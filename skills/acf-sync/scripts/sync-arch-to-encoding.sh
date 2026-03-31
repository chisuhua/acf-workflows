#!/bin/bash
# sync-arch-to-encoding.sh — 架构文档同步脚本
# 用法：./sync-arch-to-encoding.sh [--dry-run] [--list]
# 
# 环境变量:
#   PROPOSAL_ROOT   - 提案仓库路径 (默认：/workspace/mynotes/SkillApps/ecommerce/docs/architecture)
#   ENCODING_ROOT   - 编码仓库路径 (默认：/workspace/ecommerce/docs/architecture)
#   DRY_RUN         - 是否仅预览 (默认：false)

set -e

# 支持环境变量配置（多项目支持）
PROPOSAL_ROOT="${PROPOSAL_ROOT:-/workspace/mynotes/SkillApps/ecommerce/docs/architecture}"
ENCODING_ROOT="${ENCODING_ROOT:-/workspace/ecommerce/docs/architecture}"
DRY_RUN="${DRY_RUN:-false}"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list)
            echo "## 🔍 同步列表预览"
            echo ""
            echo "**源目录**: $PROPOSAL_ROOT"
            echo "**目标目录**: $ENCODING_ROOT"
            echo ""
            echo "### 可同步文件:"
            find "$PROPOSAL_ROOT" -name "*.md" -type f 2>/dev/null | while read file; do
                rel_path="${file#$PROPOSAL_ROOT/}"
                echo "  - $rel_path"
            done
            exit 0
            ;;
        -h|--help)
            echo "用法：./sync-arch-to-encoding.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --dry-run   仅预览，不实际执行同步"
            echo "  --list      显示可同步文件列表"
            echo "  -h, --help  显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROPOSAL_ROOT   提案仓库路径 (默认：/workspace/mynotes/SkillApps/ecommerce/docs/architecture)"
            echo "  ENCODING_ROOT   编码仓库路径 (默认：/workspace/ecommerce/docs/architecture)"
            echo "  DRY_RUN         是否仅预览 (默认：false)"
            exit 0
            ;;
        *)
            echo "❌ 未知选项：$1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

# ==================== 检查函数 ====================

check_directories() {
    # 检查源目录
    if [ ! -d "$PROPOSAL_ROOT" ]; then
        echo "❌ 错误：提案仓库目录不存在"
        echo "路径：$PROPOSAL_ROOT"
        echo ""
        echo "提示：设置环境变量 PROPOSAL_ROOT 指向正确的提案仓库路径"
        exit 1
    fi
    
    # 检查并创建目标目录
    if [ ! -d "$ENCODING_ROOT" ]; then
        echo "📁 创建编码仓库目录：$ENCODING_ROOT"
        mkdir -p "$ENCODING_ROOT"
    fi
    
    # 创建子目录
    mkdir -p "$ENCODING_ROOT/decisions"
    mkdir -p "$ENCODING_ROOT/reviews"
    mkdir -p "$ENCODING_ROOT/plans"
    mkdir -p "$ENCODING_ROOT/phases"
}

# ==================== 同步函数 ====================

sync_files() {
    local synced_count=0
    local sync_list=""
    
    echo "## 🔍 扫描可同步文件..."
    echo ""
    
    # 查找所有 Markdown 文件
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            rel_path="${file#$PROPOSAL_ROOT/}"
            target_file="$ENCODING_ROOT/$rel_path"
            target_dir=$(dirname "$target_file")
            
            sync_list="$sync_list$rel_path\n"
            
            if [ "$DRY_RUN" = "true" ]; then
                echo "[预览] 同步：$rel_path"
            else
                # 创建目标目录
                mkdir -p "$target_dir"
                
                # 复制文件
                cp "$file" "$target_file"
                echo "✅ 同步：$rel_path"
                
                ((synced_count++))
            fi
        fi
    done < <(find "$PROPOSAL_ROOT" -name "*.md" -type f 2>/dev/null | sort)
    
    echo ""
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "## 🔍 同步预览（Dry-run）"
        echo ""
        echo "**源目录**: $PROPOSAL_ROOT"
        echo "**目标目录**: $ENCODING_ROOT"
        echo ""
        echo "### 预计同步文件"
        echo -e "$sync_list" | grep -v "^$"
        echo ""
        echo "**预计文件数**: $(echo -e "$sync_list" | grep -v "^$" | wc -l)"
        echo ""
        echo "执行真实同步：\`$0\`（不加 --dry-run）"
    else
        echo "## ✅ 同步完成"
        echo ""
        echo "**同步时间**: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "**源目录**: $PROPOSAL_ROOT"
        echo "**目标目录**: $ENCODING_ROOT"
        echo ""
        echo "### 同步文件列表"
        echo -e "$sync_list" | grep -v "^$"
        echo ""
        echo "**同步文件数**: $synced_count"
        
        # 生成同步报告
        generate_sync_report "$sync_list" "$synced_count"
        
        echo ""
        echo "### 下一步"
        echo "1. 验证同步：\`ls -la $ENCODING_ROOT/\`"
        echo "2. 提交变更：\`cd $ENCODING_ROOT/.. && git add . && git commit -m 'sync: 架构文档更新'\`"
        echo "3. 通知编码助手：@OpenCode 架构文档已更新"
    fi
}

# ==================== 报告生成函数 ====================

generate_sync_report() {
    local sync_list="$1"
    local synced_count="$2"
    
    cat > "$ENCODING_ROOT/SYNC-REPORT.md" << EOF
# 架构文档同步报告

**同步时间**: $(date +'%Y-%m-%d %H:%M:%S')
**源目录**: $PROPOSAL_ROOT
**目标目录**: $ENCODING_ROOT

## 同步文件列表

$(echo -e "$sync_list" | grep -v "^$")

## 同步文件数

**总计**: $synced_count 个文件

## 下一步

1. 验证同步：\`ls -la $ENCODING_ROOT/\`
2. 提交变更：\`cd $ENCODING_ROOT/.. && git add . && git commit -m 'sync: 架构文档更新'\`
3. 通知编码助手：@OpenCode 架构文档已更新

---

**生成脚本**: \`sync-arch-to-encoding.sh\`
**环境变量**:
- PROPOSAL_ROOT=$PROPOSAL_ROOT
- ENCODING_ROOT=$ENCODING_ROOT
EOF
    
    echo "📄 生成同步报告：$ENCODING_ROOT/SYNC-REPORT.md"
}

# ==================== 主程序 ====================

echo "========================================"
echo "  架构文档同步工具"
echo "========================================"
echo ""

# 检查目录
check_directories

# 执行同步
sync_files

echo ""
echo "========================================"
