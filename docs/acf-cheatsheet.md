# ZCF 工作流快速参考卡

**版本**: v2.0 | **更新**: 2026-03-29

---

## 🚀 核心命令

### 架构循环（慢循环）

```bash
# 启动架构讨论
/zcf:arch-doc "<主题>"

# 架构评审
/zcf:task-review "<架构草稿> 评审"
```

### 编码循环（快循环）

```bash
# 执行任务
task(prompt="Task XXX: <描述>", category="quick|deep")

# 任务评审
/zcf:task-review "Task XXX 完成"
```

### 状态与同步

```bash
# 查看状态
/zcf:status [full|brief|next]

# 同步架构文档
/zcf:sync-to-encoding [--dry-run] [--list]

# GitHub 同步
/zcf:github-sync "<阶段名>"
```

---

## 📁 关键路径

| 用途 | 路径 |
|------|------|
| 提案仓库 | `/workspace/mynotes/SkillApps/ecommerce/docs/architecture/` |
| 编码仓库 | `/workspace/ecommerce/docs/architecture/` |
| 状态追踪 | `/workspace/ecommerce/status/` |
| 执行日志 | `~/.openclaw/workspace/docs/workflow/execution-log-template.md` |
| Agent Skills | `~/.openclaw/workspace/docs/workflow/skills/` |
| 同步脚本 | `~/.openclaw/workspace/scripts/sync-arch-to-encoding.sh` |

---

## 🎯 偏差处理速查

| 偏差类型 | 级别 | 行动 |
|----------|------|------|
| 接口参数新增 | ⚠️ 轻微 | 记录 CHANGELOG，继续 |
| 技术选型补充 | ⚠️ 中等 | 更新文档，继续 |
| 架构违规 | ❌ 严重 | **暂停**，通知架构师 |
| 依赖方向错误 | ❌ 严重 | **暂停**，通知架构师 |

---

## 📋 每日工作流

```
早上 9:00  → /zcf:status brief      (查看今日计划)
开始编码前 → /zcf:sync-to-encoding --list (确认文档最新)
任务完成后 → /zcf:task-review "Task XXX 完成" (自动评审)
晚上       → 检查 memory/YYYY-MM-DD.md (记录日志)
```

---

## 🔗 文档链接

- **权威版工作流**: `~/.openclaw/workspace/docs/workflow/acf-workflow.md`
- **执行日志模板**: `~/.openclaw/workspace/docs/workflow/execution-log-template.md`
- **状态仪表盘**: `/workspace/ecommerce/status/current-phase.md`
- **今日记忆**: `~/.openclaw/workspace/memory/2026-03-29.md`

---

## 🆘 常见问题

**Q: OpenCode 不理解架构约束？**
A: 在 Prompt 开头明确列出关键约束（最多 3 条），使用 `@file` 引用 ADR

**Q: 任务执行时间过长？**
A: 拆分为多个子任务，每个任务聚焦单一功能

**Q: 如何查看历史状态？**
A: 查看 `/workspace/ecommerce/status/` 目录中的历史报告

---

**打印建议**: 此卡片设计为单页，可打印贴在显示器旁
