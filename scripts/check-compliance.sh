#!/bin/bash
# check-compliance.sh — ACF 架构合规检查（精简版）
# 用法：bash scripts/check-compliance.sh [项目目录]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
PROJECT_DIR="${1:-$PROJECT_PATH}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  ACF 架构合规检查"
echo "========================================"
echo ""

# 检查 1: 是否修改了架构文档（只读）
echo -e "${YELLOW}[1/4] 检查架构文档只读性...${NC}"
if git -C "$PROJECT_DIR" diff --name-only 2>/dev/null | grep -q "docs/architecture/"; then
    echo -e "${RED}❌ 禁止修改架构文档（只读）${NC}"
    echo "修改的文件:"
    git -C "$PROJECT_DIR" diff --name-only | grep "docs/architecture/"
    exit 1
else
    echo -e "${GREEN}✅ 未修改架构文档${NC}"
fi
echo ""

# 检查 2: 是否包含未授权外部依赖
echo -e "${YELLOW}[2/4] 检查外部项目依赖...${NC}"
if grep -r "aos-browser\|brainskillforge\|agentic-dsl-runtime" "$PROJECT_DIR/src/" 2>/dev/null; then
    echo -e "${RED}❌ 禁止使用未授权外部项目${NC}"
    echo "发现外部项目引用:"
    grep -r "aos-browser\|brainskillforge\|agentic-dsl-runtime" "$PROJECT_DIR/src/" 2>/dev/null
    exit 1
else
    echo -e "${GREEN}✅ 无未授权外部依赖${NC}"
fi
echo ""

# 检查 3: 测试覆盖率
echo -e "${YELLOW}[3/4] 检查测试覆盖率...${NC}"
if command -v pytest &> /dev/null; then
    COV_RESULT=$(pytest "$PROJECT_DIR/tests/" --cov="$PROJECT_DIR/src/" --cov-fail-under=80 -q 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 测试覆盖率 ≥80%${NC}"
    else
        echo -e "${RED}❌ 测试覆盖率 < 80%${NC}"
        echo "$COV_RESULT" | tail -20
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️ pytest 未安装，跳过测试检查${NC}"
    echo "安装命令：pip install pytest pytest-cov"
fi
echo ""

# 检查 4: 架构问题记录
echo -e "${YELLOW}[4/4] 检查架构问题记录...${NC}"
if [ -f "$PROJECT_DIR/temp/arch-issues.md" ]; then
    ISSUE_COUNT=$(grep -c "## \[" "$PROJECT_DIR/temp/arch-issues.md" 2>/dev/null || echo "0")
    PENDING=$(grep -c "⏳ 待评审" "$PROJECT_DIR/temp/arch-issues.md" 2>/dev/null || echo "0")
    if [ "$PENDING" -gt 0 ]; then
        echo -e "${YELLOW}⚠️ 发现 $PENDING 个待处理架构问题${NC}"
        echo "请查看并处理:"
        echo "  cat $PROJECT_DIR/temp/arch-issues.md"
        echo ""
        echo "继续执行？(y/n): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "已取消"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ 无待处理架构问题${NC}"
    fi
else
    echo -e "${GREEN}✅ 无架构问题记录${NC}"
fi
echo ""

echo "========================================"
echo -e "${GREEN}✅ 架构合规检查通过${NC}"
echo "========================================"
