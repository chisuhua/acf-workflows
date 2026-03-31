#!/bin/bash
# cleanup-claims.sh — 清理过期 claims（定时执行）
# 用法：bash scripts/cleanup-claims.sh [timeout_minutes]
# 
# 环境变量:
#   PROJECT_PATH - 项目根目录 (默认：/workspace/ecommerce)
#   CLAIMS_FILE  - claims 文件路径 (默认：$PROJECT_PATH/.acf/temp/claims.json)

set -e

# 支持环境变量配置
PROJECT_PATH="${PROJECT_PATH:-/workspace/ecommerce}"
CLAIMS_FILE="${CLAIMS_FILE:-$PROJECT_PATH/.acf/temp/claims.json}"

# 加载 claims 库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/claims.sh"

# 配置参数
CLAIMS_TIMEOUT="${1:-$(openclaw config show acf.executor.claimTimeoutMinutes 2>/dev/null || echo 120)}"

# 确保 claims 目录存在
claims_init

# 清理前统计
before_count=$(count_claims)

# 清理过期 claims
cleanup_claims "$CLAIMS_TIMEOUT" > /dev/null

# 清理后统计
after_count=$(count_claims)
removed=$((before_count - after_count))

# 输出结果
echo "========================================"
echo "  Claims 清理报告"
echo "========================================"
echo ""
echo "配置:"
echo "  项目路径：$PROJECT_PATH"
echo "  Claims 文件：$CLAIMS_FILE"
echo "  过期时间：$CLAIMS_TIMEOUT 分钟"
echo ""
echo "统计:"
echo "  清理前：$before_count 个"
echo "  清理后：$after_count 个"
echo "  已清理：$removed 个"
echo ""

if [ "$removed" -gt 0 ]; then
    echo "✅ 清理完成：$removed 个过期 claims 已删除"
else
    echo "✅ 无过期 claims"
fi

# 列出剩余 claims
if [ "$after_count" -gt 0 ]; then
    echo ""
    echo "活跃 claims:"
    list_claims
fi

echo ""
