#!/bin/bash
# auto-flow.sh — 任务自动流转脚本（ACP 驱动 OpenCode 版本）
# 用法：./auto-flow.sh [phase] [task_id]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   TEMP_DIR     - 临时文件目录 (默认：$PROJECT_PATH/temp)

set -e

# 支持环境变量配置（多项目支持）
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
TEMP_DIR="${TEMP_DIR:-$PROJECT_PATH/temp}"

PHASE="${1:-auto}"
TASK_ID="${2:-next}"

# 查找任务计划文件
PLAN_FILE=$(find "$TEMP_DIR" -name "phase*-tasks.md" 2>/dev/null | head -1)

if [ ! -f "$PLAN_FILE" ]; then
    echo "❌ 错误：未找到任务计划文件"
    echo "请先创建 phase*-tasks.md"
    echo "搜索路径：$TEMP_DIR"
    exit 1
fi

# 查找下一个待执行任务
if [ "$TASK_ID" = "next" ]; then
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
fi

# 提取任务详情
TASK_SECTION=$(grep -A 30 "^### $TASK_ID" "$PLAN_FILE" 2>/dev/null)

if [ -z "$TASK_SECTION" ]; then
    echo "❌ 错误：未找到任务 $TASK_ID"
    exit 1
fi

# 提取任务标题
TASK_TITLE=$(echo "$TASK_SECTION" | grep "任务名称" | cut -d':' -f2 | xargs)

# 提取交付物
DELIVERABLES=$(echo "$TASK_SECTION" | grep -A 5 "交付物" | grep -v "交付物" | grep -v "^--$" | head -5)

# 提取验收标准
ACCEPTANCE=$(echo "$TASK_SECTION" | grep -A 10 "验收标准" | grep -v "验收标准" | grep -v "^--$" | head -10)

# 生成 ACP 驱动的任务执行 JSON
# 这是给 OpenClaw 的 sessions_spawn 工具使用的
cat << EOF
## 📋 下一个任务

**任务 ID**: $TASK_ID
**任务名称**: $TASK_TITLE

### 交付物
$DELIVERABLES

### 验收标准
$ACCEPTANCE

### 执行命令（ACP 驱动 OpenCode）

\`\`\`json
{
  "tool": "sessions_spawn",
  "params": {
    "runtime": "acp",
    "agentId": "opencode",
    "task": "$TASK_ID: $TASK_TITLE",
    "cwd": "$PROJECT_PATH",
    "mode": "run",
    "label": "$TASK_ID"
  }
}
\`\`\`

### 或使用 OpenClaw 命令

\`\`\`bash
# 通过 OpenClaw sessions spawn 命令
openclaw sessions spawn \\
  --runtime acp \\
  --agent-id opencode \\
  --task "$TASK_ID: $TASK_TITLE" \\
  --cwd "$PROJECT_PATH" \\
  --mode run \\
  --label "$TASK_ID"
\`\`\`

### 架构上下文
- 项目路径：$PROJECT_PATH
- 主文档：$PROJECT_PATH/docs/architecture/YYYY-MM-DD-xxx.md
- ADR 约束：$PROJECT_PATH/docs/architecture/decisions/

---

**状态**: 准备执行 → 执行后运行 \`/zcf[:/]task-review "$TASK_ID 完成"\`

**注意**: 此脚本输出的是 sessions_spawn 的参数，需要 OpenClaw 执行
EOF
