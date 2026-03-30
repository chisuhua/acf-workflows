#!/bin/bash
# generate-status.sh — ZCF 项目状态生成脚本
# 用法：./generate-status.sh [project_path] [mode]
# 示例：./generate-status.sh /workspace/ecommerce full

set -e

PROJECT_PATH="${1:-/workspace/ecommerce}"
MODE="${2:-full}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==================== 状态检查函数 ====================

check_sync_status() {
    local sync_report="$PROJECT_PATH/docs/architecture/SYNC-REPORT.md"
    
    if [ -f "$sync_report" ]; then
        local sync_time=$(grep -i "同步时间" "$sync_report" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
        if [ -n "$sync_time" ]; then
            echo "🟢 最新 ($sync_time)"
        else
            echo "🟢 最新"
        fi
    else
        echo "❌ 缺失"
    fi
}

check_doc_status() {
    local doc_count=$(find "$PROJECT_PATH/docs/architecture" -name "*.md" 2>/dev/null | wc -l)
    
    if [ $doc_count -ge 10 ]; then
        echo "🟢 完整 ($doc_count 个文档)"
    elif [ $doc_count -ge 5 ]; then
        echo "🟡 部分 ($doc_count 个文档)"
    else
        echo "🔴 缺失 ($doc_count 个文档)"
    fi
}

check_coding_status() {
    local src_count=$(find "$PROJECT_PATH/src" -name "*.py" 2>/dev/null | wc -l)
    local test_count=$(find "$PROJECT_PATH/tests" -name "*.py" 2>/dev/null | wc -l)
    
    if [ $src_count -eq 0 ] && [ $test_count -eq 0 ]; then
        echo "⏸️ 未开始"
    elif [ $src_count -gt 0 ] && [ $test_count -gt 0 ]; then
        echo "🟡 进行中 ($src_count 源代码，$test_count 测试)"
    elif [ $src_count -gt 0 ]; then
        echo "🟡 编码中 ($src_count 源代码)"
    else
        echo "🟡 测试中 ($test_count 测试)"
    fi
}

check_issue_status() {
    local issues_file="$PROJECT_PATH/temp/arch-issues.md"
    
    if [ -f "$issues_file" ]; then
        local severe_count=$(grep -c "❌ 严重" "$issues_file" 2>/dev/null || echo 0)
        local pending_count=$(grep -c "⏳ 待评审" "$issues_file" 2>/dev/null || echo 0)
        
        if [ $severe_count -gt 0 ]; then
            echo "🔴 有阻塞 ($severe_count 个严重问题)"
        elif [ $pending_count -gt 0 ]; then
            echo "🟡 有待评审 ($pending_count 个问题)"
        else
            echo "✅ 无"
        fi
    else
        echo "✅ 无"
    fi
}

# ==================== 报告生成函数 ====================

generate_full_report() {
    cat << EOF
# 项目状态报告

**生成时间**: $(date +'%Y-%m-%d %H:%M:%S')
**项目**: $PROJECT_PATH

---

## 📊 总体状态

| 维度 | 状态 |
|------|------|
| 同步状态 | $(check_sync_status) |
| 架构文档 | $(check_doc_status) |
| 编码进度 | $(check_coding_status) |
| 架构问题 | $(check_issue_status) |

---

## 📄 架构文档状态

### 核心文档
EOF

    find "$PROJECT_PATH/docs/architecture" -maxdepth 1 -name "*.md" -type f 2>/dev/null | while read file; do
        local size=$(ls -lh "$file" | awk '{print $5}')
        echo "- ✅ $(basename "$file") ($size)"
    done

    cat << EOF

### ADR 文档
EOF

    find "$PROJECT_PATH/docs/architecture/decisions" -name "*.md" -type f 2>/dev/null | wc -l | xargs -I {} echo "- {} 个 ADR 文档"

    cat << EOF

---

## 💻 编码进度

### 源代码
- 文件数：$(find "$PROJECT_PATH/src" -name "*.py" 2>/dev/null | wc -l)
- 目录数：$(find "$PROJECT_PATH/src" -type d 2>/dev/null | wc -l)

### 测试代码
- 文件数：$(find "$PROJECT_PATH/tests" -name "*.py" 2>/dev/null | wc -l)

### Git 提交
EOF

    if [ -d "$PROJECT_PATH/.git" ]; then
        git -C "$PROJECT_PATH" log --oneline -5 2>/dev/null | sed 's/^/```/' | sed '$s/$$/```/'
    else
        echo "（非 Git 仓库）"
    fi

    cat << EOF

---

## ⚠️ 架构问题追踪

EOF

    if [ -f "$PROJECT_PATH/temp/arch-issues.md" ]; then
        echo "（查看 \`$PROJECT_PATH/temp/arch-issues.md\`）"
    else
        echo "**无架构问题记录**"
    fi

    cat << EOF

---

## 🎯 下一步建议

### 推荐路径

\`\`\`bash
# 1. 查看下一步
skill_use acf-status mode=next

# 2. 执行下一个任务
skill_use acf-flow --next-task

# 3. 任务完成后评审
/zcf:task-review "Task XXX 完成"
\`\`\`

---

**下次检查**: 建议每日 9:00 自动检查（配置 cron 触发器）
EOF
}

generate_brief_report() {
    cat << EOF
## 📊 项目状态简报

**生成时间**: $(date +'%Y-%m-%d %H:%M')

**总体进度**: 估算中...

| 维度 | 状态 |
|------|------|
| 同步状态 | $(check_sync_status) |
| 架构文档 | $(check_doc_status) |
| 编码进度 | $(check_coding_status) |
| 架构问题 | $(check_issue_status) |

**下一步**: \`skill_use acf-flow --next-task\`
EOF
}

generate_next_report() {
    cat << EOF
## 🎯 下一步建议

### 立即执行（5 分钟内可开始）

\`\`\`bash
skill_use acf-flow --next-task
\`\`\`

### 后续步骤

1. 执行 Task XXX（查看 \`temp/phase*-tasks.md\`）
2. 完成后 \`/zcf:task-review "Task XXX 完成"\`
3. 根据评审结果继续或修复

---

**提示**: 使用 \`skill_use acf-status mode=brief\` 查看完整状态
EOF
}

# ==================== 主程序 ====================

echo "正在分析项目状态..." >&2
echo "" >&2

case $MODE in
    full)
        generate_full_report
        ;;
    brief)
        generate_brief_report
        ;;
    next)
        generate_next_report
        ;;
    *)
        echo "未知模式：$MODE" >&2
        echo "用法：$0 [project_path] [full|brief|next]" >&2
        exit 1
        ;;
esac
