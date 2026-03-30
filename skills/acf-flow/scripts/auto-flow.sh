#!/bin/bash
# auto-flow.sh — 任务自动流转脚本
# 用法：./auto-flow.sh [phase] [task_id]

PHASE="${1:-auto}"
TASK_ID="${2:-next}"

# 查找任务计划文件
PLAN_FILE=$(find /workspace/ecommerce/temp -name "phase*-tasks.md" 2>/dev/null | head -1)

if [ ! -f "$PLAN_FILE" ]; then
    echo "❌ 错误：未找到任务计划文件"
    echo "请先创建 phase*-tasks.md"
    exit 1
fi

# 查找下一个待执行任务
if [ "$TASK_ID" = "next" ]; then
    TASK_LINE=$(grep -E "^\| Task [0-9]+" "$PLAN_FILE" | grep -E "pending|in_progress" | head -1)
    
    if [ -z "$TASK_LINE" ]; then
        echo "✅ 当前阶段任务全部完成"
        echo ""
        echo "下一步建议:"
        echo "  1. 执行阶段评审：/zcf:task-review \"阶段 X 完成\""
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

TASK_TITLE=$(echo "$TASK_SECTION" | grep "任务名称\|描述" | head -1 | cut -d':' -f2 | xargs)
PRIORITY=$(echo "$TASK_SECTION" | grep "优先级" | head -1 | cut -d':' -f2 | xargs)
EST_TIME=$(echo "$TASK_SECTION" | grep "预计耗时" | head -1 | cut -d':' -f2 | xargs)

cat << EOF
## 📋 任务详情

**任务 ID**: $TASK_ID
**任务名称**: $TASK_TITLE
**优先级**: $PRIORITY
**预计耗时**: $EST_TIME

---

### 交付物
$(echo "$TASK_SECTION" | grep -A 5 "交付物" | tail -n +2 | head -5 | sed 's/^- /✅ /')

---

### 执行命令

task(category="deep", prompt="$TASK_ID: $TASK_TITLE")

---

**完成后**: /zcf:task-review "$TASK_ID 完成"
EOF
