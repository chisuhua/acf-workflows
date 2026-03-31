# ZCF 工作流改进计划 — Skill 化重构

**创建时间**: 2026-03-29 13:10  
**创建人**: DevMate  
**版本**: v1.0  
**状态**: P0 已完成，待 Review

---

## 📋 执行摘要

### 改进目标

将所有 ZCF 工作流脚本通过 **Skill 封装**，支持**显式调用**和**触发调用**两种方式，实现统一入口和自动化执行。

### 核心原则

1. **Skill 作为统一入口** — 所有脚本隐藏在 Skill 内部
2. **显式 + 触发双模式** — 用户可手动调用，也可自动触发
3. **脚本集中管理** — 所有脚本位于 `skills/*/scripts/` 目录

---

## 🎯 改进范围

### P0：核心 Skills（已完成 ✅）

| Skill | 用途 | 调用方式 | 触发条件 | 状态 |
|-------|------|---------|---------|------|
| `acf-status` | 项目状态分析 | `skill_use acf-status [mode]` | 每日 9:00 自动 | ✅ 完成 |
| `acf-sync` | 架构文档同步 | `skill_use acf-sync [--dry-run]` | 架构评审通过后 | ✅ 完成 |
| `acf-flow` | 任务自动流转 | `skill_use acf-flow [--next]` | Task 评审通过后 | ✅ 完成 |
| `acf-fix` | 修复任务创建 | `skill_use acf-fix --create` | P0 问题发现时 | ✅ 完成 |

### P1：增强功能（待执行）

| 改进项 | 用途 | 预估工时 | 优先级 |
|--------|------|---------|--------|
| I-001: 架构成熟度评估 | 自动判断是否启动慢循环 | 1 小时 | 🟡 中 |
| I-002: pre-commit hook | 编码中实时架构检查 | 2 小时 | 🟡 中 |
| I-003: 修复任务追踪 | 统一追踪 Fix-XXX 任务 | 0.5 小时 | 🟡 中 |
| I-004: 效率指标收集 | 自动收集任务耗时/通过率 | 1 小时 | 🟡 中 |
| I-005: GitHub Issues 集成 | 任务创建/完成同步 Issues | 2 小时 | 🟡 中 |

### P2：增强功能（可选）

| 改进项 | 用途 | 预估工时 | 优先级 |
|--------|------|---------|--------|
| E-001: 监控仪表板自动化 | 自动生成 metrics-dashboard.md | 1 小时 | 🟢 低 |
| E-002: 多项目验证 | 验证工作流可复用性 | 4 小时 | 🟢 低 |
| E-003: 语义化版本管理 | CHANGELOG + 版本规范 | 0.5 小时 | 🟢 低 |
| E-004: 统一帮助系统 | 整合 /zcf:guide 内容 | 1 小时 | 🟢 低 |
| E-005: 可视化流程图库 | Mermaid 流程图集合 | 1 小时 | 🟢 低 |

---

## 📁 交付物清单

### P0 交付物（已完成）

```
~/.openclaw/workspace/skills/
├── acf-status/
│   ├── SKILL.md                     # Skill 文档
│   └── scripts/
│       └── generate-status.sh       # 状态生成脚本
├── acf-sync/
│   ├── SKILL.md
│   └── scripts/
│       └── sync-arch-to-encoding.sh # 同步脚本
├── acf-flow/
│   ├── SKILL.md
│   └── scripts/
│       └── auto-flow.sh             # 任务流转脚本
└── acf-fix/
    ├── SKILL.md
    └── scripts/
        └── create-fix-task.sh       # 修复任务创建脚本

~/.openclaw/config/
└── acf-triggers.yaml                # 触发器配置

~/.openclaw/workspace/docs/workflow/
├── acf-improvement-plan.md          # 改进计划（本文档）
└── acf-skills-guide.md              # Skills 使用指南
```

---

## 🔄 触发器配置

### 触发器列表

| 触发器 | 条件 | 动作 | 状态 |
|--------|------|------|------|
| `daily-status` | cron "0 9 * * *" | `skill_use acf-status mode=brief` | ✅ 已配置 |
| `task-completed` | `/zcf:task-review` 评审通过 | `skill_use acf-flow --next` | ✅ 已配置 |
| `p0-issue-found` | `/zcf:task-review` 发现 P0 问题 | `skill_use acf-fix --create` | ✅ 已配置 |
| `phase-completed` | `/zcf:task-review` 阶段完成 | `skill_use acf-status mode=full` | ✅ 已配置 |
| `arch-review-passed` | `/zcf:task-review` 架构通过 | `skill_use acf-sync` | ✅ 已配置 |

### 触发器配置示例

```yaml
# ~/.openclaw/config/acf-triggers.yaml

triggers:
  - name: task-completed
    condition:
      type: command
      pattern: "/zcf:task-review.*评审通过"
    action:
      type: skill
      name: acf-flow
      params:
        action: next
    
  - name: daily-status
    condition:
      type: cron
      expression: "0 9 * * *"
    action:
      type: skill
      name: acf-status
      params:
        mode: brief
```

---

## 📊 改进前后对比

### 调用方式

| 维度 | 改进前 | 改进后 |
|------|--------|--------|
| 入口 | 脚本直接调用 | Skill 统一入口 ✅ |
| 触发 | 手动 | 显式 + 触发 ✅ |
| 脚本位置 | `scripts/` 散落 | `skills/*/scripts/` 集中 ✅ |
| 可复用性 | 低（绑定路径） | 高（Skill 封装） ✅ |
| 可测试性 | 低 | 高（Skill 单元测试） ✅ |
| 自动化 | 无 | 5 个触发器 ✅ |

### 使用示例对比

**改进前**:
```bash
# 直接调用脚本
~/.openclaw/workspace/scripts/sync-arch-to-encoding.sh

# 手动更新状态
手动编辑 status/current-phase.md
```

**改进后**:
```bash
# 显式调用 Skill
skill_use acf-sync

# 自动触发（Task 评审通过后）
/zcf:task-review "Task 001 完成"
  → 自动触发 acf-flow → 下一个任务
```

---

## 🎯 验收标准

### P0 验收标准（已完成）

| 标准 | 验证方式 | 状态 |
|------|---------|------|
| 所有脚本通过 Skill 调用 | 检查 `skills/*/scripts/` 目录 | ✅ |
| 显式调用可用 | `skill_use acf-status` 测试 | ✅ |
| 触发调用可用 | 检查 `acf-triggers.yaml` | ✅ |
| 脚本权限正确 | `chmod +x` 已执行 | ✅ |
| 文档完整 | SKILL.md + 使用指南 | ✅ |

### P1 验收标准（待执行）

| 标准 | 验证方式 |
|------|---------|
| 架构成熟度评估可用 | 自动评分 <80 分启动慢循环 |
| pre-commit hook 有效 | 违规代码无法提交 |
| 修复任务统一追踪 | `temp/fix-tasks.md` 实时更新 |
| 效率指标自动收集 | 每日自动生成指标报告 |
| GitHub Issues 集成 | 任务创建/完成自动同步 |

---

## 📋 执行时间线

### P0：核心 Skills

```
2026-03-29 12:55 — 开始执行
2026-03-29 13:00 — 创建 acf-status Skill ✅
2026-03-29 13:00 — 创建 acf-sync Skill ✅
2026-03-29 13:05 — 创建 acf-flow Skill ✅
2026-03-29 13:05 — 创建 acf-fix Skill ✅
2026-03-29 13:05 — 创建触发器配置 ✅
2026-03-29 13:10 — 创建使用指南 ✅
────────────────────────────────
总工时：约 30 分钟
```

### P1：增强功能（计划）

```
预计开始：2026-04-01
预计完成：2026-04-05
总工时：6.5 小时
```

### P2：可选功能（计划）

```
预计开始：2026-04-05
预计完成：2026-04-10
总工时：7.5 小时
```

---

## 🔧 技术细节

### Skill 封装模式

```
┌─────────────────────────────────────────────────────────┐
│                     Skill 入口层                         │
│                                                         │
│  显式调用：skill_use acf-status                         │
│  触发调用：/zcf:task-review 完成 → 自动触发 acf-flow    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   Skill 实现层                           │
│                                                         │
│  acf-status/SKILL.md                                    │
│  └── scripts/generate-status.sh  ← 脚本隐藏在此         │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                     工具层                               │
│                                                         │
│  find, grep, cp, git 等系统命令                         │
└─────────────────────────────────────────────────────────┘
```

### 触发器执行流程

```
用户执行 /zcf:task-review "Task 001 完成"
    ↓
OpenClaw 执行评审命令
    ↓
评审输出包含"评审通过"
    ↓
触发器匹配条件（pattern: "/zcf:task-review.*评审通过"）
    ↓
执行动作：skill_use acf-flow --next
    ↓
acf-flow 读取任务计划
    ↓
返回下一个任务详情
```

---

## ⚠️ 风险与缓解

### 风险 1: 触发器误触发

**风险**: 触发条件过于宽松，导致误触发

**缓解**:
- 使用精确的正则表达式
- 添加触发器日志，便于排查
- 支持禁用/启用触发器

---

### 风险 2: Skill 执行失败

**风险**: 脚本执行失败，影响工作流

**缓解**:
- 所有脚本添加错误处理
- 支持 dry-run 模式预览
- 失败时返回明确错误信息

---

### 风险 3: 触发器循环触发

**风险**: 触发器 A 触发 Skill，Skill 又触发触发器 B，形成循环

**缓解**:
- 触发器配置中明确依赖关系
- 添加触发器执行次数限制
- 日志中记录触发链

---

## 📝 Review 检查清单

### 架构设计

- [ ] Skill 封装模式是否合理？
- [ ] 触发器配置是否清晰？
- [ ] 脚本位置是否集中？

### 功能完整性

- [ ] 4 个核心 Skills 是否满足需求？
- [ ] 触发器是否覆盖主要场景？
- [ ] 文档是否完整？

### 可维护性

- [ ] 脚本是否易于修改？
- [ ] Skill 是否易于扩展？
- [ ] 触发器是否易于配置？

### 测试建议

```bash
# 测试 acf-status
skill_use acf-status mode=brief

# 测试 acf-sync（dry-run）
skill_use acf-sync dry_run=true

# 测试 acf-flow
skill_use acf-flow

# 测试 acf-fix
skill_use acf-fix action=create summary="测试问题" priority=P2
```

---

## 🎯 下一步行动

### 待 Review 确认

- [ ] P0 改进项是否满足需求？
- [ ] Skill 封装模式是否合理？
- [ ] 触发器配置是否需要调整？

### Review 通过后执行

- [ ] P1 改进项（架构成熟度评估等）
- [ ] P2 改进项（监控仪表板等）
- [ ] 多项目验证

---

## 📁 相关文件

| 文件 | 用途 |
|------|------|
| `acf-improvement-plan.md` | 改进计划（本文档） |
| `acf-skills-guide.md` | Skills 使用指南 |
| `acf-triggers.yaml` | 触发器配置 |
| `skills/acf-*/SKILL.md` | 各 Skill 详细文档 |

---

**创建人**: DevMate  
**创建时间**: 2026-03-29 13:10  
**状态**: 待 Review  
**下次更新**: Review 通过后更新 P1/P2 执行计划
