# ZCF 双循环工作流 — 完整文件地图与协作关系

**整理时间**: 2026-03-29  
**工作流版本**: v2.1  
**适用项目**: 所有采用 ZCF 工作流的项目

---

## 📁 完整文件地图

### 1. OpenClaw 工作流文档（~/.openclaw/workspace/docs/workflow/）

```
~/.openclaw/workspace/docs/workflow/
├── acf-workflow.md                    # 权威版工作流文档（v2.1，生效中）
├── acf-workflow-summary.md            # 成果总结与改进计划（2026-03-29）
├── acf-workflow-arch-review.md        # 架构评审报告（识别 4 个遗漏）
├── acf-cheatsheet.md                  # 快速参考卡（单页命令速查）
├── execution-log-template.md          # 执行日志模板
│
├── archive/
│   ├── acf-workflow-v1.md             # 归档 v1.0（历史参考）
│   └── acf-workflow-v2-draft.md       # 归档 v2.0 草案（历史参考）
│
├── skills/                            # Agent Skills 骨架（阶段 2 交付物）
│   ├── acf-architect/SKILL.md         # 架构师 Skill
│   ├── acf-reviewer/SKILL.md          # 评审员 Skill
│   ├── acf-coordinator/SKILL.md       # 协调员 Skill
│   └── acf-executor/SKILL.md          # 执行者 Skill
│
└── status/                            # 状态追踪（阶段 3 交付物）
    └── (由项目维护，如 ecommerce/status/)
```

**用途**: ZCF 工作流的**元文档**，定义工作流本身的规则和流程

---

### 2. OpenCode 命令（~/.agents/commands/zcf/ 或 ~/.claude/commands/zcf/）

```
~/.agents/commands/zcf/
├── guide.md                           # 工作流使用指南
├── status.md                          # /zcf:status 命令（项目状态分析）
├── arch-doc.md                        # /zcf:arch-doc 命令（架构文档开发）
├── task-review.md                     # /zcf:task-review 命令（任务评审）
├── github-sync.md                     # /zcf:github-sync 命令（GitHub 同步）
├── feat.md                            # /zcf:feat 命令（功能开发）
├── init-project.md                    # /zcf:init-project 命令（项目初始化）
│
├── git-*.md                           # Git 相关命令
│   ├── git-cleanBranches.md
│   ├── git-commit.md
│   ├── git-rollback.md
│   └── git-worktree.md
│
├── bmad-init.md                       # BMAD 方法初始化
│
├── docs/                              # 命令文档
│   ├── STATUS-COMMAND-GUIDE.md
│   ├── QUICK_REFERENCE.md
│   ├── WORKFLOW_GUIDE.md
│   └── CROSS-PROJECT-GUIDE.md
│
└── templates/                         # 命令模板
    └── (...)
```

**用途**: OpenCode/Claude Code 的**可执行命令**，通过 `/zcf:*` 调用

---

### 3. Agent Skills（~/.agents/skills/）

```
~/.agents/skills/
├── acf-architect/                     # 架构师 Skill（骨架）
│   ├── SKILL.md
│   └── scripts/
│
├── acf-reviewer/                      # 评审员 Skill（骨架）
│   ├── SKILL.md
│   └── scripts/
│
├── acf-coordinator/                   # 协调员 Skill（骨架）
│   ├── SKILL.md
│   └── scripts/
│
└── acf-executor/                      # 执行者 Skill（骨架）
    ├── SKILL.md
    └── scripts/
```

**用途**: 可通过 `skill_use acf-*` 调用的**技能封装**

---

### 4. 项目级文件（以 ecommerce 为例）

```
/workspace/ecommerce/
├── AGENTS.md                          # 编码助手指南（双仓库规则）
├── docs/architecture/                 # 编码仓库架构文档（只读，从 mynotes 同步）
│   ├── 2026-03-26-ecommerce-analysis-system.md
│   ├── ERROR-HANDLING-STRATEGY.md
│   ├── TESTING-STRATEGY.md
│   ├── decisions/
│   │   └── ADR-*.md
│   ├── reviews/
│   │   └── 2026-03-29-task-001-review.md
│   ├── plans/
│   │   └── implementation-plan.md
│   └── SYNC-REPORT.md                 # 同步报告（自动生成）
│
├── status/                            # 状态追踪
│   ├── current-phase.md               # 当前阶段概览
│   └── metrics-dashboard.md           # 监控仪表板
│
├── temp/                              # 临时文件
│   ├── arch-issues.md                 # 架构问题记录
│   ├── phase1-tasks.md                # 阶段 1 任务分解
│   ├── phase2-tasks.md                # 阶段 2 任务分解
│   └── phase3-tasks.md                # 阶段 3 任务分解
│
├── src/                               # 源代码
├── tests/                             # 测试代码
└── scripts/                           # 工具脚本
```

**用途**: 具体项目的**编码仓库**，存储可执行代码和定稿文档

---

### 5. 提案仓库（/workspace/mynotes/SkillApps/ecommerce/docs/architecture/）

```
/workspace/mynotes/SkillApps/ecommerce/docs/architecture/
├── YYYY-MM-DD-<topic>-draft.md        # 架构草稿
├── decisions/
│   └── ADR-XXX-<title>.md             # 架构决策记录
├── reviews/
│   └── YYYY-MM-DD-<topic>-review.md   # 评审记录
├── plans/
│   └── implementation-plan.md         # 实施计划
└── archive/                           # 归档旧版本
```

**用途**: 架构讨论的**提案仓库**，DevMate + 老板在此进行架构决策

---

## 🔄 快慢循环转换节点与条件

### 双循环架构回顾

```
┌─────────────────────────────────────────────────────────────┐
│                    架构循环（慢循环）                        │
│  频率：按需触发 | 参与者：DevMate + 老板 | 产出：架构决策    │
│                                                             │
│  需求 → 研究 → 构思 (2-3 方案) → 评审 → 定稿                 │
└─────────────────────────────────────────────────────────────┘
                            ↓ 同步（ADR 定稿后）
                            │ 【转换节点 1】
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    编码循环（快循环）                        │
│  频率：每日 | 参与者：OpenCode/Claude Code | 产出：代码     │
│                                                             │
│  任务 → 实现 → 测试 → 自动评审 → 偏差检测 → 继续/暂停       │
│                                        │                    │
│                                        │ 【转换节点 2】     │
│                                        └──────────┐         │
│                                                   ▼         │
│                                    严重偏差 → 暂停 → 通知    │
│                                                   │         │
│                                                   ▼         │
│                                    返回架构循环重新设计      │
└─────────────────────────────────────────────────────────────┘
```

---

### 转换节点 1: 架构循环 → 编码循环

**触发条件**:
| 条件 | 检查项 | 验证方式 |
|------|--------|---------|
| ✅ 架构文档评审通过 | 评审报告无严重偏差 | `/zcf:task-review "架构评审"` |
| ✅ 标记"可同步" | 文档头部状态字段 | 检查 `状态：已发布` |
| ✅ 老板确认 | 明确确认同步 | 用户输入"同步"或"确认" |

**执行动作**:
```bash
# 协调员执行同步
/zcf:sync-to-encoding

# 或手动执行
bash ~/.openclaw/workspace/scripts/sync-arch-to-encoding.sh
```

**同步后**:
- 编码仓库读取定稿文档
- 开始任务执行（编码循环）
- 架构仓库进入等待状态（除非有架构调整）

---

### 转换节点 2: 编码循环 → 架构循环

**触发条件**:
| 条件 | 偏差级别 | 示例 |
|------|---------|------|
| 🔴 严重偏差 | 架构违规 | 依赖方向错误、接口契约违反 |
| 🔴 严重偏差 | 技术选型变更 | 需要更换核心技术栈 |
| 🔴 严重偏差 | 需求重大变更 | 业务范围扩大/缩小 >50% |

**发现方式**:
```bash
# 任务评审时发现
/zcf:task-review "Task XXX 完成"

# 评审报告中标记
## ❌ 严重偏差
- 依赖方向错误：src/crawler 依赖 src/presentation（违反分层架构）
```

**执行动作**:
```
1. 暂停编码循环
2. 通知 DevMate + 老板
3. 写入 temp/arch-issues.md
4. DevMate 评估后返回架构循环
5. 架构调整后重新同步
6. 恢复编码循环
```

---

### 转换节点 3: 阶段完成 → 下一阶段架构评审

**触发条件**:
| 条件 | 检查项 |
|------|--------|
| ✅ 所有 Task 完成 | 实施计划中 100% 打勾 |
| ✅ 阶段评审通过 | `/zcf:task-review "阶段 X 完成"` |
| ✅ 技术债务汇总 | 阶段报告包含债务清单 |

**执行动作**:
```bash
# 生成阶段完成报告
# 自动触发下一阶段架构评审（如需要）

# 如果下一阶段架构已明确 → 继续编码循环
# 如果下一阶段架构需调整 → 进入架构循环
```

---

## 🤖 与 OpenCode 命令的协作关系

### 命令分类

| 命令 | 所属循环 | 用途 | 调用时机 |
|------|---------|------|---------|
| `/zcf:arch-doc` | 架构循环 | 架构文档开发 | 架构讨论阶段 |
| `/zcf:status` | 双循环通用 | 项目状态分析 | 每日晨会/编码前 |
| `/zcf:task-review` | 编码循环 | 任务完成评审 | Task/Module/Phase 完成后 |
| `/zcf:github-sync` | 编码循环 | GitHub 同步 | 任务创建/完成后 |
| `/zcf:guide` | 双循环通用 | 工作流指南 | 需要帮助时 |
| `/zcf:feat` | 编码循环 | 功能开发 | 具体功能实现 |

---

### 完整协作流程

```
┌─────────────────────────────────────────────────────────────┐
│ 阶段 0: 项目初始化                                           │
│                                                             │
│ /zcf:init-project → 创建项目骨架                            │
│ /zcf:arch-doc "总体架构" → 创建主架构文档                   │
│                                                             │
│ 【转换节点 1】架构评审通过 → 同步到编码仓库                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 阶段 1: 架构设计（慢循环）                                   │
│                                                             │
│ /zcf:arch-doc "错误处理策略" → ERROR-HANDLING-STRATEGY.md  │
│ /zcf:arch-doc "测试策略" → TESTING-STRATEGY.md             │
│ /zcf:arch-doc "阶段实施计划" → implementation-plan.md      │
│ /zcf:arch-doc "模块详细设计" → detailed-design.md          │
│                                                             │
│ /zcf:task-review "架构评审" → 评审报告                      │
│                                                             │
│ 【转换节点 1】评审通过 → 同步到编码仓库                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 阶段 2: 任务执行（快循环）                                   │
│                                                             │
│ /zcf:status → 确认架构文档最新                              │
│ skill_use writing-plans → 生成任务计划                      │
│ /zcf:github-sync "Phase 1" → 创建 Issues                    │
│                                                             │
│ ┌─ 循环开始 ──────────────────────────────────┐            │
│ │ task(prompt="Task 001: ...") → 执行任务     │            │
│ │ /zcf:task-review "Task 001 完成" → 评审     │            │
│ │   ├─ 无偏差 → 继续 Task 002                  │            │
│ │   ├─ 轻微偏差 → 记录 CHANGELOG → 继续       │            │
│ │   └─ 严重偏差 → 【转换节点 2】→ 架构循环    │            │
│ └─ 循环结束 ──────────────────────────────────┘            │
│                                                             │
│ 【转换节点 3】阶段完成 → 阶段评审                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 阶段 3: 阶段评审与下一阶段                                   │
│                                                             │
│ /zcf:task-review "阶段 1 完成" → 阶段评审报告               │
│ /zcf:status full → 生成进度报告                             │
│                                                             │
│ 如果下一阶段架构明确 → 返回 阶段 2（继续编码）              │
│ 如果下一阶段架构需调整 → 返回 阶段 1（架构设计）            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 命令调用权限矩阵

| 角色 | `/zcf:arch-doc` | `/zcf:status` | `/zcf:task-review` | `/zcf:github-sync` |
|------|----------------|---------------|-------------------|-------------------|
| DevMate | ✅ | ✅ | ✅ | ✅ |
| OpenCode | ❌（去 mynotes） | ✅（只读） | ✅ | ✅ |
| Claude Code | ❌（去 mynotes） | ✅（只读） | ✅ | ✅ |
| 老板 | ✅ | ✅ | ✅ | ❌（需确认） |

**说明**:
- OpenCode/Claude Code 禁止调用 `/zcf:arch-doc`，架构讨论必须去 mynotes（提案仓库）
- 编码仓库的架构文档是**只读**的，由同步脚本更新

---

## 🎯 关键设计原则

### 1. 双仓库隔离

```
提案仓库（mynotes/）          编码仓库（ecommerce/）
├─ 架构草稿                   ├─ 定稿文档（只读）
├─ 评审中 ADR                 ├─ 已采纳 ADR
├─ 评审记录                   ├─ 任务评审记录
└─ 实施计划                   └─ 可执行计划
        ↓ 同步（/zcf:sync-to-encoding）
```

**原则**: 架构讨论不污染编码环境，编码助手仅读取定稿文档

---

### 2. 自动流转

```
Task N 评审通过？
├─ 是 → 读取 implementation-plan.md → 执行 Task N+1 ✅
├─ 轻微偏差 → 记录 CHANGELOG → 继续 Task N+1 ✅
└─ 严重偏差 → 暂停 → 通知 DevMate → 架构循环 🔴
```

**原则**: 编码循环无需人工决策，仅架构调整时请求老板确认

---

### 3. 修复优先

```
评审发现 P0 问题 → 创建 Fix-XXX 任务 → 阻塞后续任务 → 优先修复
```

**原则**: 严重问题不带到后续阶段

---

### 4. 状态自动追踪

```
Task 开始 → 更新状态为"进行中"
Task 完成 → 更新进度百分比
评审完成 → 更新偏差统计
每日 9:00 → 生成每日状态报告（cron）
```

**原则**: 状态仪表盘实时更新，无需手动维护

---

## 🔗 文件位置速查

| 用途 | 路径 |
|------|------|
| **工作流元文档** | `~/.openclaw/workspace/docs/workflow/` |
| **OpenCode 命令** | `~/.agents/commands/zcf/` 或 `~/.claude/commands/zcf/` |
| **Agent Skills** | `~/.agents/skills/acf-*/` |
| **提案仓库** | `/workspace/mynotes/SkillApps/<project>/docs/architecture/` |
| **编码仓库** | `/workspace/<project>/docs/architecture/` |
| **状态追踪** | `/workspace/<project>/status/` |
| **同步脚本** | `~/.openclaw/workspace/scripts/sync-arch-to-encoding.sh` |

---

**维护人**: DevMate  
**最后更新**: 2026-03-29 11:20  
**下次评审**: 2026-04-05（一周后）
