# ACF 工作流迁移计划

**创建时间**: 2026-03-29 14:25  
**执行目标**: 将 ZCF 工作流迁移到 ACF（Arch-Coding-Flow）架构  
**预计耗时**: 30 分钟  
**风险等级**: 低（可回滚）

---

## 📁 目标目录结构

```
/workspace/acf-workflow/                    # ACF 工作流项目（新建）
├── docs/
│   ├── acf-workflow.md                     # ACF 工作流文档
│   ├── acf-skills-guide.md                 # Skills 使用指南
│   └── acf-improvement-plan.md             # 改进计划
├── skills/
│   ├── acf-status/
│   │   ├── SKILL.md
│   │   └── scripts/generate-status.sh
│   ├── acf-sync/
│   ├── acf-flow/
│   └── acf-fix/
├── scripts/                                # 工具脚本
└── tests/                                  # 测试用例

/workspace/mynotes/acf-workflow/            # ACF 架构讨论（新建）
├── architecture/
├── reviews/
└── plans/

/workspace/ecommerce/.acf/                  # 电商项目 ACF 运行时（新建）
├── status/
│   ├── current-phase.md
│   └── metrics-dashboard.md
├── temp/
│   ├── fix-tasks.md
│   └── phase*-tasks.md
└── config/
    └── acf-triggers.yaml

~/.agents/skills/acf-*                      # OpenClaw Skills 链接（符号链接）
~/.openclaw/workspace/skills/acf-*          # OpenClaw Skills 链接（符号链接）
```

---

## 📋 迁移步骤

### Step 1: 创建 ACF 工作流项目目录

```bash
# 1.1 创建目录结构
mkdir -p /workspace/acf-workflow/{docs,skills,scripts,tests}

# 1.2 移动现有 Skills（acf- → acf-）
mv ~/.openclaw/workspace/skills/acf-status /workspace/acf-workflow/skills/acf-status
mv ~/.openclaw/workspace/skills/acf-sync /workspace/acf-workflow/skills/acf-sync
mv ~/.openclaw/workspace/skills/acf-flow /workspace/acf-workflow/skills/acf-flow
mv ~/.openclaw/workspace/skills/acf-fix /workspace/acf-workflow/skills/acf-fix

# 1.3 移动工作流文档
mv ~/.openclaw/workspace/docs/workflow/acf-*.md /workspace/acf-workflow/docs/

# 1.4 重命名文档（acf- → acf-）
cd /workspace/acf-workflow/docs/
for file in acf-*.md; do mv "$file" "${file/acf-/acf-}"; done

# 1.5 更新文档内部的路径引用
cd /workspace/acf-workflow/docs/
sed -i 's/acf-workflow/acf-workflow/g' acf-*.md
sed -i 's/acf-status/acf-status/g' acf-*.md
sed -i 's/acf-sync/acf-sync/g' acf-*.md
sed -i 's/acf-flow/acf-flow/g' acf-*.md
sed -i 's/acf-fix/acf-fix/g' acf-*.md

# 1.6 更新 Skills 内部的路径引用
cd /workspace/acf-workflow/skills/
for skill in acf-*/; do
    sed -i 's/acf-/acf-/g' "${skill}SKILL.md"
    sed -i 's/acf-/acf-/g' "${skill}scripts/"*.sh 2>/dev/null
done

# 1.7 移动触发器配置并改名
mv ~/.openclaw/config/acf-triggers.yaml /workspace/acf-workflow/config/acf-triggers.yaml 2>/dev/null || true
mkdir -p /workspace/acf-workflow/config
mv ~/.openclaw/config/acf-triggers.yaml /workspace/acf-workflow/config/acf-triggers.yaml 2>/dev/null || true
sed -i 's/acf-/acf-/g' /workspace/acf-workflow/config/acf-triggers.yaml
```

**验证**:
```bash
ls -la /workspace/acf-workflow/skills/
# 应显示：acf-status, acf-sync, acf-flow, acf-fix
```

---

### Step 2: 创建 ACF 架构讨论目录

```bash
# 2.1 创建目录
mkdir -p /workspace/mynotes/acf-workflow/{architecture,reviews,plans}

# 2.2 创建 README
cat > /workspace/mynotes/acf-workflow/README.md << 'EOF'
# ACF 双循环工作流 — 架构讨论

**用途**: ACF 工作流框架的架构提案、评审、决策

**目录结构**:
- `architecture/` - 架构草稿、ADR
- `reviews/` - 评审记录
- `plans/` - 实施计划

**同步到编码仓库**: `/workspace/acf-workflow/docs/`
EOF
```

**验证**:
```bash
ls -la /workspace/mynotes/acf-workflow/
```

---

### Step 3: 创建项目 .acf 目录（电商项目）

```bash
# 3.1 创建目录
mkdir -p /workspace/ecommerce/.acf/{status,temp,config}

# 3.2 移动状态追踪文件
mv /workspace/ecommerce/status/* /workspace/ecommerce/.acf/status/ 2>/dev/null || true

# 3.3 移动临时文件
mv /workspace/ecommerce/temp/fix-tasks.md /workspace/ecommerce/.acf/temp/ 2>/dev/null || true
mv /workspace/ecommerce/temp/phase*-tasks.md /workspace/ecommerce/.acf/temp/ 2>/dev/null || true

# 3.4 复制触发器配置（项目级）
cp /workspace/acf-workflow/config/acf-triggers.yaml /workspace/ecommerce/.acf/config/acf-triggers.yaml

# 3.5 添加 .gitignore
cat > /workspace/ecommerce/.acf/.gitignore << 'EOF'
# ACF 运行时文件（项目特定）
*.log
*.tmp
EOF
```

**验证**:
```bash
ls -la /workspace/ecommerce/.acf/
```

---

### Step 4: 创建符号链接（OpenClaw 全局调用）

```bash
# 4.1 确保目标目录存在
mkdir -p ~/.agents/skills/
mkdir -p ~/.openclaw/workspace/skills/

# 4.2 创建符号链接
ln -sf /workspace/acf-workflow/skills/acf-status ~/.agents/skills/acf-status
ln -sf /workspace/acf-workflow/skills/acf-status ~/.openclaw/workspace/skills/acf-status

ln -sf /workspace/acf-workflow/skills/acf-sync ~/.agents/skills/acf-sync
ln -sf /workspace/acf-workflow/skills/acf-sync ~/.openclaw/workspace/skills/acf-sync

ln -sf /workspace/acf-workflow/skills/acf-flow ~/.agents/skills/acf-flow
ln -sf /workspace/acf-workflow/skills/acf-flow ~/.openclaw/workspace/skills/acf-flow

ln -sf /workspace/acf-workflow/skills/acf-fix ~/.agents/skills/acf-fix
ln -sf /workspace/acf-workflow/skills/acf-fix ~/.openclaw/workspace/skills/acf-fix
```

**验证**:
```bash
ls -la ~/.agents/skills/acf-*
ls -la ~/.openclaw/workspace/skills/acf-*
# 应显示符号链接指向 /workspace/acf-workflow/skills/
```

---

### Step 5: 更新文档中的路径引用

```bash
# 5.1 更新改进计划文档
sed -i 's|~/.openclaw/workspace/skills/|/workspace/acf-workflow/skills/|g' \
    /workspace/acf-workflow/docs/acf-improvement-plan.md

sed -i 's|acf-triggers.yaml|acf-triggers.yaml|g' \
    /workspace/acf-workflow/docs/acf-improvement-plan.md

# 5.2 更新 Skills 使用指南
sed -i 's|acf-|acf-|g' /workspace/acf-workflow/docs/acf-skills-guide.md

# 5.3 创建迁移后验证脚本
cat > /workspace/acf-workflow/scripts/verify-migration.sh << 'EOF'
#!/bin/bash
# verify-migration.sh — ACF 迁移验证脚本

echo "=== ACF 迁移验证 ==="
echo ""

# 1. 检查 ACF 工作流目录
echo "1. 检查 ACF 工作流目录..."
if [ -d "/workspace/acf-workflow/skills" ]; then
    echo "   ✅ /workspace/acf-workflow/skills/ 存在"
    ls /workspace/acf-workflow/skills/ | sed 's/^/      /'
else
    echo "   ❌ /workspace/acf-workflow/skills/ 不存在"
fi

# 2. 检查 ACF 架构讨论目录
echo ""
echo "2. 检查 ACF 架构讨论目录..."
if [ -d "/workspace/mynotes/acf-workflow" ]; then
    echo "   ✅ /workspace/mynotes/acf-workflow/ 存在"
else
    echo "   ❌ /workspace/mynotes/acf-workflow/ 不存在"
fi

# 3. 检查项目 .acf 目录
echo ""
echo "3. 检查项目 .acf 目录..."
if [ -d "/workspace/ecommerce/.acf" ]; then
    echo "   ✅ /workspace/ecommerce/.acf/ 存在"
    ls /workspace/ecommerce/.acf/ | sed 's/^/      /'
else
    echo "   ❌ /workspace/ecommerce/.acf/ 不存在"
fi

# 4. 检查符号链接
echo ""
echo "4. 检查符号链接..."
for skill in acf-status acf-sync acf-flow acf-fix; do
    if [ -L "~/.agents/skills/$skill" ]; then
        echo "   ✅ ~/.agents/skills/$skill → $(readlink ~/.agents/skills/$skill)"
    else
        echo "   ❌ ~/.agents/skills/$skill 不存在或不是符号链接"
    fi
done

# 5. 测试 Skill 调用
echo ""
echo "5. 测试 Skill 调用（dry-run）..."
echo "   运行：skill_use acf-status mode=brief"
# skill_use acf-status mode=brief

echo ""
echo "=== 验证完成 ==="
EOF
chmod +x /workspace/acf-workflow/scripts/verify-migration.sh
```

---

## 🧪 验证步骤

### 验证 1: 目录结构

```bash
# 运行验证脚本
/workspace/acf-workflow/scripts/verify-migration.sh
```

### 验证 2: Skill 调用测试

```bash
# 测试 acf-status
skill_use acf-status mode=brief

# 测试 acf-sync（dry-run）
skill_use acf-sync dry_run=true

# 测试 acf-flow
skill_use acf-flow

# 测试 acf-fix
skill_use acf-fix action=list
```

### 验证 3: 符号链接检查

```bash
# 检查符号链接
ls -la ~/.agents/skills/acf-*
ls -la ~/.openclaw/workspace/skills/acf-*
```

### 验证 4: 现有 ZCF 命令不受影响

```bash
# 确认现有 ZCF 命令仍然可用
ls ~/.agents/commands/zcf/
# 应显示：arch-doc.md, status.md, task-review.md, ...
```

---

## 🔙 回滚方案

如果迁移失败，执行以下命令回滚：

```bash
# 1. 删除 ACF 目录
rm -rf /workspace/acf-workflow/
rm -rf /workspace/mynotes/acf-workflow/
rm -rf /workspace/ecommerce/.acf/

# 2. 删除符号链接
rm -f ~/.agents/skills/acf-*
rm -f ~/.openclaw/workspace/skills/acf-*

# 3. 恢复原始 ZCF 文件（如果有备份）
# mv /backup/acf-* ~/.openclaw/workspace/skills/

# 4. 验证回滚
ls ~/.agents/commands/zcf/
# 确认 ZCF 命令仍然存在
```

---

## 📊 迁移检查清单

### 迁移前
- [ ] 备份现有 ZCF 文件
- [ ] 确认现有 ZCF 命令可用
- [ ] 记录当前状态

### 迁移中
- [ ] Step 1: 创建 ACF 工作流目录 ✅
- [ ] Step 2: 创建 ACF 架构讨论目录 ✅
- [ ] Step 3: 创建项目 .acf 目录 ✅
- [ ] Step 4: 创建符号链接 ✅
- [ ] Step 5: 更新文档路径 ✅

### 迁移后
- [ ] 运行验证脚本
- [ ] 测试所有 ACF Skills
- [ ] 确认现有 ZCF 命令不受影响
- [ ] 更新改进计划文档

---

## 📁 文件位置对照表

| 原位置 | 新位置 | 说明 |
|--------|--------|------|
| `~/.openclaw/workspace/skills/acf-*` | `/workspace/acf-workflow/skills/acf-*` | Skills 移动 + 重命名 |
| `~/.openclaw/workspace/docs/workflow/acf-*.md` | `/workspace/acf-workflow/docs/acf-*.md` | 文档移动 + 重命名 |
| `~/.openclaw/config/acf-triggers.yaml` | `/workspace/acf-workflow/config/acf-triggers.yaml` | 配置移动 + 重命名 |
| - | `/workspace/mynotes/acf-workflow/` | 新建架构讨论目录 |
| `/workspace/ecommerce/status/` | `/workspace/ecommerce/.acf/status/` | 项目状态移动 |
| `/workspace/ecommerce/temp/phase*-tasks.md` | `/workspace/ecommerce/.acf/temp/` | 任务计划移动 |
| - | `~/.agents/skills/acf-*` | 新建符号链接 |

---

## 🎯 执行顺序

```
14:25 — 开始迁移
14:26 — Step 1: 创建 ACF 工作流目录
14:28 — Step 2: 创建 ACF 架构讨论目录
14:29 — Step 3: 创建项目 .acf 目录
14:30 — Step 4: 创建符号链接
14:32 — Step 5: 更新文档路径
14:35 — 验证步骤
14:40 — 完成迁移
───────────────────────
总耗时：约 15 分钟
```

---

**创建人**: DevMate  
**创建时间**: 2026-03-29 14:25  
**状态**: 待执行  
**下次更新**: 迁移完成后更新状态
