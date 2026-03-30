# ACF 迁移遗留文件清理

**检查时间**: 2026-03-29 14:35  
**清理目标**: 清理或归档遗留的 zcf- 文件

---

## 📋 遗留文件清单

### 1. 需要保留的文件（正常）

| 文件 | 位置 | 说明 | 处理 |
|------|------|------|------|
| `zcf-status.md` | `/workspace/ecommerce/.claude/commands/` | OpenCode 项目级命令 | ✅ 保留 |
| `zcf-*.md` | `~/.agents/commands/zcf/` | OpenCode 全局命令（13 个） | ✅ 保留 |

---

### 2. 需要清理的文件

| 文件 | 位置 | 说明 | 处理 |
|------|------|------|------|
| `zcf-triggers.yaml` | `~/.openclaw/config/` | 旧触发器配置（已迁移） | 🗑️ 删除 |
| `zcf-workflow-v1.md` | `/workspace/home/openclaw/workspace/docs/workflow/archive/` | 旧工作流文档 | 🗑️ 删除或归档 |
| `zcf-workflow-v2-draft.md` | `/workspace/home/openclaw/workspace/docs/workflow/archive/` | 旧工作流文档 | 🗑️ 删除或归档 |
| `zcf-*/` | `/workspace/home/.agents/skills/` | 旧 Skills 骨架（4 个） | 🗑️ 删除 |
| `zcf-*/` | `/workspace/home/openclaw/workspace/docs/workflow/skills/` | 旧 Skills 文档 | 🗑️ 删除 |
| `execution-log-template.md` | `~/.openclaw/workspace/docs/workflow/` | 旧文档（已迁移） | 🗑️ 删除 |
| `skills/` | `~/.openclaw/workspace/docs/workflow/skills/` | 旧 Skills 目录 | 🗑️ 删除 |

---

### 3. 需要确认的文件

| 文件 | 位置 | 说明 | 待定 |
|------|------|------|------|
| `/workspace/zcf-workflow` | 根目录 | 可能是测试目录 | ❓ 确认用途 |
| `fix-task-001.md` | `/workspace/ecommerce/temp/` | 旧修复任务 | ❓ 是否需要 |
| `issues-found.md` | `/workspace/ecommerce/temp/` | 旧问题记录 | ❓ 是否需要 |
| `iteration-*.md` | `/workspace/ecommerce/temp/` | 迭代报告 | ❓ 是否需要 |
| `phase*-*.md` | `/workspace/ecommerce/temp/` | 阶段报告 | ❓ 是否需要 |

---

## 🗑️ 清理命令

### 立即清理（确认无用的文件）

```bash
# 1. 删除旧触发器配置
rm -f ~/.openclaw/config/zcf-triggers.yaml

# 2. 删除旧工作流文档（archive 目录）
rm -rf /workspace/home/openclaw/workspace/docs/workflow/archive/

# 3. 删除旧 Skills 目录
rm -rf /workspace/home/.agents/skills/zcf-*/
rm -rf /workspace/home/openclaw/workspace/docs/workflow/skills/

# 4. 删除旧文档
rm -f ~/.openclaw/workspace/docs/workflow/execution-log-template.md
```

### 待定清理（需要确认）

```bash
# 1. 检查 /workspace/zcf-workflow 目录
ls -la /workspace/zcf-workflow/

# 2. 清理 temp 目录（需要确认）
# 建议：将重要报告移动到 .acf/temp/archive/
mkdir -p /workspace/ecommerce/.acf/temp/archive/
mv /workspace/ecommerce/temp/iteration-*.md /workspace/ecommerce/.acf/temp/archive/
mv /workspace/ecommerce/temp/phase*-*.md /workspace/ecommerce/.acf/temp/archive/
```

---

## 📊 清理后目录结构

### 清理前

```
~/.openclaw/
├── config/
│   └── zcf-triggers.yaml          # 待删除
└── workspace/docs/workflow/
    ├── archive/
    │   └── zcf-*.md               # 待删除
    ├── skills/
    │   └── zcf-*/                 # 待删除
    └── execution-log-template.md  # 待删除
```

### 清理后

```
~/.openclaw/
└── workspace/docs/workflow/       # 已清空（ACF 文件在 /workspace/acf-workflow/）
```

---

## ✅ 验证清理结果

```bash
# 验证命令
echo "=== 检查遗留的 zcf- 文件 ==="
find /workspace -name "zcf-*" -type f 2>/dev/null | grep -v node_modules
find ~/.openclaw -name "zcf-*" 2>/dev/null
find ~/.agents -name "zcf-*" 2>/dev/null

# 应该只显示：
# - /workspace/ecommerce/.claude/commands/zcf-status.md (项目级，保留)
# - ~/.agents/commands/zcf/*.md (OpenCode 命令，保留)
```

---

## 📝 清理检查清单

- [ ] 删除 `~/.openclaw/config/zcf-triggers.yaml`
- [ ] 删除 `/workspace/home/openclaw/workspace/docs/workflow/archive/`
- [ ] 删除 `/workspace/home/.agents/skills/zcf-*/`
- [ ] 删除 `/workspace/home/openclaw/workspace/docs/workflow/skills/`
- [ ] 删除 `~/.openclaw/workspace/docs/workflow/execution-log-template.md`
- [ ] 确认 `/workspace/zcf-workflow/` 用途
- [ ] 整理 `/workspace/ecommerce/temp/` 旧报告
- [ ] 验证清理结果

---

**检查人**: DevMate  
**检查时间**: 2026-03-29 14:35  
**状态**: 待清理
