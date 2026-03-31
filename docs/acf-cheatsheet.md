# ACF 工作流快速参考卡

**版本**: v3.2 | **更新**: 2026-03-31

---

## 🌳 任务接收决策树（⭐ 强制）

```
收到任务
  │
  ├─ 需求澄清（4 问）─ 有模糊 → Interview（5 问，2 轮）
  │                     全明确 ↓
  ├─ 复杂度评估（4 问）─ 全否 → 编码循环（直接执行）
  │                     有是 ↓
  └─ 架构循环 ──→ 草稿 → 老板评审 → OpenCode → 对比 → 同步
```

**详细流程**: `docs/decision-tree.md`

---

## 📀 双层记忆结构

| 层级 | 位置 | 用途 | 恢复命令 |
|------|------|------|---------|
| **全局** | `memory/YYYY-MM-DD.md` | 跨项目日志 | `cat memory/$(date +%Y-%m-%d).md` |
| **项目** | `<Project>/.acf/status/current-task.md` | 项目进展 | `cat .acf/status/current-task.md` |

**Gateway Restart 恢复**:
```bash
# 1. 全局记忆
cat memory/YYYY-MM-DD.md | grep -A 10 "## In Progress"

# 2. 项目进展
for p in /workspace/*/; do
  [ -f "$p/.acf/status/current-task.md" ] && cat "$p/.acf/status/current-task.md"
done
```

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
| 提案仓库 | `/workspace/mynotes/<Project>/docs/architecture/` |
| 编码仓库 | `/workspace/<Project>/docs/architecture/` |
| 项目记忆 | `/workspace/<Project>/.acf/` |
| 全局记忆 | `memory/YYYY-MM-DD.md` |
| 决策树 | `docs/decision-tree.md` |
| ACF Skills | `/workspace/acf-workflow/skills/` |

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
早上 9:00     → skill_use acf-status mode=brief  (查看状态)
新任务接收    → 决策树检查 → Interview/架构循环  (强制)
开始编码前    → 读取 .acf/status/current-task.md (确认进展)
任务执行前    → 更新 current-task.md → acf-executor
任务完成后    → /zcf/task-review → acf-flow → 更新 current-task.md
晚上          → 更新 memory/YYYY-MM-DD.md + .acf/ (双层记忆)
Gateway 重启  → 读取双层记忆 → 恢复报告 → 继续
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
