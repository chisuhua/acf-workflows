# ZCF Skills 使用指南

**版本**: v1.0  
**创建时间**: 2026-03-29  
**适用**: 所有使用 ZCF 工作流的项目

---

## 📋 Skills 列表

### 核心 Skills（P0）

| Skill | 用途 | 调用方式 | 触发条件 |
|-------|------|---------|---------|
| `acf-status` | 项目状态分析 | `skill_use acf-status [mode]` | 每日 9:00 自动 |
| `acf-sync` | 架构文档同步 | `skill_use acf-sync [--dry-run]` | 架构评审通过后 |
| `acf-flow` | 任务自动流转 | `skill_use acf-flow [--next]` | Task 评审通过后 |
| `acf-fix` | 修复任务创建 | `skill_use acf-fix --create <摘要>` | P0 问题发现时 |

### 架构 Skills（骨架）

| Skill | 用途 | 状态 |
|-------|------|------|
| `acf-architect` | 架构设计 | 🟡 骨架 |
| `acf-reviewer` | 任务评审 | 🟡 骨架 |
| `acf-coordinator` | 协调调度 | 🟡 骨架 |
| `acf-executor` | 任务执行 | 🟡 骨架 |

---

## 🎯 显式调用

### 语法

```bash
skill_use <skill-name> [param1=value1] [param2=value2]
```

### 示例

```bash
# 查看完整状态报告
skill_use acf-status mode=full

# 预览同步（不实际执行）
skill_use acf-sync dry_run=true

# 获取下一个任务
skill_use acf-flow

# 创建修复任务
skill_use acf-fix action=create summary="Mock 路径错误" priority=P0
```

---

## 🔄 触发调用

### 触发器配置

**位置**: `~/.openclaw/config/acf-triggers.yaml`

### 自动触发场景

| 场景 | 触发条件 | 执行动作 |
|------|---------|---------|
| 每日晨会 | cron "0 9 * * *" | `skill_use acf-status mode=brief` |
| Task 完成 | `/zcf:task-review` 评审通过 | `skill_use acf-flow --next` |
| P0 问题 | `/zcf:task-review` 发现严重问题 | `skill_use acf-fix --create` |
| 阶段完成 | `/zcf:task-review` 阶段完成 | `skill_use acf-status mode=full` |
| 架构评审通过 | `/zcf:task-review` 架构通过 | `skill_use acf-sync` |

---

## 📁 文件结构

```
~/.openclaw/workspace/skills/
├── acf-status/
│   ├── SKILL.md                 # Skill 文档
│   └── scripts/
│       └── generate-status.sh   # 封装脚本
├── acf-sync/
│   ├── SKILL.md
│   └── scripts/
│       └── sync-arch-to-encoding.sh
├── acf-flow/
│   ├── SKILL.md
│   └── scripts/
│       └── auto-flow.sh
└── acf-fix/
    ├── SKILL.md
    └── scripts/
        └── create-fix-task.sh
```

---

## 🔧 故障排查

### 问题 1: Skill 找不到

**症状**: `skill_use acf-status` 返回 "skill not found"

**解决**:
```bash
# 检查 Skill 目录
ls -la ~/.openclaw/workspace/skills/acf-status/

# 确认 SKILL.md 存在
cat ~/.openclaw/workspace/skills/acf-status/SKILL.md
```

---

### 问题 2: 脚本无执行权限

**症状**: `Permission denied`

**解决**:
```bash
chmod +x ~/.openclaw/workspace/skills/*/scripts/*.sh
```

---

### 问题 3: 触发器不执行

**症状**: 触发条件满足，但未自动执行

**解决**:
```bash
# 检查触发器配置
cat ~/.openclaw/config/acf-triggers.yaml

# 检查触发器日志
tail -f ~/.openclaw/logs/acf-triggers.log
```

---

## 🎓 最佳实践

### 1. 优先使用触发调用

```bash
# ❌ 手动执行
/zcf:task-review "Task 001 完成"
# 然后手动：skill_use acf-flow --next

# ✅ 自动触发
/zcf:task-review "Task 001 完成"
# 自动触发 acf-flow → 下一个任务
```

---

### 2. 使用 dry-run 预览

```bash
# 同步前先预览
skill_use acf-sync dry_run=true

# 确认无误后执行
skill_use acf-sync
```

---

### 3. 定期检查状态

```bash
# 每日晨会
skill_use acf-status mode=brief

# 阶段完成后
skill_use acf-status mode=full
```

---

## 🔗 相关文档

- `acf-workflow.md` - ZCF 工作流完整文档
- `acf-cheatsheet.md` - 快速参考卡
- `acf-triggers.yaml` - 触发器配置

---

**维护人**: DevMate  
**最后更新**: 2026-03-29  
**下次评审**: 2026-04-05
