#!/bin/bash
# auto-flow.sh — 任务自动流转脚本（支持并行执行 + claims 防重复）
# 用法：./auto-flow.sh [--parallel] [--max-concurrent N]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   CLAIMS_FILE  - claims 文件路径 (默认：$PROJECT_PATH/.acf/temp/claims.json)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
CLAIMS_FILE="${CLAIMS_FILE:-$PROJECT_PATH/.acf/temp/claims.json}"
TEMP_DIR="${TEMP_DIR:-$PROJECT_PATH/temp}"

# 参数解析
PARALLEL=false
MAX_CONCURRENT=$(openclaw config show acf.executor.maxConcurrent 2>/dev/null || echo 4)
CRITICAL_MARKER=$(openclaw config show acf.executor.criticalTaskMarker 2>/dev/null || echo "是")

while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel) PARALLEL=true; shift ;;
        --max-concurrent) MAX_CONCURRENT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# 加载 claims 库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../scripts/lib/claims.sh"

# 配置参数
CLAIMS_TIMEOUT=$(openclaw config show acf.executor.claimTimeoutMinutes 2>/dev/null || echo 120)

# 查找任务计划文件
PLAN_FILE=$(find "$TEMP_DIR" -name "phase*-tasks.md" 2>/dev/null | head -1)

if [ ! -f "$PLAN_FILE" ]; then
    echo "❌ 错误：未找到任务计划文件"
    echo "请先创建 phase*-tasks.md"
    echo "搜索路径：$TEMP_DIR"
    exit 1
fi

# 初始化 claims
claims_init
cleanup_claims "$CLAIMS_TIMEOUT" > /dev/null

# 判断是否是关键任务
is_critical_task() {
    local task_id="$1"
    # 列索引：| Task ID(2) | 任务名称 (3) | 依赖 (4) | 并行组 (5) | 关键 (6) | 状态 (7) |
    local critical=$(grep "^| $task_id" "$PLAN_FILE" | awk -F'|' '{print $6}' | xargs)
    if [[ "$critical" == "$CRITICAL_MARKER" ]] || [[ "$critical" == "true" ]] || [[ "$critical" == "yes" ]]; then
        return 0  # 是关键任务
    fi
    return 1  # 不是关键任务
}

# 识别下一个关键任务
identify_next_critical_task() {
    grep -E "^\| Task [0-9]+" "$PLAN_FILE" | \
    while IFS='|' read -r _ task_id task_name depends parallel_group critical status estimated; do
        task_id=$(echo "$task_id" | xargs)
        critical=$(echo "$critical" | xargs)
        status=$(echo "$status" | xargs)
        
        # 跳过非 pending 状态
        if [ "$status" != "pending" ]; then
            continue
        fi
        
        # 只返回关键任务
        if [[ "$critical" == "$CRITICAL_MARKER" ]] || [[ "$critical" == "true" ]] || [[ "$critical" == "yes" ]]; then
            echo "$task_id"
            return 0
        fi
    done
}

# 识别可并行任务（排除关键任务和有依赖的任务）
identify_parallel_tasks() {
    grep -E "^\| Task [0-9]+" "$PLAN_FILE" | \
    while IFS='|' read -r _ task_id task_name depends parallel_group critical status estimated; do
        task_id=$(echo "$task_id" | xargs)
        critical=$(echo "$critical" | xargs)
        depends=$(echo "$depends" | xargs)
        status=$(echo "$status" | xargs)
        
        # 跳过非 pending 状态
        if [ "$status" != "pending" ]; then
            continue
        fi
        
        # 跳过关键任务（关键任务串行执行）
        if [[ "$critical" == "$CRITICAL_MARKER" ]] || [[ "$critical" == "true" ]] || [[ "$critical" == "yes" ]]; then
            echo "⚠️  $task_id 是关键任务，跳过并行"
            continue
        fi
        
        # 跳过有依赖的任务
        if [ "$depends" != "无" ] && [ "$depends" != "-" ]; then
            continue
        fi
        
        # 检查 claim（已在处理的任务跳过）
        if check_claim "$task_id" > /dev/null 2>&1; then
            echo "⚠️  $task_id 已在处理中，跳过"
            continue
        fi
        
        echo "$task_id"
    done
}

# 释放 claim（供外部调用）
release_claim_wrapper() {
    local task_id="$1"
    release_claim "$task_id"
}

# 主流程
if [ "$PARALLEL" = "true" ]; then
    echo "========================================"
    echo "  并行执行模式"
    echo "========================================"
    echo ""
    
    # 先检查是否有未完成的关键任务
    CRITICAL_TASK=$(identify_next_critical_task)
    if [ -n "$CRITICAL_TASK" ]; then
        echo "⚠️  有关键任务待执行：$CRITICAL_TASK"
        echo "💡 建议：先执行关键任务（串行），再执行非关键任务（并行）"
        echo ""
        
        # 提取任务名称
        task_name=$(grep "^| $CRITICAL_TASK" "$PLAN_FILE" | cut -d'|' -f3 | xargs)
        
        # 执行关键任务（串行）
        echo "🚀 执行关键任务：$CRITICAL_TASK: $task_name"
        skill_use acf-executor task="$CRITICAL_TASK: $task_name" cwd="$PROJECT_PATH"
        
        echo ""
        echo "⏳ 等待关键任务完成..."
        echo "💡 完成后运行：/zcf/task-review \"$CRITICAL_TASK 完成\""
        echo ""
        echo "📋 评审后决策点："
        echo "   - 无问题 → 继续并行执行非关键任务"
        echo "   - 架构偏差 → 返回架构循环"
        echo ""
        exit 0
    fi
    
    # 无关键任务，执行非关键任务（并行）
    echo "🔍 识别可并行任务..."
    TASKS=$(identify_parallel_tasks | grep "^Task" | head -n "$MAX_CONCURRENT")
    TASK_COUNT=$(echo "$TASKS" | grep -c "Task" 2>/dev/null || echo 0)
    
    if [ "$TASK_COUNT" -eq 0 ]; then
        echo "✅ 无可用并行任务"
        echo ""
        echo "可能原因:"
        echo "  1. 所有任务已完成"
        echo "  2. 有待执行的关键任务（先执行关键任务）"
        echo "  3. 任务已在处理中"
        echo ""
        echo "💡 建议：运行 skill_use acf-status 查看项目状态"
        exit 0
    fi
    
    echo "📋 可并行任务：$TASK_COUNT 个（非关键）"
    echo "$TASKS"
    echo ""
    
    # 并行启动
    echo "🚀 并行启动任务..."
    PIDS=()
    AGENT_IDS=()
    
    for task_id in $TASKS; do
        task_name=$(grep "^| $task_id" "$PLAN_FILE" | cut -d'|' -f3 | xargs)
        
        # 启动任务（后台）
        skill_use acf-executor task="$task_id: $task_name" cwd="$PROJECT_PATH" &
        PID=$!
        PIDS+=($PID)
        
        # 等待 1 秒后读取 agent_id
        sleep 1
        agent_id=$(jq -r --arg id "$task_id" '.[$id].agent_id // "unknown"' "$CLAIMS_FILE" 2>/dev/null || echo "unknown")
        AGENT_IDS+=($agent_id)
        
        echo "✅ $task_id 已启动 (PID: $PID, Agent: $agent_id)"
    done
    
    # 等待所有完成
    echo ""
    echo "⏳ 等待所有任务完成..."
    FAILED=0
    for i in "${!PIDS[@]}"; do
        pid=${PIDS[$i]}
        task_id=$(echo "$TASKS" | sed -n "$((i+1))p")
        
        if wait $pid; then
            echo "✅ $task_id 完成"
        else
            echo "❌ $task_id 失败"
            FAILED=$((FAILED + 1))
        fi
    done
    
    echo ""
    echo "========================================"
    if [ "$FAILED" -eq 0 ]; then
        echo "✅ 并行执行完成：$TASK_COUNT 任务全部成功"
        echo "💡 下一步：skill_use acf-flow --parallel"
    else
        echo "⚠️  并行执行完成：$((TASK_COUNT - FAILED))/$TASK_COUNT 成功，$FAILED 失败"
        echo "💡 下一步：检查失败任务 → skill_use acf-fix"
    fi
    echo "========================================"
    
else
    # 串行执行模式
    echo "========================================"
    echo "  串行执行模式"
    echo "========================================"
    echo ""
    
    # 查找下一个待执行任务
    TASK_LINE=$(grep -E "^\| Task [0-9]+" "$PLAN_FILE" | grep -E "pending|in_progress" | head -1)
    
    if [ -z "$TASK_LINE" ]; then
        echo "✅ 当前阶段任务全部完成"
        echo ""
        echo "下一步建议:"
        echo "  1. 执行阶段评审：/zcf[:/]task-review \"阶段 X 完成\""
        echo "  2. 规划下一阶段：skill_use acf-architect"
        exit 0
    fi
    
    TASK_ID=$(echo "$TASK_LINE" | awk -F'|' '{print $2}' | xargs)
    
    # 检查是否是关键任务
    if is_critical_task "$TASK_ID"; then
        echo "📋 下一个任务：$TASK_ID (关键任务)"
    else
        echo "📋 下一个任务：$TASK_ID (非关键任务)"
    fi
    
    # 检查 claim
    if check_claim "$TASK_ID" > /dev/null 2>&1; then
        agent_id=$(jq -r --arg id "$TASK_ID" '.[$id].agent_id // "unknown"' "$CLAIMS_FILE" 2>/dev/null || echo "unknown")
        echo "⚠️  任务 $TASK_ID 已在处理中"
        echo "   Agent: $agent_id"
        echo ""
        echo "💡 等待任务完成或释放 claim 后重试"
        exit 0
    fi
    
    # 提取任务详情
    TASK_SECTION=$(grep -A 30 "^### $TASK_ID" "$PLAN_FILE" 2>/dev/null)
    
    if [ -z "$TASK_SECTION" ]; then
        echo "❌ 错误：未找到任务 $TASK_ID"
        exit 1
    fi
    
    # 提取任务标题
    TASK_TITLE=$(echo "$TASK_SECTION" | grep "任务名称" | cut -d':' -f2 | xargs)
    
    # 执行任务（串行）
    echo "🚀 执行任务：$TASK_ID: $TASK_TITLE"
    skill_use acf-executor task="$TASK_ID: $TASK_TITLE" cwd="$PROJECT_PATH"
    
    echo ""
    echo "⏳ 等待任务完成..."
    echo "💡 完成后运行：/zcf/task-review \"$TASK_ID 完成\""
fi
