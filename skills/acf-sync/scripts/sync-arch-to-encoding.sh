#!/bin/bash
# sync-arch-to-encoding.sh — 架构文档同步脚本
# 用法：./sync-arch-to-encoding.sh [proposal_root] [encoding_root] [--dry-run]

set -e

PROPOSAL_ROOT="${1:-/workspace/mynotes/SkillApps/ecommerce/docs/architecture}"
ENCODING_ROOT="${2:-/workspace/ecommerce/docs/architecture}"
DRY_RUN="false"

# 解析参数
if [ "$3" = "--dry-run" ] || [ "$3" = "--list" ]; then
    DRY_RUN="true"
fi

echo "=== 架构文档同步 ==="
echo "源目录：$PROPOSAL_ROOT"
echo "目标目录：$ENCODING_ROOT"
echo "模式：$([ "$DRY_RUN" = "true" ] && echo 'DRY-RUN' || echo 'EXECUTE')"
echo ""

# 检查源目录
if [ ! -d "$PROPOSAL_ROOT" ]; then
    echo "❌ 错误：提案仓库目录不存在：$PROPOSAL_ROOT"
    exit 1
fi

# 生成同步列表（优先同步"已发布"或"已采纳"状态的文档）
SYNC_LIST_FILE="/tmp/acf-sync-list-$$.txt"

echo "正在生成同步列表..." >&2

# 查找状态为"已发布"、"已采纳"或"可同步"的文档
find "$PROPOSAL_ROOT" -name "*.md" -type f 2>/dev/null | while read file; do
    if grep -qE "状态.*:.*(已发布 | 已采纳 | 可同步)" "$file" 2>/dev/null; then
        echo "$file"
    fi
done > "$SYNC_LIST_FILE"

# 如果没有找到带状态标记的文档，同步所有 .md 文件
if [ ! -s "$SYNC_LIST_FILE" ]; then
    echo "⚠️  未找到带状态标记的文档，同步所有 .md 文件..." >&2
    find "$PROPOSAL_ROOT" -name "*.md" -type f 2>/dev/null > "$SYNC_LIST_FILE"
fi

SYNC_COUNT=$(wc -l < "$SYNC_LIST_FILE" 2>/dev/null || echo 0)
echo "✅ 找到 $SYNC_COUNT 个待同步文件"
echo ""

# 逐文件同步
SYNCED_COUNT=0
while IFS= read -r file; do
    if [ ! -f "$file" ]; then
        echo "⚠️  跳过（文件不存在）：$file"
        continue
    fi
    
    rel_path="${file#$PROPOSAL_ROOT/}"
    target_file="$ENCODING_ROOT/$rel_path"
    target_dir="$(dirname "$target_file")"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] 同步：$rel_path"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
        continue
    fi
    
    mkdir -p "$target_dir"
    cp "$file" "$target_file"
    
    echo "✅ 同步：$rel_path"
    SYNCED_COUNT=$((SYNCED_COUNT + 1))
done < "$SYNC_LIST_FILE"

# 生成同步报告
if [ "$DRY_RUN" = "false" ]; then
    cat > "$ENCODING_ROOT/SYNC-REPORT.md" << EOF
# 架构文档同步报告

**同步时间**: $(date +'%Y-%m-%d %H:%M:%S')
**同步文件数**: $SYNCED_COUNT
**源目录**: $PROPOSAL_ROOT
**目标目录**: $ENCODING_ROOT

## 同步文件列表

$(cat "$SYNC_LIST_FILE" 2>/dev/null | sed "s|$PROPOSAL_ROOT/||")

## 下一步

1. **验证同步**: \`ls -la $ENCODING_ROOT/\`
2. **提交变更**: \`cd $ENCODING_ROOT/.. && git add . && git commit -m "sync: 架构文档更新"\`
3. **通知编码助手**: @OpenCode 架构文档已更新

---
**执行人**: DevMate
**触发方式**: skill_use acf-sync
EOF

    echo ""
    echo "✅ 同步完成！"
    echo "📊 同步文件数：$SYNCED_COUNT"
    echo "📄 同步报告：$ENCODING_ROOT/SYNC-REPORT.md"
else
    echo ""
    echo "✅ DRY-RUN 完成！"
    echo "📊 预计同步文件数：$SYNCED_COUNT"
fi

# 清理临时文件
rm -f "$SYNC_LIST_FILE"
