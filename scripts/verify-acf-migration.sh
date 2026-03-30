#!/bin/bash
echo "=== ACF 迁移验证 ==="
echo ""
echo "1. ACF 工作流目录:"
ls /workspace/acf-workflow/skills/ | sed 's/^/   /'
echo ""
echo "2. ACF 架构讨论目录:"
ls /workspace/mynotes/acf-workflow/ | sed 's/^/   /'
echo ""
echo "3. 项目.acf 目录:"
ls /workspace/ecommerce/.acf/ | sed 's/^/   /'
echo ""
echo "4. 符号链接:"
ls -la ~/.agents/skills/acf-* 2>/dev/null | awk '{print "   "$9" -> "$11}'
echo ""
echo "5. 现有 ZCF 命令:"
ls ~/.agents/commands/zcf/*.md 2>/dev/null | wc -l | xargs -I {} echo "   {} 个命令"
echo ""
echo "✅ 迁移完成"
