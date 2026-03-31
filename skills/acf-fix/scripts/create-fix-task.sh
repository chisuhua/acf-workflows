#!/bin/bash
# create-fix-task.sh — 修复任务创建脚本
# 用法：./create-fix-task.sh [action] [options]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   TEMP_DIR     - 临时文件目录 (默认：$PROJECT_PATH/temp)

set -e

# 支持环境变量配置（多项目支持）
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
TEMP_DIR="${TEMP_DIR:-$PROJECT_PATH/temp}"

# 默认参数
ACTION="${1:-create}"
PRIORITY="${2:-auto}"
SUMMARY="${3:-未指定}"
SOURCE_REVIEW="${4:-}"

# 创建临时目录（如不存在）
mkdir -p "$TEMP_DIR"

# ==================== 辅助函数 ====================

generate_fix_id() {
    local fix_count=0
    if [ -f "$TEMP_DIR/fix-tasks.md" ]; then
        fix_count=$(grep -c "### Fix-" "$TEMP_DIR/fix-tasks.md" 2>/dev/null || echo 0)
    fi
    printf "Fix-%03d" $((fix_count + 1))
}

auto_detect_priority() {
    local source="$1"
    
    if [ -z "$source" ] || [ ! -f "$source" ]; then
        echo "P2"
        return
    fi
    
    # 从评审报告自动识别优先级
    if grep -q "❌ 严重\|P0\|阻塞" "$source" 2>/dev/null; then
        echo "P0"
    elif grep -q "⚠️ 中等\|P1" "$source" 2>/dev/null; then
        echo "P1"
    else
        echo "P2"
    fi
}

identify_blocked_tasks() {
    # 简单实现：返回下一个任务
    local plan_file=$(find "$TEMP_DIR" -name "phase*-tasks.md" 2>/dev/null | head -1)
    
    if [ -f "$plan_file" ]; then
        local next_task=$(grep -E "^\| Task [0-9]+" "$plan_file" | grep "pending" | head -1 | awk -F'|' '{print $2}' | xargs)
        if [ -n "$next_task" ]; then
            echo "$next_task"
            return
        fi
    fi
    
    echo "无"
}

insert_to_plan_top() {
    local fix_id="$1"
    local summary="$2"
    local priority="$3"
    
    local plan_file=$(find "$TEMP_DIR" -name "phase*-tasks.md" 2>/dev/null | head -1)
    
    if [ -f "$plan_file" ]; then
        # 创建临时文件
        local temp_plan=$(mktemp)
        
        # 在顶部插入修复任务
        cat > "$temp_plan" << EOF
### $fix_id

- **优先级**: $priority ($summary)
- **状态**: 待开始
- **创建时间**: $(date +'%Y-%m-%d %H:%M')
- **阻塞任务**: $(identify_blocked_tasks)
- **验收标准**: 
  - [ ] 问题修复完成
  - [ ] 相关测试通过

---

EOF
        
        # 追加原内容
        cat "$plan_file" >> "$temp_plan"
        
        # 替换原文件
        mv "$temp_plan" "$plan_file"
        
        echo "📝 已插入到任务计划顶部：$plan_file"
    else
        echo "⚠️ 未找到任务计划文件，跳过插入"
    fi
}

# ==================== 动作函数 ====================

action_create() {
    # 自动识别优先级
    if [ "$PRIORITY" = "auto" ]; then
        PRIORITY=$(auto_detect_priority "$SOURCE_REVIEW")
        echo "🔍 自动识别优先级：$PRIORITY"
    fi
    
    # 生成 Fix-XXX 编号
    FIX_ID=$(generate_fix_id)
    
    # 创建时间戳
    CREATE_TIME=$(date +'%Y-%m-%d %H:%M')
    
    # 识别阻塞任务
    BLOCKED_TASKS=$(identify_blocked_tasks)
    
    # 创建修复任务记录
    cat >> "$TEMP_DIR/fix-tasks.md" << EOF
### $FIX_ID

- **优先级**: $PRIORITY
- **问题摘要**: $SUMMARY
- **来源评审**: ${SOURCE_REVIEW:-未指定}
- **状态**: 待开始
- **创建时间**: $CREATE_TIME
- **阻塞任务**: $BLOCKED_TASKS
- **验收标准**: 
  - [ ] 问题修复完成
  - [ ] 相关测试通过

---

EOF
    
    # 插入到任务计划顶部
    insert_to_plan_top "$FIX_ID" "$SUMMARY" "$PRIORITY"
    
    # 输出结果
    cat << EOF
## ✅ 修复任务已创建

**任务 ID**: $FIX_ID
**优先级**: $PRIORITY
**问题摘要**: $SUMMARY
**来源评审**: ${SOURCE_REVIEW:-未指定}
**创建时间**: $CREATE_TIME

### 阻塞任务
$BLOCKED_TASKS

### 验收标准
- [ ] 问题修复完成
- [ ] 相关测试通过

### 执行命令
\`\`\`bash
task(
    category="deep",
    prompt="$FIX_ID: $SUMMARY",
    load_skills=["subagent-driven-development"]
)
\`\`\`

---

**状态**: 准备执行 → 执行后运行 \`/zcf[:/]task-review "$FIX_ID 完成"\`
EOF
}

action_list() {
    local fix_file="$TEMP_DIR/fix-tasks.md"
    
    if [ ! -f "$fix_file" ]; then
        echo "## 📋 修复任务列表"
        echo ""
        echo "暂无修复任务"
        return
    fi
    
    echo "## 📋 修复任务列表"
    echo ""
    echo "| 任务 ID | 优先级 | 问题摘要 | 状态 | 来源评审 |"
    echo "|--------|--------|---------|------|---------|"
    
    # 解析 fix-tasks.md
    local current_id=""
    local current_priority=""
    local current_summary=""
    local current_status=""
    local current_source=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^###\ (Fix-[0-9]+) ]]; then
            # 输出上一行（如果有）
            if [ -n "$current_id" ]; then
                echo "| $current_id | $current_priority | $current_summary | $current_status | $current_source |"
            fi
            current_id="${BASH_REMATCH[1]}"
            current_priority=""
            current_summary=""
            current_status=""
            current_source=""
        elif [[ "$line" =~ ^-\ \*\*优先级\*\*:\ (P[0-2]) ]]; then
            current_priority="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-\ \*\*问题摘要\*\*:\ (.+) ]]; then
            current_summary="${BASH_REMATCH[1]}"
            # 截断过长的摘要
            if [ ${#current_summary} -gt 30 ]; then
                current_summary="${current_summary:0:27}..."
            fi
        elif [[ "$line" =~ ^-\ \*\*状态\*\*:\ (.+) ]]; then
            current_status="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-\ \*\*来源评审\*\*:\ (.+) ]]; then
            current_source="${BASH_REMATCH[1]}"
            # 简化路径
            current_source=$(basename "$current_source")
        fi
    done < "$fix_file"
    
    # 输出最后一行
    if [ -n "$current_id" ]; then
        echo "| $current_id | $current_priority | $current_summary | $current_status | $current_source |"
    fi
    
    echo ""
    
    # 统计
    local p0_count=$(grep -c "\*\*优先级\*\*: P0" "$fix_file" 2>/dev/null || echo 0)
    local p1_count=$(grep -c "\*\*优先级\*\*: P1" "$fix_file" 2>/dev/null || echo 0)
    local p2_count=$(grep -c "\*\*优先级\*\*: P2" "$fix_file" 2>/dev/null || echo 0)
    
    echo "**P0 任务**: $p0_count 个（阻塞后续任务）"
    echo "**P1 任务**: $p1_count 个"
    echo "**P2 任务**: $p2_count 个"
}

action_status() {
    local task_id="${1:-}"
    local fix_file="$TEMP_DIR/fix-tasks.md"
    
    if [ -z "$task_id" ]; then
        echo "❌ 错误：请指定任务 ID"
        echo "用法：$0 status <task_id>"
        exit 1
    fi
    
    if [ ! -f "$fix_file" ]; then
        echo "❌ 错误：修复任务文件不存在"
        exit 1
    fi
    
    echo "## 📊 修复任务状态：$task_id"
    echo ""
    
    # 提取任务信息
    local task_section=$(grep -A 15 "^### $task_id" "$fix_file" 2>/dev/null)
    
    if [ -z "$task_section" ]; then
        echo "❌ 未找到任务：$task_id"
        exit 1
    fi
    
    echo "\`\`\`"
    echo "$task_section"
    echo "\`\`\`"
}

# ==================== 帮助信息 ====================

show_help() {
    cat << EOF
用法：$0 [action] [options]

动作:
  create    创建修复任务（默认）
  list      列出所有修复任务
  status    查看指定任务状态

选项:
  create 动作:
    $0 create [priority] [summary] [source_review]
    
    priority:   P0|P1|P2|auto (默认：auto)
    summary:    问题摘要
    source_review: 来源评审报告路径
  
  status 动作:
    $0 status <task_id>

环境变量:
  PROJECT_PATH  项目根目录 (默认：/workspace/ecommerce)
  TEMP_DIR      临时文件目录 (默认：\$PROJECT_PATH/temp)

示例:
  # 创建修复任务（自动识别优先级）
  $0 create auto "Mock Fixture 路径错误" "docs/reviews/task-001-review.md"
  
  # 创建修复任务（指定 P0 优先级）
  $0 create P0 "严重架构违规" "docs/reviews/task-002-review.md"
  
  # 列出所有修复任务
  $0 list
  
  # 查看指定任务状态
  $0 status Fix-001
EOF
}

# ==================== 主程序 ====================

case "$ACTION" in
    create)
        action_create
        ;;
    list)
        action_list
        ;;
    status)
        action_status "$SUMMARY"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "❌ 未知动作：$ACTION"
        show_help
        exit 1
        ;;
esac
