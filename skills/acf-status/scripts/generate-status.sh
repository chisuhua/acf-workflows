#!/bin/bash
# generate-status.sh — ACF 项目状态生成脚本
# 用法：./generate-status.sh [project_path] [mode]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   MODE         - 报告模式：full/brief/next (默认：full)

set -e

# 支持环境变量配置（多项目支持）
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
MODE="${MODE:-${1:-full}}"

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
    local src_count=$(find "$PROJECT_PATH/src" -name "*.py" -o -name "*.cpp" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l)
    local test_count=$(find "$PROJECT_PATH/tests" -name "*.py" -o -name "*.cpp" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l)
    
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

### 已完成 ✅
\`\`\`bash
find "$PROJECT_PATH/docs/architecture" -name "*.md" -type f 2>/dev/null | head -10
\`\`\`

### 待创建 ❌
- [ ] 总体架构文档（如缺失）
- [ ] 项目测试策略（如缺失）
- [ ] 实施计划（如缺失）

---

## 💻 编码进度

**源代码文件**: $(find "$PROJECT_PATH/src" -name "*.py" -o -name "*.cpp" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l) 个
**测试文件**: $(find "$PROJECT_PATH/tests" -name "*.py" -o -name "*.cpp" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l) 个

---

## 🎯 下一步建议

### 立即执行
\`\`\`bash
skill_use acf-flow --next
\`\`\`

### 后续步骤
1. 执行下一个任务
2. 完成后运行：\`/zcf[:/]task-review "Task XXX 完成"\`

---

**生成脚本**: \`$PROJECT_PATH/acf-workflow/skills/acf-status/scripts/generate-status.sh\`
**使用环境变量**: PROJECT_PATH=$PROJECT_PATH, MODE=$MODE
EOF
}

generate_brief_report() {
    cat << EOF
## 📊 项目状态简报

**生成时间**: $(date +'%Y-%m-%d %H:%M:%S')
**项目**: $PROJECT_PATH
**总体进度**: 估算中...

| 维度 | 状态 |
|------|------|
| 同步状态 | $(check_sync_status) |
| 架构文档 | $(check_doc_status) |
| 编码进度 | $(check_coding_status) |
| 架构问题 | $(check_issue_status) |

**下一步**: \`skill_use acf-flow --next\`

---

**提示**: 完整报告请使用 \`skill_use acf-status mode=full\`
EOF
}

generate_next_report() {
    cat << EOF
## 🎯 下一步建议

### 立即执行（5 分钟内可开始）
\`\`\`bash
skill_use acf-flow --next
\`\`\`

### 后续步骤
1. 执行任务
2. 完成后：\`/zcf[:/]task-review "Task XXX 完成"\`
3. 获取下一个任务：\`skill_use acf-flow --next\`

---

**提示**: 完整报告请使用 \`skill_use acf-status mode=full\`
EOF
}

# ==================== 主程序 ====================

echo "正在生成状态报告..."
echo "项目路径：$PROJECT_PATH"
echo "报告模式：$MODE"
echo ""

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
        echo "❌ 未知模式：$MODE"
        echo "可用模式：full, brief, next"
        exit 1
        ;;
esac
