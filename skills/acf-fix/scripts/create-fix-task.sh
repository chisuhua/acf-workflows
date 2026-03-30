#!/bin/bash
# create-fix-task.sh — 修复任务创建脚本
# 用法：./create-fix-task.sh [priority] [summary] [source_review]

PRIORITY="${1:-auto}"
SUMMARY="${2:-未指定}"
SOURCE_REVIEW="${3:-}"

FIX_TASKS_FILE="/workspace/ecommerce/temp/fix-tasks.md"
PLAN_FILE="/workspace/ecommerce/temp/phase*-tasks.md"

# 生成 Fix-XXX 编号
if [ -f "$FIX_TASKS_FILE" ]; then
    FIX_COUNT=$(grep -c "^### Fix-" "$FIX_TASKS_FILE" 2>/dev/null || echo 0)
else
    FIX_COUNT=0
fi
FIX_NUM=$((FIX_COUNT + 1))
FIX_ID=$(printf "Fix-%03d" $FIX_NUM)

# 自动识别优先级
if [ "$PRIORITY" = "auto" ] && [ -n "$SOURCE_REVIEW" ] && [ -f "$SOURCE_REVIEW" ]; then
    if grep -qE "❌ 严重|P0|阻塞" "$SOURCE_REVIEW" 2>/dev/null; then
        PRIORITY="P0"
    elif grep -qE "⚠️ 中等|P1" "$SOURCE_REVIEW" 2>/dev/null; then
        PRIORITY="P1"
    else
        PRIORITY="P2"
    fi
fi

# 创建/初始化 fix-tasks.md
if [ ! -f "$FIX_TASKS_FILE" ]; then
    cat > "$FIX_TASKS_FILE" << 'EOF'
# 修复任务追踪

**创建时间**: $(date +'%Y-%m-%d')

## 修复任务列表

EOF
fi

# 追加修复任务记录
cat >> "$FIX_TASKS_FILE" << EOF
### $FIX_ID

- **优先级**: $PRIORITY
- **问题摘要**: $SUMMARY
- **来源评审**: $SOURCE_REVIEW
- **状态**: 待开始
- **创建时间**: $(date +'%Y-%m-%d %H:%M')
- **阻塞任务**: 后续任务（P0 阻塞，P1/P2 不阻塞）

---

EOF

# 插入到任务计划顶部（查找第一个任务，插入到其前面）
FIRST_TASK_LINE=$(grep -n "^### Task" $(find /workspace/ecommerce/temp -name "phase*-tasks.md" | head -1) 2>/dev/null | head -1 | cut -d':' -f1)

if [ -n "$FIRST_TASK_LINE" ]; then
    PLAN_FILE=$(find /workspace/ecommerce/temp -name "phase*-tasks.md" | head -1)
    
    # 创建临时文件
    TEMP_FILE=$(mktemp)
    
    # 插入修复任务到第一个任务前面
    head -n $((FIRST_TASK_LINE - 1)) "$PLAN_FILE" > "$TEMP_FILE"
    cat >> "$TEMP_FILE" << EOF
### $FIX_ID: $SUMMARY

**优先级**: $PRIORITY
**类型**: 修复任务
**阻塞**: $([ "$PRIORITY" = "P0" ] && echo "是（阻塞后续任务）" || echo "否")

$(grep -A 10 "交付物\|验收" "$SOURCE_REVIEW" 2>/dev/null | head -15)

---

EOF
    tail -n +$FIRST_TASK_LINE "$PLAN_FILE" >> "$TEMP_FILE"
    mv "$TEMP_FILE" "$PLAN_FILE"
fi

# 输出结果
cat << EOF
## ✅ 修复任务已创建

**任务 ID**: $FIX_ID
**优先级**: $PRIORITY
**问题摘要**: $SUMMARY
**来源评审**: $SOURCE_REVIEW

### 执行命令

task(category="deep", prompt="$FIX_ID: $SUMMARY")

---

**完成后**: /zcf:task-review "$FIX_ID 完成"
EOF
