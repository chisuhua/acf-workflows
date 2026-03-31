#!/bin/bash
# execute-task.sh — ACP 驱动 OpenCode 执行任务脚本（集成 claims 防重复机制）
# 用法：./execute-task.sh [task_description] [cwd] [mode] [label]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   CLAIMS_FILE  - claims 文件路径 (默认：$PROJECT_PATH/.acf/temp/claims.json)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
CLAIMS_FILE="${CLAIMS_FILE:-$PROJECT_PATH/.acf/temp/claims.json}"

TASK="${1:-}"
CWD="${2:-$PROJECT_PATH}"
MODE="${3:-run}"
LABEL="${4:-task}"

# 提取 Task ID
TASK_ID=$(echo "$TASK" | grep -oE 'Task [0-9]+' | head -1)

# 加载 claims 库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../scripts/lib/claims.sh"

# 配置参数
CLAIMS_TIMEOUT=$(openclaw config show acf.executor.claimTimeoutMinutes 2>/dev/null || echo 120)

# 检查参数
if [ -z "$TASK" ]; then
    echo "❌ 错误：缺少任务描述"
    echo ""
    echo "用法：$0 <task_description> [cwd] [mode] [label]"
    echo ""
    echo "示例:"
    echo "  $0 \"Task 001: 创建 Crawler 基类\" /workspace/ecommerce run Task-001"
    exit 1
fi

# 检查 OpenCode 是否安装
if ! command -v opencode &> /dev/null; then
    echo "⚠️  警告：opencode 未安装"
    echo "安装命令：npm install -g opencode"
    echo ""
    echo "继续执行（通过 ACP 自动调用）..."
fi

# 检查 ACP 配置
echo "🔍 检查 ACP 配置..."
if ! openclaw config show acp.enabled &> /dev/null; then
    echo "❌ 错误：ACP 未启用"
    echo "启用命令：openclaw config set acp.enabled true"
    exit 1
fi

echo "✅ ACP 已启用"
echo ""

# Claims 检查（防重复 Spawn）
echo "🔒 检查任务 claim..."
claims_init
cleanup_claims "$CLAIMS_TIMEOUT" > /dev/null

CLAIM_RESULT=$(check_claim "$TASK_ID" 2>/dev/null || echo "not_exists")
if [[ "$CLAIM_RESULT" == exists:* ]]; then
    AGENT_ID=$(echo "$CLAIM_RESULT" | cut -d':' -f2)
    STARTED_AT=$(echo "$CLAIM_RESULT" | cut -d':' -f3)
    echo "⚠️  任务 $TASK_ID 已在处理中"
    echo "   Agent: $AGENT_ID"
    echo "   开始时间：$STARTED_AT"
    echo ""
    echo "💡 如需强制重新执行，先释放 claim:"
    echo "   source scripts/lib/claims.sh && release_claim \"$TASK_ID\""
    exit 0
fi

echo "✅ 任务 $TASK_ID 可以执行"
echo ""

# 执行任务
echo "🚀 启动任务：$TASK"
echo "工作目录：$CWD"
echo "执行模式：$MODE"
echo "任务标签：$LABEL"
echo ""

# 状态机更新（P0 新增）
update_state() {
    local state="$1"
    local prev_state="$2"
    local next_action="$3"
    local block_reason="${4:-}"
    local status_file="$CWD/.acf/status/current-task.md"
    
    if [ -f "$status_file" ]; then
        sed -i "s/\*\*当前状态\*\*: .*/\*\*当前状态\*\*: \`$state\`/" "$status_file"
        sed -i "s/\*\*最后状态转换\*\*: .*/\*\*最后状态转换\*\*: \`$prev_state\` → \`$state\` ($(date +'%Y-%m-%d %H:%M:%S'))/" "$status_file"
        sed -i "s/\*\*下一步动作\*\*: .*/\*\*下一步动作\*\*: \`$next_action\`/" "$status_file"
        if [ -n "$block_reason" ]; then
            sed -i "s/\*\*阻塞原因\*\*: .*/\*\*阻塞原因\*\*: \`$block_reason\`/" "$status_file"
        fi
        echo "✅ 状态机已更新：$prev_state → $state"
    else
        echo "⚠️  警告：状态文件不存在 $status_file"
    fi
}

# 构建任务 Prompt（含编码助手角色定义）
build_task_prompt() {
    local task="$1"
    local cwd="$2"
    local prompt_file="$cwd/temp/current-task-prompt.md"
    local template_file="/workspace/acf-workflow/templates/task-prompt.md"
    
    # 创建临时目录
    mkdir -p "$cwd/temp"
    
    # 加载模板并填充变量
    if [ -f "$template_file" ]; then
        cat "$template_file" | \
            sed "s/{{Task ID}}/$(echo "$task" | grep -oE 'Task [0-9]+' | head -1)/g" | \
            sed "s/{{任务名称}}/$task/g" | \
            sed "s/{{PROJECT_PATH}}/$cwd/g" | \
            sed "s/{{主文档名}}/YYY-MM-DD-architecture/g" | \
            sed "s/{{task-id}}/$(echo "$task" | grep -oE 'Task [0-9]+' | head -1 | tr '[:upper:]' '[:lower:]' | tr ' ' '-')/g" | \
            sed "s/{{short-desc}}/task/g" > "$prompt_file"
        
        echo "✅ 任务 Prompt 已生成：$prompt_file"
        cat "$prompt_file"
    else
        echo "⚠️  警告：模板文件不存在，使用原始任务描述"
        echo "$task"
    fi
}

# 执行前更新状态：IDLE → EXECUTING
update_state "EXECUTING" "IDLE" "/zcf/task-review \"$TASK 完成\""

# 构建任务 Prompt（含编码助手角色定义）
TASK_PROMPT=$(build_task_prompt "$TASK" "$CWD")

# 使用 OpenClaw sessions spawn 启动 ACP 驱动的 OpenCode（编码助手角色）
echo "🚀 启动 ACP session..."
SESSION_OUTPUT=$(openclaw sessions spawn \
  --runtime acp \
  --agent-id opencode \
  --task "$TASK_PROMPT" \
  --cwd "$CWD" \
  --mode "$MODE" \
  --label "$LABEL" 2>&1)

echo "$SESSION_OUTPUT"

# 提取 agent_id
AGENT_ID=$(echo "$SESSION_OUTPUT" | grep -oE 'agent:opencode:acp:[a-f0-9-]+' | head -1)

if [ -n "$AGENT_ID" ]; then
    # 写入 claim
    write_claim "$TASK_ID" "$AGENT_ID" "$CLAIMS_TIMEOUT"
    
    # 更新状态机
    update_state "EXECUTING" "IDLE" "/zcf/task-review \"$TASK 完成\"" "$AGENT_ID"
else
    echo "⚠️  警告：无法提取 agent_id，claim 未写入"
fi

echo ""
echo "✅ 任务已启动"
echo ""
echo "Session Key: $AGENT_ID"
echo ""
echo "监控命令:"
echo "  查看状态：openclaw sessions list"
echo "  查看日志：openclaw sessions history $AGENT_ID"
echo "  停止任务：/acp cancel $AGENT_ID"
