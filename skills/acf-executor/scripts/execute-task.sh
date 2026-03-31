#!/bin/bash
# execute-task.sh — ACP 驱动 OpenCode 执行任务脚本
# 用法：./execute-task.sh [task_description] [cwd] [mode] [label]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"

TASK="${1:-}"
CWD="${2:-$PROJECT_PATH}"
MODE="${3:-run}"
LABEL="${4:-task}"

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
        # 更新现有文件
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

# 执行前更新状态：IDLE → EXECUTING
update_state "EXECUTING" "IDLE" "/zcf/task-review \"$TASK 完成\""

# 使用 OpenClaw sessions spawn 启动 ACP 驱动的 OpenCode
openclaw sessions spawn \
  --runtime acp \
  --agent-id opencode \
  --task "$TASK" \
  --cwd "$CWD" \
  --mode "$MODE" \
  --label "$LABEL"

echo ""
echo "✅ 任务已启动"
echo ""
echo "监控命令:"
echo "  查看状态：openclaw sessions list"
echo "  查看日志：openclaw sessions history <session-key>"
echo "  停止任务：/acp cancel <session-key>"
