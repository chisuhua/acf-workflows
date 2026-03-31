#!/bin/bash
# merge-branches.sh — ACF 多分支合并脚本（精简版）
# 用法：bash scripts/merge-branches.sh --feature <分支名> [--feature <分支名>...]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 参数解析
FEATURE_BRANCHES=()
MAIN_BRANCH="main"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --feature)
            FEATURE_BRANCHES+=("$2")
            shift 2
            ;;
        --main)
            MAIN_BRANCH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "用法：bash scripts/merge-branches.sh --feature <分支名> [--feature <分支名>...]"
            echo ""
            echo "选项:"
            echo "  --feature    功能分支名（可重复）"
            echo "  --main       主分支名（默认：main）"
            echo "  --dry-run    预览模式，不实际合并"
            echo "  -h, --help   显示帮助信息"
            echo ""
            echo "示例:"
            echo "  bash scripts/merge-branches.sh --feature feature/task-001-crawler --feature feature/task-002-retry"
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项：$1${NC}"
            exit 1
            ;;
    esac
done

# 参数验证
if [ ${#FEATURE_BRANCHES[@]} -eq 0 ]; then
    echo -e "${RED}错误：缺少 --feature 参数${NC}"
    exit 1
fi

echo "========================================"
echo "  ACF 多分支合并"
echo "========================================"
echo ""

# 检查点 1: 确认当前分支
echo -e "${YELLOW}[1/5] 检查当前分支...${NC}"
CURRENT_BRANCH=$(git -C "$PROJECT_PATH" rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
    echo -e "${YELLOW}⚠️ 当前分支是 $CURRENT_BRANCH，不是 $MAIN_BRANCH${NC}"
    echo "切换到 $MAIN_BRANCH？(y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git -C "$PROJECT_PATH" checkout "$MAIN_BRANCH"
    else
        echo "请在 $MAIN_BRANCH 分支上运行此脚本"
        exit 1
    fi
else
    echo -e "${GREEN}✓ 当前分支是 $MAIN_BRANCH${NC}"
fi
echo ""

# 检查点 2: 检查工作区干净
echo -e "${YELLOW}[2/5] 检查工作区状态...${NC}"
if [ -n "$(git -C "$PROJECT_PATH" status --porcelain)" ]; then
    echo -e "${RED}✗ 工作区有未提交的修改${NC}"
    git -C "$PROJECT_PATH" status --short
    exit 1
else
    echo -e "${GREEN}✓ 工作区干净${NC}"
fi
echo ""

# 检查点 3: 更新主分支
echo -e "${YELLOW}[3/5] 更新主分支...${NC}"
git -C "$PROJECT_PATH" pull origin "$MAIN_BRANCH" 2>/dev/null || echo "（本地仓库，跳过）"
echo -e "${GREEN}✓ 主分支已更新${NC}"
echo ""

# 检查点 4: 预览合并（检测冲突）
echo -e "${YELLOW}[4/5] 预览合并...${NC}"
echo "将要合并的分支:"
for branch in "${FEATURE_BRANCHES[@]}"; do
    if git -C "$PROJECT_PATH" rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ $branch${NC}"
    else
        echo -e "${RED}  ✗ $branch (分支不存在)${NC}"
        exit 1
    fi
done
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== 预览模式，不实际合并 ===${NC}"
    for branch in "${FEATURE_BRANCHES[@]}"; do
        echo "检查 $branch 的合并冲突..."
        if git -C "$PROJECT_PATH" merge-tree $(git -C "$PROJECT_PATH" merge-base "$MAIN_BRANCH" "$branch") "$MAIN_BRANCH" "$branch" | grep -q "^<<<<<<<"; then
            echo -e "${YELLOW}  ⚠️ $branch 有冲突${NC}"
        else
            echo -e "${GREEN}  ✓ $branch 无冲突${NC}"
        fi
    done
    exit 0
fi
echo ""

# 检查点 5: 执行合并
echo -e "${YELLOW}[5/5] 执行合并...${NC}"
CONFLICTS=()

for branch in "${FEATURE_BRANCHES[@]}"; do
    echo "合并 $branch..."
    if git -C "$PROJECT_PATH" merge "$branch" -m "merge: $branch" 2>&1 | grep -q "CONFLICT"; then
        echo -e "${YELLOW}⚠️ $branch 合并冲突${NC}"
        CONFLICTS+=("$branch")
    else
        echo -e "${GREEN}✓ $branch 合并成功${NC}"
    fi
done
echo ""

# 处理冲突
if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo "========================================"
    echo -e "${YELLOW}⚠️ 发现冲突${NC}"
    echo "========================================"
    echo ""
    echo "冲突分支:"
    for branch in "${CONFLICTS[@]}"; do
        echo "  - $branch"
    done
    echo ""
    echo "请手动解决冲突："
    echo "  1. 编辑冲突文件（搜索 <<<<<<<）"
    echo "  2. git add <文件>"
    echo "  3. git commit"
    echo ""
    echo "或者中止合并："
    echo "  git merge --abort"
    echo ""
    exit 1
fi

# 合并成功
echo "========================================"
echo -e "${GREEN}✅ 所有分支合并成功！${NC}"
echo "========================================"
echo ""
echo "合并的分支:"
for branch in "${FEATURE_BRANCHES[@]}"; do
    echo "  ✓ $branch"
done
echo ""
echo "下一步:"
echo "  1. 运行集成测试：pytest tests/integration/ -v"
echo "  2. 提交到远程：git push origin $MAIN_BRANCH"
echo "  3. 删除功能分支：git branch -d <分支名>"
echo ""
