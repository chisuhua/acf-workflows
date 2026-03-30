# ACF 双循环工作流 v3.0（权威版）

**创建时间**: 2026-03-29  
**版本**: v3.0（角色与命令澄清版）  
**状态**: 生效中  
**归档**: v1.0 → `archive/acf-workflow-v1.md`, v2.0 → `archive/acf-workflow-v2.md`

---

## 1. 核心概念

### 1.1 双循环交织架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    架构循环（慢循环，三方协作）                   │
│  参与者：老板 + DevMate + 编码架构师 (OpenCode/Claude Code)       │
│  频率：按需触发 | 产出：架构决策、标准化架构文档                  │
│                                                                 │
│  1. 老板 + DevMate 讨论初步架构                                 │
│     → 输出：/workspace/mynotes/<Project>/docs/architecture/     │
│                                                                 │
│  2. DevMate → 编码架构师发送命令                                │
│     OpenCode:   /zcf/arch-doc "电商分析系统"                    │
│     ClaudeCode: /zcf:arch-doc "电商分析系统"                    │
│                                                                 │
│  3. 编码架构师执行 /zcf/arch-doc 工作流                         │
│     → 输出：/workspace/<Project>/docs/architecture/             │
│                                                                 │
│  4. DevMate 对比评审（mynotes vs 编码仓库）                      │
│     ├─ 一致 → 架构定稿，进入编码循环                            │
│     └─ 不一致 → 返回步骤 1，调整架构                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓ 架构定稿
┌─────────────────────────────────────────────────────────────────┐
│                    编码循环（快循环，双方协作）                   │
│  参与者：DevMate + 编码架构师 (OpenCode/Claude Code)             │
│  频率：每日执行 | 产出：可运行代码、测试、Git 提交                 │
│                                                                 │
│  1. DevMate → 编码架构师发送任务                                │
│     task(prompt="Task 001: 创建 Crawler 基类")                  │
│                                                                 │
│  2. 编码架构师实现代码                                          │
│     → 输出：/workspace/<Project>/src/...                        │
│                                                                 │
│  3. DevMate → 编码架构师发送评审命令                            │
│     OpenCode:   /zcf/task-review "Task 001 完成"                │
│     ClaudeCode: /zcf:task-review "Task 001 完成"                │
│                                                                 │
│  4. 编码架构师执行自评 → 输出评审报告                           │
│                                                                 │
│  5. DevMate 使用 acf-flow 获取下一个任务                         │
│     ├─ 无问题 → 继续 Task 002                                   │
│     └─ 发现问题 → 返回架构循环，和老板沟通                      │
└─────────────────────────────────────────────────────────────────┘
```

---

### 1.2 双仓库隔离与权限

| 仓库 | 路径 | 定位 | 写入权限 | 读取权限 |
|------|------|------|---------|---------|
| **提案仓库** | `/workspace/mynotes/<Project>/docs/architecture/` | 架构讨论、手工草稿、ADR | **仅 DevMate** | DevMate + 老板 |
| **编码仓库** | `/workspace/<Project>/docs/architecture/` | 标准化文档、任务执行 | DevMate + 编码架构师 | 所有人 |

**关键规则**:
- ✅ **提案仓库仅 DevMate 可写** — 用于和老板讨论架构，编码架构师不可写
- ✅ **编码仓库 DevMate + 编码架构师可写** — 编码架构师的输出只能到这里
- ✅ **编码架构师（OpenCode/Claude Code）只能写编码仓库** — 不能写提案仓库

---

### 1.3 角色与命令对应关系

| 角色 | 身份 | 使用的命令/技能 | 命令格式 |
|------|------|----------------|---------|
| **DevMate** | 你（技术合伙人） | `acf-flow`, `acf-status`, `acf-fix`, `acf-sync` | OpenClaw Skills |
| **OpenCode** | 编码架构师 | `/zcf/arch-doc`, `/zcf/task-review`, `/zcf/status` | **斜杠** `/zcf/` |
| **Claude Code** | 编码架构师 | `/zcf:arch-doc`, `/zcf:task-review`, `/zcf:status` | **冒号** `/zcf:` |

**命令格式差异原因**:
- OpenCode: 使用 `/command/arg` 格式（斜杠）
- Claude Code: 使用 `/command:arg` 格式（冒号）

**重要**: `/zcf/` 技能是**编码架构师使用的**，不是 DevMate 直接使用的。DevMate 使用 `acf-*` Skills 来驱动工作流程。

---

## 2. Agent 角色与职责

### 2.1 角色矩阵（澄清版）

| 角色 | 职责 | 工作目录 | 使用的命令/技能 | 输出路径 |
|------|------|---------|----------------|---------|
| **DevMate** | 架构讨论、流程驱动、问题发现 | 双仓库 | `acf-flow`, `acf-status`, `acf-fix`, `acf-sync` | 提案仓库 + 编码仓库 |
| **编码架构师** (OpenCode/Claude Code) | 标准化架构文档生成、任务执行、自评 | 编码仓库 | `/zcf/arch-doc`, `/zcf/task-review`, `/zcf/status` | 仅编码仓库 |
| **老板** | 架构决策确认、技术选型审批 | 提案仓库（只读） | 无（人工评审） | - |

### 2.2 编码架构师的 /zcf/ 技能列表

| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 |
|------|------|--------------|-----------------|
| `arch-doc` | 架构文档生成（3 阶段：研究→构思→评审） | `/zcf/arch-doc "主题"` | `/zcf:arch-doc "主题"` |
| `task-review` | 任务评审（架构一致性检查、偏差识别） | `/zcf/task-review "Task XXX"` | `/zcf:task-review "Task XXX"` |
| `status` | 状态分析（完整/简要/仅下一步） | `/zcf/status [mode]` | `/zcf:status [mode]` |
| `github-sync` | GitHub 同步（Milestones + Issues） | `/zcf/github-sync "Phase 1"` | `/zcf:github-sync "Phase 1"` |

**技能定义位置**: `~/.agents/commands/zcf/*.md`

---

### 2.3 DevMate 的 acf-workflow Skills

| Skill | 用途 | 调用方式 | 触发条件 |
|-------|------|---------|---------|
| `acf-status` | 项目状态分析，生成进度报告 | `skill_use acf-status [mode]` | 每日 9:00 自动 / 手动 |
| `acf-flow` | 任务自动流转（读取计划 → 下一个任务） | `skill_use acf-flow [--next]` | Task 评审通过后 |
| `acf-fix` | 修复任务创建（P0/P1 问题） | `skill_use acf-fix action=create` | 评审发现问题时 |
| `acf-sync` | 同步提案仓库 → 编码仓库 | `skill_use acf-sync [--dry-run]` | 架构定稿后 |

**Skill 定义位置**: `/workspace/acf-workflow/skills/*/SKILL.md`

---

### 2.4 偏差处理矩阵

| 偏差类型 | 级别 | 自动处理 | 人工确认 | 行动 |
|----------|------|---------|---------|------|
| 接口参数新增 | ⚠️ 轻微 | 记录 CHANGELOG | 否 | 继续 Task，文档后续更新 |
| 技术选型补充 | ⚠️ 中等 | 更新文档 | 否 | 先更新文档，再继续 |
| 架构违规 | ❌ 严重 | 暂停任务 | ✅ 必须 | **返回架构循环**，和老板沟通 |
| 依赖方向错误 | ❌ 严重 | 暂停任务 | ✅ 必须 | **返回架构循环**，和老板沟通 |
| 需求重大变更 | ❌ 严重 | 暂停任务 | ✅ 必须 | **返回架构循环**，和老板沟通 |

---

## 3. 工作流程

### 3.1 架构循环流程（三方协作）

```bash
# 1. 老板 + DevMate 讨论初步架构
#    输出：/workspace/mynotes/<Project>/docs/architecture/YYYY-MM-DD-draft.md

# 2. DevMate → OpenCode 发送命令（斜杠格式）
/zcf/arch-doc "电商分析系统"

#    或 DevMate → Claude Code 发送命令（冒号格式）
/zcf:arch-doc "电商分析系统"

# 3. 编码架构师执行 /zcf/arch-doc 工作流
#    - 阶段 1：研究（读取现有文档、技术栈识别）
#    - 阶段 2：构思（生成 2-3 种架构方案）
#    - 阶段 3：评审（完整性检查、一致性验证）
#    输出：/workspace/<Project>/docs/architecture/YYYY-MM-DD-xxx.md

# 4. DevMate 对比评审（mynotes 手工 vs 编码仓库标准化）
#    - 一致 → 架构定稿，进入编码循环
#    - 不一致 → 返回步骤 1，调整架构

# 5. 架构定稿后，DevMate 使用 acf-sync 同步
skill_use acf-sync
```

---

### 3.2 编码循环流程（双方协作）

```bash
# 1. 架构文档已定稿（编码仓库）

# 2. DevMate → 编码架构师发送任务
task(prompt="Task 001: 创建 Crawler 基类")

# 3. 编码架构师实现代码
#    输出：/workspace/<Project>/src/crawler/base.py

# 4. DevMate → 编码架构师发送评审命令
#    OpenCode:
/zcf/task-review "Task 001 完成"
#    或 Claude Code:
/zcf:task-review "Task 001 完成"

# 5. 编码架构师执行自评
#    - 任务执行结果验证
#    - 架构一致性检查
#    - 文档偏差识别
#    - 下一步决策
#    输出：评审报告

# 6. DevMate 使用 acf-flow 获取下一个任务
skill_use acf-flow --next

# 7. DevMate 发现问题？
#    - 否 → 继续 Task 002
#    - 是 → 返回架构循环，和老板沟通
```

---

### 3.2.1 任务流转规则（自动执行，无需人工确认）

**前提**: `plans/implementation-plan.md` 已定义任务依赖顺序

#### 规则 1: 顺序执行（默认）
```
Task N 评审通过 → 读取实施计划 → 执行 Task N+1
```

#### 规则 2: 并行执行（独立任务）
```
前提：多个任务无依赖关系
流转：同时 spawn 多个执行者 Agent
```

#### 规则 3: 阻塞等待（有依赖）
```
前提：Task N+1 依赖 Task N 的输出
流转：Task N 完成 → 标记 Task N+1 为"就绪" → 等待协调员调度
```

#### 规则 4: 修复优先（P0 问题）
```
前提：评审发现 P0 级别问题（阻塞后续任务）
流转：暂停后续任务 → 创建修复任务 → 执行修复 → 恢复原计划
```

#### 自动流转决策树
```
Task N 评审通过？
├─ 是 → 检查实施计划
│      ├─ 有下一个任务 → 自动执行 Task N+1
│      └─ 无下一个任务 → 阶段完成，触发阶段评审
│
├─ 轻微偏差 → 记录 CHANGELOG → 继续 Task N+1
│
└─ 严重偏差 → 暂停 → 通知架构师 → 等待架构调整
```

---

### 3.2.2 修复任务管理

#### 修复任务创建
- 评审报告中的 P0/P1 问题 → 自动创建修复任务
- 任务命名：`Fix-XXX: [问题摘要]`
- 优先级：P0 > P1 > P2

#### 修复任务执行
- **P0 问题**: 阻塞后续任务，立即执行
- **P1 问题**: 与正常任务交替执行（每 3 个正常任务后执行 1 个修复）
- **P2 问题**: 阶段结束时统一处理

#### 修复验证
- 修复完成后 → 重新运行相关测试
- 测试通过 → 关闭修复任务
- 测试失败 → 重新修复或升级问题级别

---

### 3.2.3 任务完成标准（DoD）

**Task 完成定义**（全部满足才算完成）:
- [ ] 代码实现完成
- [ ] 单元测试通过（覆盖率 ≥80%）
- [ ] 评审通过（无严重偏差）
- [ ] Git commit 完成
- [ ] 执行日志记录

**阶段完成定义**（全部满足才算完成）:
- [ ] 所有 Task 完成并通过评审
- [ ] 集成测试通过
- [ ] 阶段评审报告生成
- [ ] 技术债务汇总
- [ ] 下一阶段计划确认

---

### 3.3 同步流程（提案仓库 → 编码仓库）

**触发条件**: 架构定稿后（DevMate 对比评审一致）

```bash
# 手动同步（推荐）
skill_use acf-sync

# Dry-run 预览
skill_use acf-sync dry_run=true

# 查看同步列表
skill_use acf-sync list=true
```

**同步内容**:
- 提案仓库的定稿架构文档 → 编码仓库
- ADR 文档 → 编码仓库 `decisions/`
- 评审报告 → 编码仓库 `reviews/`

---

## 4. 文档结构

### 4.1 提案仓库结构（仅 DevMate 可写）

```
/workspace/mynotes/<Project>/docs/architecture/
├── YYYY-MM-DD-<topic>-draft.md    # DevMate 手工架构草稿
├── decisions/
│   └── ADR-XXX-<title>.md         # 架构决策记录（DevMate 创建）
├── reviews/
│   └── YYYY-MM-DD-<topic>-review.md  # DevMate 评审记录
├── plans/
│   └── implementation-plan.md     # 实施计划
└── archive/                       # 归档旧版本
```

---

### 4.2 编码仓库结构（DevMate + 编码架构师可写）

```
/workspace/<Project>/docs/architecture/
├── YYYY-MM-DD-<system-name>.md    # 标准化架构文档（编码架构师生成）
├── decisions/                     # 已采纳 ADR
├── reviews/                       # 任务评审记录（编码架构师自评）
├── plans/                         # 可执行计划
├── phases/
│   ├── phase-1-mvp/
│   │   ├── crawler/
│   │   │   ├── detailed-design.md
│   │   │   ├── api-spec.md
│   │   │   ├── database-schema.md
│   │   │   └── test-strategy.md
│   │   └── storage/
│   └── phase-2-features/
└── SYNC-REPORT.md                 # 同步报告（acf-sync 自动生成）
```

**编码架构师输出规则**:
- ✅ `/zcf/arch-doc` 输出到编码仓库
- ✅ `/zcf/task-review` 输出到编码仓库
- ❌ **编码架构师不能写提案仓库**

---

### 4.3 状态追踪结构

```
/workspace/<Project>/.acf/
├── status/
│   ├── YYYY-MM-DD-status.md     # 每日状态报告（acf-status 生成）
│   └── current-phase.md         # 当前阶段概览
├── temp/
│   ├── task-plans/              # 任务计划
│   └── arch-issues.md           # 架构问题记录
└── config/
    └── acf-triggers.yaml        # 触发器配置
```

### 4.3.1 状态更新规则

#### 自动更新触发
- **Task 开始** → 更新状态为"进行中"
- **Task 完成** → 更新进度百分比
- **评审完成** → 更新偏差统计
- **每日 9:00** → 生成每日状态报告（cron）

#### 更新内容
- 任务进度表（完成数/总数/百分比）
- 偏差追踪表（今日/累计）
- 效率指标（本周/累计）
- 阻塞点列表（如有）

---

## 5. DevMate 工作流程（acf-workflow）

### 5.1 acf-workflow Skills 定位

**acf-workflow 是 DevMate 的工作流程**，用于：
1. 标准化 DevMate 手工驱动 OpenCode/Claude Code 的操作
2. 在架构循环和编码循环之间切换
3. 发现问题时及时返回架构循环和老板沟通

### 5.2 核心 Skills

| Skill | 用途 | 典型场景 |
|-------|------|---------|
| `acf-status` | 分析项目状态，生成进度报告 | 新 session 开始、每日站会、阶段转换前 |
| `acf-flow` | 任务自动流转 | Task 评审通过后获取下一个任务 |
| `acf-fix` | 创建修复任务 | 评审发现 P0/P1 问题时 |
| `acf-sync` | 同步提案仓库 → 编码仓库 | 架构定稿后 |

### 5.3 DevMate 典型工作流

```
1. 新 session 开始
   ↓
   skill_use acf-status mode=brief
   ↓
2. 架构循环（如需要）
   ↓
   DevMate 手工创建架构草稿 (mynotes/)
   ↓
   DevMate → OpenCode: /zcf/arch-doc "xxx"
   ↓
   DevMate 对比评审 (mynotes vs 编码仓库)
   ↓
   一致 → skill_use acf-sync
   ↓
3. 编码循环
   ↓
   DevMate → OpenCode: task(prompt="Task 001: ...")
   ↓
   DevMate → OpenCode: /zcf/task-review "Task 001 完成"
   ↓
   skill_use acf-flow --next
   ↓
4. 发现问题？
   ↓
   是 → 返回架构循环，和老板沟通
   否 → 继续 Task 002
```

---

## 6. 命令参考

### 6.1 DevMate 命令（acf-workflow Skills）

```bash
# 查看项目状态
skill_use acf-status mode=brief      # 简要报告
skill_use acf-status mode=full       # 完整报告
skill_use acf-status mode=next       # 仅下一步

# 获取下一个任务
skill_use acf-flow --next

# 创建修复任务
skill_use acf-fix action=create summary="问题描述" priority=P0

# 同步架构文档
skill_use acf-sync
skill_use acf-sync dry_run=true      # 预览
skill_use acf-sync list=true         # 查看同步列表
```

### 6.2 编码架构师命令（/zcf/ 技能）

**OpenCode 格式（斜杠）**:
```bash
/zcf/arch-doc "电商分析系统"
/zcf/arch-doc "阶段 1：爬虫模块详细设计"
/zcf/task-review "Task 001 完成"
/zcf/status
/zcf/status brief
/zcf/github-sync "Phase 1: MVP"
```

**Claude Code 格式（冒号）**:
```bash
/zcf:arch-doc "电商分析系统"
/zcf:arch-doc "阶段 1：爬虫模块详细设计"
/zcf:task-review "Task 001 完成"
/zcf:status
/zcf:status brief
/zcf:github-sync "Phase 1: MVP"
```

---

## 7. 快速启动

### 7.1 新项目初始化

```bash
# 1. 创建项目目录
PROJECT_NAME="my-project"
mkdir -p /workspace/$PROJECT_NAME/{.acf/{status,temp,config},src,tests,docs/architecture}
mkdir -p /workspace/mynotes/$PROJECT_NAME/docs/architecture/{decisions,reviews,plans}

# 2. 创建项目 AGENTS.md
cat > /workspace/$PROJECT_NAME/AGENTS.md << 'EOF'
# $PROJECT_NAME - ACF 工作流项目

**架构文档位置**: `docs/architecture/`
**ACF 运行时目录**: `.acf/`

## 角色与命令

### DevMate（我）
- `skill_use acf-status` - 查看项目状态
- `skill_use acf-flow` - 获取下一个任务
- `skill_use acf-fix` - 创建修复任务
- `skill_use acf-sync` - 同步架构文档

### 编码架构师（OpenCode/Claude Code）
- OpenCode:   /zcf/arch-doc, /zcf/task-review, /zcf/status
- ClaudeCode: /zcf:arch-doc, /zcf:task-review, /zcf:status

## 仓库权限
- 提案仓库 (mynotes/): 仅 DevMate 可写
- 编码仓库 (当前目录): DevMate + 编码架构师可写
EOF
```

### 7.2 每日工作流

```bash
# 早上：查看状态
skill_use acf-status mode=brief

# 开始编码前：确认架构文档最新
skill_use acf-sync list=true

# 任务完成：评审
# DevMate → OpenCode: /zcf/task-review "Task XXX 完成"

# 获取下一个任务
skill_use acf-flow --next

# 晚上：记录日志
# 自动写入 memory/YYYY-MM-DD.md
```

---

## 8. 切换到慢循环（架构循环）的条件

满足以下**任一条件**即切换到慢循环：

| 条件 | 严重性 | 行动 |
|------|--------|------|
| ❌ 架构缺陷（严重） | 严重 | 暂停编码，返回架构循环 |
| ❌ 技术选型变更 | 严重 | 暂停编码，返回架构循环 |
| ❌ 需求重大变更（>30%） | 严重 | 暂停编码，返回架构循环 |
| ❌ 新增模块 | 中等 | 评估后决定是否返回架构循环 |
| ❌ 老板决策 | 严重 | 立即返回架构循环 |
| ❌ 架构违规（评审发现） | 严重 | 暂停任务，返回架构循环 |
| ❌ 依赖方向错误（评审发现） | 严重 | 暂停任务，返回架构循环 |

---

## 9. 效率指标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 架构讨论干扰 | < 5 分钟/天 | 手动记录 |
| 编程助手理解准确率 | > 90% | 评审偏差统计 |
| 同步执行时间 | < 30 秒 | acf-sync 计时 |
| 偏差检测自动化率 | > 80% | 自动/手动比例 |
| 综合效率提升 | > 2x | 对比单仓库手动管理 |

---

## 10. 变更日志

| 日期 | 版本 | 变更 | 理由 |
|------|------|------|------|
| 2026-03-30 | v3.0 | 角色与命令澄清 | 明确 DevMate vs 编码架构师、命令格式差异、仓库权限 |
| 2026-03-29 | v2.1 | 添加任务流转规则 | Task 001 评审后发现设计遗漏，需自动流转 |
| 2026-03-29 | v2.1 | 添加修复任务管理 | 评审发现的问题需跟踪管理 |
| 2026-03-29 | v2.1 | 添加任务完成标准 | 明确 DoD，避免模糊完成 |
| 2026-03-29 | v2.0 | 创建权威版 | 合并 v1.0 + v2.0 草案，消除混乱 |

---

## 附录 A: 命令格式差异说明

**OpenCode** 使用斜杠格式：
```bash
/zcf/arch-doc "主题"
/zcf/task-review "Task 001"
```

**Claude Code** 使用冒号格式：
```bash
/zcf:arch-doc "主题"
/zcf:task-review "Task 001"
```

**原因**: 不同编码助手的 Commands 机制不同
- OpenCode: `/command/arg` 格式
- Claude Code: `/command:arg` 格式

**DevMate 不需要记住**：根据你使用的编码架构师自动选择格式即可。

---

## 附录 B: 相关文件

| 文件 | 用途 |
|------|------|
| `~/.agents/commands/zcf/*.md` | 编码架构师使用的 /zcf/ 技能定义 |
| `/workspace/acf-workflow/skills/*/SKILL.md` | DevMate 使用的 acf-workflow Skills |
| `acf-skills-guide.md` | acf-workflow Skills 使用指南 |
| `acf-quickstart.md` | 新项目快速启动指南 |
| `acf-cheatsheet.md` | 快速参考卡 |

---

**版本**: v3.0  
**状态**: 生效中  
**下次评审**: 2026-04-05  
**维护人**: DevMate
