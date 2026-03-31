# ACF 双循环工作流 v3.1（ACP 驱动版）

**创建时间**: 2026-03-29  
**版本**: v3.1（ACP 驱动 OpenCode 实现）  
**状态**: 生效中  
**归档**: v1.0 → `archive/acf-workflow-v1.md`, v2.0 → `archive/acf-workflow-v2.md`, v3.0 → `archive/acf-workflow-v3.0.md`

---

## 1. 核心概念

### 1.1 双循环交织架构（角色澄清版）

```
┌─────────────────────────────────────────────────────────────────┐
│                    架构循环（慢循环，三方协作）                   │
│  参与者：老板 + DevMate + 架构师 (OpenCode/Claude Code 运行 arch-doc) │
│  频率：按需触发 | 产出：架构决策、标准化架构文档                  │
│                                                                 │
│  1. 老板 + DevMate 讨论初步架构                                 │
│     → 输出：/workspace/mynotes/<Project>/docs/architecture/     │
│                                                                 │
│  2. DevMate → 架构师发送命令（通过 ACP session）                 │
│     OpenCode:   /zcf/arch-doc "电商分析系统"                    │
│     ClaudeCode: /zcf:arch-doc "电商分析系统"                    │
│                                                                 │
│  3. 架构师执行 /zcf/arch-doc 工作流                             │
│     → 输出：/workspace/<Project>/docs/architecture/             │
│                                                                 │
│  4. DevMate 对比评审（mynotes 提案 vs 编码仓库标准化）            │
│     ├─ 一致 → 架构定稿，进入编码循环                            │
│     └─ 不一致 → 返回步骤 1，调整架构                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓ 架构定稿
┌─────────────────────────────────────────────────────────────────┐
│                    编码循环（快循环，双方协作）                   │
│  参与者：DevMate + 编码助手 (OpenCode/Claude Code 运行 workflow) │
│  频率：每日执行 | 产出：可运行代码、测试、Git 提交                 │
│                                                                 │
│  1. DevMate → 编码助手发送任务（acf-executor 启动 ACP session）   │
│     skill_use acf-executor task="Task 001: ..."                │
│                                                                 │
│  2. 编码助手自主实现代码（OpenCode 自行决定如何执行）             │
│     → 输出：/workspace/<Project>/src/...                        │
│                                                                 │
│  3. DevMate → 评审员发送评审命令（通过 ACP session 输入）         │
│     OpenCode:   /zcf/task-review "Task 001 完成"                │
│     ClaudeCode: /zcf:task-review "Task 001 完成"                │
│                                                                 │
│  4. 评审员执行评审 → 输出报告（给 DevMate 看）                    │
│                                                                 │
│  5. DevMate 查看报告 → acf-flow → 下一任务                       │
│     ├─ 无问题 → 继续 Task 002                                   │
│     └─ 发现问题 → 返回架构循环，和老板沟通                      │
└─────────────────────────────────────────────────────────────────┘
```

**关键实现**: 
- 编码循环使用 **ACP 驱动 OpenCode**（`sessions_spawn(runtime="acp", agentId="opencode")`）
- **角色说明**: OpenCode/Claude Code 根据接收的命令扮演不同角色
  - `/zcf/arch-doc` → **架构师** (Architect)
  - `/zcf/workflow` 或自主执行 → **编码助手** (Encoding Assistant)
  - `/zcf/task-review` → **评审员** (Reviewer)
  - `/zcf/status` → **分析师** (Analyst)

**DevMate 角色**: **终端操作员**（通过 ACP session 输入 /zcf/ 命令，唤醒对应角色）

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

### 1.3 角色与命令对应关系（统一术语）

| 角色 | 身份 | 使用的命令/技能 | 命令格式 | 触发方式 |
|------|------|----------------|---------|
| **DevMate** | 你（技术合伙人/终端操作员） | `acf-flow`, `acf-status`, `acf-fix`, `acf-sync`, `acf-executor` | OpenClaw Skills | 直接调用 |
| **架构师** | OpenCode/Claude Code (运行 arch-doc) | `/zcf/arch-doc` | **斜杠** `/zcf/` (OpenCode)<br>**冒号** `/zcf:` (Claude Code) | DevMate 通过 ACP session 输入 |
| **编码助手** | OpenCode/Claude Code (自主执行任务) | `/zcf/workflow` (可选) | 同上 | OpenCode 自主决定 |
| **评审员** | OpenCode/Claude Code (运行 task-review) | `/zcf/task-review` | 同上 | DevMate 通过 ACP session 输入 |
| **分析师** | OpenCode/Claude Code (运行 status) | `/zcf/status` | 同上 | DevMate 通过 ACP session 输入 |

**命令格式差异原因**:
- OpenCode: 使用 `/command/arg` 格式（斜杠）
- Claude Code: 使用 `/command:arg` 格式（冒号）

**重要说明**:
1. `/zcf/` 技能是**OpenCode/Claude Code 内部角色使用的**，DevMate 作为终端操作员通过 ACP session 输入这些命令
2. DevMate 使用 `acf-*` Skills 来驱动工作流程（如 `acf-executor` 启动 ACP session）
3. OpenCode/Claude Code 根据接收的命令**扮演不同角色**（架构师/编码助手/评审员/分析师）

---

## 2. Agent 角色与职责

### 2.1 角色矩阵（统一术语）

| 角色 | 职责 | 工作目录 | 使用的命令/技能 | 输出路径 |
|------|------|---------|----------------|---------|
| **DevMate** | 架构讨论、流程驱动、问题发现、架构对比 | 双仓库 | `acf-flow`, `acf-status`, `acf-fix`, `acf-sync`, `acf-executor` | 提案仓库 + 编码仓库 |
| **架构师** (OpenCode/Claude Code) | 架构文档生成（运行 arch-doc） | 编码仓库 | `/zcf/arch-doc` | 仅编码仓库 |
| **编码助手** (OpenCode/Claude Code) | 任务执行、自评（自主执行） | 编码仓库 | `/zcf/workflow` (可选) | 仅编码仓库 |
| **评审员** (OpenCode/Claude Code) | 任务评审（运行 task-review） | 编码仓库 | `/zcf/task-review` | 仅编码仓库 |
| **分析师** (OpenCode/Claude Code) | 状态分析（运行 status） | 编码仓库 | `/zcf/status` | 仅编码仓库 |
| **老板** | 架构决策确认、技术选型审批 | 提案仓库（只读） | 无（人工评审） | - |

**说明**:
- OpenCode/Claude Code 根据接收的命令**扮演不同角色**
- DevMate 通过 ACP session 输入 `/zcf/` 命令唤醒对应角色
- 架构对比由 DevMate 自己执行（对比 mynotes 提案 vs 编码仓库标准化文档）

---

### 2.2 /zcf/ 技能列表（按角色分类）

#### 架构师技能
| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 | 定义位置 |
|------|------|--------------|-----------------|---------|
| `arch-doc` | 架构文档生成（3 阶段：研究→构思→评审） | `/zcf/arch-doc "主题"` | `/zcf:arch-doc "主题"` | `~/.agents/commands/zcf/arch-doc.md` |

#### 编码助手技能（可选，OpenCode 自主决定）
| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 | 定义位置 |
|------|------|--------------|-----------------|---------|
| `workflow` | 代码开发（6 阶段流程） | `/zcf/workflow "任务"` | `/zcf:workflow "任务"` | `~/.agents/commands/zcf/workflow.md` |

#### 评审员技能
| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 | 定义位置 |
|------|------|--------------|-----------------|---------|
| `task-review` | 任务评审（架构一致性检查、偏差识别） | `/zcf/task-review "Task XXX"` | `/zcf:task-review "Task XXX"` | `~/.agents/commands/zcf/task-review.md` |

#### 分析师技能
| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 | 定义位置 |
|------|------|--------------|-----------------|---------|
| `status` | 状态分析（完整/简要/仅下一步） | `/zcf/status [mode]` | `/zcf:status [mode]` | `~/.agents/commands/zcf/status.md` |

#### 协调员技能
| 技能 | 用途 | OpenCode 格式 | Claude Code 格式 | 定义位置 |
|------|------|--------------|-----------------|---------|
| `github-sync` | GitHub 同步（Milestones + Issues） | `/zcf/github-sync "Phase 1"` | `/zcf:github-sync "Phase 1"` | `~/.agents/commands/zcf/github-sync.md` |

---

### 2.3 DevMate 的 acf-workflow Skills

| Skill | 用途 | 调用方式 | 触发条件 |
|-------|------|---------|---------|
| `acf-status` | 项目状态分析，生成进度报告 | `skill_use acf-status [mode]` | 每日 9:00 自动 / 手动 / 新 session |
| `acf-flow` | 任务自动流转（读取计划 → 下一个任务） | `skill_use acf-flow [--next]` | Task 评审通过后 |
| `acf-fix` | 修复任务创建（P0/P1 问题） | `skill_use acf-fix action=create` | 评审发现问题时 |
| `acf-sync` | 同步提案仓库 → 编码仓库 | `skill_use acf-sync [--dry-run]` | 架构定稿后（DevMate 对比一致） |
| **`acf-executor`** | **任务执行（ACP 驱动 OpenCode）** | `skill_use acf-executor task="..."` | **任务执行时** |

**Skill 定义位置**: `/workspace/acf-workflow/skills/*/SKILL.md`

---

### 2.4 acf-executor 执行流程（修复 2）

```
1. DevMate 调用 acf-executor
   skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

2. acf-executor 启动 OpenCode（编码助手角色）
   - 加载 templates/task-prompt.md（含编码助手角色定义）
   - sessions_spawn(runtime="acp", agentId="opencode", task=prompt)
   - 更新状态机：IDLE → EXECUTING

3. OpenCode 自主执行代码（内部可能调用 /zcf/workflow，可选）
   - 读取架构文档
   - 实现代码
   - 编写测试
   - 运行合规检查（bash scripts/check-compliance.sh）
   - Git 分支开发（feature/task-001-xxx）

4. OpenCode 完成任务
   - 更新状态机：EXECUTING → WAITING_REVIEW
   - 等待 DevMate 评审

5. DevMate 运行评审（通过 ACP session 输入）
   /zcf/task-review "Task 001 完成"
   → 唤醒评审员角色 → 输出报告
   → DevMate 查看报告 → acf-flow → 下一任务
```

**关键点**:
- OpenCode 执行方式是**自主决定**的（可能调用 /zcf/workflow，也可能直接编码）
- DevMate 作为**终端操作员**，通过 ACP session 输入 `/zcf/task-review` 唤醒评审员
- 评审结束后，DevMate 查看报告，决定下一步行动

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

### 2.5 Git 分支策略（P0 新增）

**原则**: 每个任务在独立分支上开发，合并前通过合规检查

#### 分支命名规范

```
格式：feature/<task-id>-<short-desc>
示例：
- feature/task-001-crawler-base
- feature/task-002-retry-mechanism
- feature/fix-001-null-pointer
```

#### 分支生命周期

```
1. 任务开始 → 创建分支
   git checkout -b feature/task-001-crawler-base main

2. 编码中 → 提交到分支
   git add . && git commit -m "feat: Crawler 基类实现"

3. 任务完成 → 发起合并请求
   /zcf/task-review "Task 001 完成"

4. 评审通过 → 合并到 main
   bash scripts/merge-branches.sh --feature feature/task-001-crawler-base

5. 合并完成 → 删除分支
   git branch -d feature/task-001-crawler-base
```

#### 分支保护规则

| 规则 | 说明 | 执行方式 |
|------|------|---------|
| ❌ 禁止直接 push main | 所有代码必须通过合并 | `merge-branches.sh` 检查 |
| ✅ 必须通过合规检查 | 测试覆盖率≥80%，无架构违规 | `check-compliance.sh` |
| ✅ 必须通过任务评审 | `/zcf/task-review` 自评通过 | 人工确认 |
| ⚠️ 冲突解决 | 合并前解决所有冲突 | `merge-branches.sh` 检测 |

#### 多任务并行策略

```
场景：Task 002/003/005 并行执行

分支创建:
- feature/task-002-retry
- feature/task-003-circuit
- feature/task-005-storage

合并顺序:
1. 逐个合并（检测冲突）
2. 运行集成测试
3. 删除已合并分支

命令:
bash scripts/merge-branches.sh \
  --feature feature/task-002-retry \
  --feature feature/task-003-circuit \
  --feature feature/task-005-storage
```

---

### 2.6 架构循环→编码循环切换流程（修复 4）

```
1. 架构师 (arch-doc) 完成架构文档
   输出：docs/architecture/YYYY-MM-DD-xxx.md

2. DevMate 对比评审（自己执行，不调用技能）
   - 读取 mynotes 提案草稿
   - 读取编码仓库标准化文档
   - 对比一致性

3. 一致 → acf-sync 同步
   skill_use acf-sync
   → 同步提案仓库 → 编码仓库

4. acf-executor 进入编码循环
   skill_use acf-executor task="Task 001: ..."
   → 启动 OpenCode（编码助手角色）
   → 开始编码
```

**DevMate 对比检查清单**:
- [ ] 架构文档结构一致
- [ ] 模块边界一致
- [ ] 接口定义一致
- [ ] 技术选型一致
- [ ] ADR 约束一致

**不一致时的处理**:
```
1. DevMate 通知架构师（通过 ACP session）
   /zcf/arch-doc "更新：XXX 模块接口定义"

2. 架构师重新生成文档

3. DevMate 再次对比

4. 一致 → 继续步骤 3-4
```

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

### 3.2 编码循环流程（双方协作）— ACP 驱动版

```bash
# 1. 架构文档已定稿（编码仓库）

# 2. DevMate → 编码架构师发送任务（ACP 驱动）
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

# 或
sessions_spawn(
    runtime="acp",
    agentId="opencode",
    task="Task 001: 创建 Crawler 基类",
    cwd="/workspace/ecommerce",
    mode="run",
    label="Task-001"
)

# 3. 编码架构师实现代码（通过 ACP 协议）
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

### 3.4 任务接收决策树（强制流程）

**版本**: v1.0  
**生效日期**: 2026-03-31  
**强制级别**: 🔴 必须遵循

---

#### 3.4.1 决策树流程图

```
收到任务
    │
    ▼
┌─────────────────────────────────────┐
│ 步骤 1: 需求澄清检查                 │
│ 问自己以下 4 个问题：                │
│ □ 交付物格式明确？（代码/文档/图片） │
│ □ 技术选型/偏好明确？               │
│ □ 优先级明确？（性能/可读性/速度）  │
│ □ 范围边界明确？（验收标准）        │
└─────────────────────────────────────┘
    │
    ├─ 有任一模糊 ──→ 🛑 触发 Interview（最多 5 问，2 轮上限）
    │                  格式：选择题 + 1 个开放题
    │                  输出：写入 memory/YYYY-MM-DD.md
    │
    ▼ 全部明确
┌─────────────────────────────────────┐
│ 步骤 2: 架构复杂度评估              │
│ 问自己以下 4 个问题：                │
│ □ 是否涉及新领域/新技术栈？         │
│ □ 是否影响现有系统架构？            │
│ □ 是否有重大技术选型决策？          │
│ □ 预估工作量 > 1 天？               │
└─────────────────────────────────────┘
    │
    ├─ 全部否 ──→ 进入编码循环（快循环）
    │              直接调用 acf-executor 执行
    │
    ▼ 有任一是
┌─────────────────────────────────────┐
│ 步骤 3: 架构循环（慢循环）           │
│ 3.1 DevMate 手工创建架构草稿         │
│     → /workspace/mynotes/<Project>/ │
│       docs/architecture/draft.md    │
│ 3.2 找老板评审草稿（关键决策点）     │
│     - 技术选型                      │
│     - 模块边界                      │
│     - 数据流向                      │
│ 3.3 老板确认后 → 派给 OpenCode       │
│     /zcf/arch-doc "<主题>"          │
│ 3.4 对比评审（mynotes vs 编码仓库）  │
│     - 一致 → 架构定稿，进入步骤 3.5   │
│     - 不一致 → 返回步骤 3.1          │
│ 3.5 acf-sync 同步 → 进入编码循环     │
└─────────────────────────────────────┘
```

---

#### 3.4.2 架构循环 ↔ 编码循环 切换规则

**进入架构循环的条件**（满足任一即切换）:

| 条件 | 严重性 | 行动 |
|------|--------|------|
| ❌ 架构缺陷（严重） | 严重 | 暂停编码，返回架构循环 |
| ❌ 技术选型变更 | 严重 | 暂停编码，返回架构循环 |
| ❌ 需求重大变更（>30%） | 严重 | 暂停编码，返回架构循环 |
| ❌ 新增模块 | 中等 | 评估后决定是否返回架构循环 |
| ❌ 老板决策 | 严重 | 立即返回架构循环 |
| ❌ 架构违规（评审发现） | 严重 | 暂停任务，返回架构循环 |
| ❌ 依赖方向错误（评审发现） | 严重 | 暂停任务，返回架构循环 |
| ❌ 评审发现 P0 问题 | 严重 | 暂停后续任务，返回架构循环 |

**保持编码循环的条件**（满足全部即继续）:

| 条件 | 说明 |
|------|------|
| ✅ 任务在已定稿架构范围内 | 无需架构调整 |
| ✅ 技术选型无变更 | 沿用已有决策 |
| ✅ 偏差为轻微级别 | 记录 CHANGELOG 即可 |
| ✅ 老板无新决策 | 按原计划执行 |

---

#### 3.4.3 如何保证严格遵循（执行机制）

**1. 文件化检查清单**（而非上下文记忆）

每次任务接收前，DevMate 必须读取：
- `/workspace/acf-workflow/docs/decision-tree.md`（决策树）
- `/workspace/acf-workflow/docs/acf-cheatsheet.md`（快速参考）

**2. 强制写入记忆文件**

任务接收后 1 分钟内，必须写入 `memory/YYYY-MM-DD.md`：
```markdown
## In Progress
- [ ] [任务 ID] 任务描述
  - 需求澄清状态：✅ 已完成 / 🛑 待 Interview
  - 架构评估：🟢 简单（直接编码）/ 🟡 复杂（需架构循环）
  - 当前阶段：架构草稿 / 编码中 / 评审中
```

**3. Gateway Restart 恢复检查**

收到 GatewayRestart 通知后，必须：
1. 读取 `memory/YYYY-MM-DD.md` 的 `## In Progress` 部分
2. 读取 `temp/*.plan.md` 恢复未完成任务
3. 检查决策树状态（是否卡在 Interview/架构评审）

**4. 违反决策树的后果与修复**

| 违规行为 | 后果 | 修复方案 |
|---------|------|---------|
| 跳过 Interview 直接执行 | 需求理解偏差，返工 | 暂停任务 → 补 Interview → 更新记忆 |
| 未评估复杂度直接编码 | 架构缺陷，后期大改 | 暂停 → 补架构草稿 → 对比评审 |
| 编码架构师写提案仓库 | 仓库权限混乱 | 删除错误文件 → 更新触发器阻止 |
| 未写入记忆文件 | Gateway Restart 后丢失上下文 | 立即补写 → 设置 cron 提醒 |

---

#### 3.4.4 快速参考卡（打印版）

```
┌─────────────────────────────────────────────────────────┐
│           ACF 工作流决策树 - 快速参考卡                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 收到任务 → 问自己 4 个问题（需求澄清）                    │
│           ├─ 有模糊 → Interview（5 问，2 轮）            │
│           └─ 全明确 → 问自己 4 个问题（复杂度评估）      │
│                        ├─ 全否 → 编码循环（直接执行）    │
│                        └─ 有是 → 架构循环（草稿→评审）   │
│                                                         │
│ 编码中发现问题 → 判断严重性                             │
│           ├─ 严重（架构/选型/需求变更）→ 返回架构循环    │
│           └─ 轻微（偏差/补充）→ 记录 CHANGELOG 继续      │
│                                                         │
│ 记忆规则：                                              │
│ - 每日琐事 → memory/YYYY-MM-DD.md                       │
│ - 重大决策 → MEMORY.md                                  │
│ - 任务状态 → 立即写入，不要等"稍后"                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

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

### 4.3 状态追踪结构（双层记忆）

#### 全局记忆（跨项目）

**位置**: `memory/YYYY-MM-DD.md`（工作区根目录）

**用途**: 记录当天所有项目的关键事件、决策、状态变更

**格式**: 见 `docs/decision-tree.md#4.2`

---

#### 项目记忆（单项目）⭐

**位置**: `/workspace/<Project>/.acf/`

**用途**: 追踪项目级进展，支持重启后快速恢复

**目录结构**:
```
/workspace/<Project>/.acf/
├── status/
│   ├── current-task.md        # 当前任务状态（⭐重启恢复用）
│   ├── current-phase.md       # 当前阶段概览
│   └── YYYY-MM-DD-status.md   # 每日状态报告（acf-status 生成）
├── temp/
│   ├── task-plans/            # 任务计划（phase*-tasks.md）
│   ├── arch-issues.md         # 架构问题记录
│   └── execution-log.md       # 执行日志
└── config/
    └── acf-triggers.yaml      # 触发器配置
```

**核心文件**: `current-task.md`（重启恢复的关键）

**完整格式**: 见 `docs/decision-tree.md#4.2`

---

### 4.3.1 状态更新规则

#### 自动更新触发

| 事件 | 更新文件 | 更新时机 |
|------|---------|---------|
| 任务开始 | `.acf/status/current-task.md` | 调用 acf-executor 前 |
| 任务完成 | `.acf/status/current-task.md` | 评审通过后 |
| 阶段完成 | `.acf/status/current-phase.md` | 所有任务完成后 |
| 架构变更 | `.acf/temp/arch-issues.md` | 发现问题时 |
| 每日站会 | `.acf/status/YYYY-MM-DD-status.md` | 每日 9:00（cron） |

#### 更新内容

**current-task.md**（任务级）:
- 任务进度表（完成数/总数/百分比）
- 当前任务详情（ID、描述、验收标准）
- 下一步行动

**current-phase.md**（阶段级）:
- 阶段目标
- 任务列表与状态
- 阻塞点

**YYYY-MM-DD-status.md**（日报）:
- 偏差追踪表（今日/累计）
- 效率指标（本周/累计）
- 技术债务汇总

---

### 4.3.2 Gateway Restart 恢复流程（claims.json 优化版）

**收到 GatewayRestart 通知后，必须**（优化后 30 秒 → 3 秒）:

```bash
# 步骤 1: 读取 claims.json（快速恢复，3 秒）⭐
CLAIMS_FILE=".acf/temp/claims.json"
if [ -f "$CLAIMS_FILE" ]; then
    echo "=== 进行中的任务 ==="
    cat "$CLAIMS_FILE" | jq -r 'to_entries[] | "\(.key): \(.value.agent_id) (\(.value.status))"'
fi

# 步骤 2: 检查每个任务 session 是否存活
for task_id in $(cat "$CLAIMS_FILE" | jq -r 'keys[]'); do
    agent_id=$(jq -r --arg id "$task_id" '.[$id].agent_id' "$CLAIMS_FILE")
    
    # 检查 session 是否存活
    if openclaw sessions list 2>/dev/null | grep -q "$agent_id"; then
        echo "✅ $task_id: 执行中 ($agent_id)"
    else
        echo "⚠️  $task_id: session 已丢失，需要恢复"
        # 释放 claim
        source scripts/lib/claims.sh && release_claim "$task_id"
    fi
done

# 步骤 3: 读取状态机（仅当 claims.json 为空时）
if [ ! -s "$CLAIMS_FILE" ] || [ "$(cat "$CLAIMS_FILE" | jq 'length')" -eq 0 ]; then
    echo "=== 状态机（备用）==="
    cat .acf/status/current-task.md | grep -A 15 "## 状态机"
fi
```

**恢复决策表**:

| claims.json 状态 | Session 状态 | 恢复动作 |
|-----------------|-------------|---------|
| 有任务 | 存活 | 继续监控，等待完成 |
| 有任务 | 丢失 | 释放 claim，通知 DevMate |
| 空 | - | 读取状态机（备用） |

**输出**: 重启恢复报告（主动汇报给老板）

**收益**:
- 恢复时间从 30 秒 → **3 秒**（单文件查询 vs 遍历目录）
- 支持并行任务追踪（claims.json 包含所有任务）
- 自动检测 session 丢失并释放 claim

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
| **`acf-executor`** | **执行任务（ACP 驱动 OpenCode）** | **任务执行时** |

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
   DevMate → acf-executor: skill_use acf-executor task="Task 001: ..."
   ↓
   OpenCode 通过 ACP 执行任务
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

# 执行任务（ACP 驱动 OpenCode）
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

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

## 7. ACP 配置要求

### 7.1 必需配置 (`~/.openclaw/openclaw.json`)

```json5
{
  "acp": {
    "enabled": true,
    "backend": "acpx",
    "defaultAgent": "opencode",
    "allowedAgents": ["opencode", "codex", "claude"],
    "maxConcurrentSessions": 4
  },
  "plugins": {
    "entries": {
      "acpx": {
        "enabled": true,
        "config": {
          "permissionMode": "approve-all",
          "nonInteractivePermissions": "deny"
        }
      }
    }
  },
  "skills": {
    "load": {
      "extraDirs": [
        "~/.agents/skills",
        "/workspace/acf-workflow/skills"
      ]
    }
  }
}
```

### 7.2 检查命令

```bash
# 检查 ACP 状态
/acp doctor

# 检查配置
openclaw config show acp.enabled
openclaw config show plugins.entries.acpx.enabled

# 列出可用 Agents
agents_list
```

### 7.3 安装 OpenCode

```bash
# 检查是否安装
opencode --version

# 安装（如未安装）
npm install -g opencode
```

**当前版本**: v1.3.7+

---

## 8. 快速启动

### 8.1 新项目初始化

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
- `skill_use acf-executor` - 执行任务（ACP 驱动 OpenCode）

### 编码架构师（OpenCode/Claude Code）
- OpenCode:   /zcf/arch-doc, /zcf/task-review, /zcf/status
- ClaudeCode: /zcf:arch-doc, /zcf:task-review, /zcf:status

## 仓库权限
- 提案仓库 (mynotes/): 仅 DevMate 可写
- 编码仓库 (当前目录): DevMate + 编码架构师可写
EOF
```

### 8.2 每日工作流

```bash
# 早上：查看状态
skill_use acf-status mode=brief

# 开始编码前：确认架构文档最新
skill_use acf-sync list=true

# 执行任务
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

# 任务完成：评审
# DevMate → OpenCode: /zcf/task-review "Task 001 完成"

# 获取下一个任务
skill_use acf-flow --next

# 晚上：记录日志
# 自动写入 memory/YYYY-MM-DD.md
```

---

## 9. 切换到慢循环（架构循环）的条件

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

## 10. 效率指标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 架构讨论干扰 | < 5 分钟/天 | 手动记录 |
| 编程助手理解准确率 | > 90% | 评审偏差统计 |
| 同步执行时间 | < 30 秒 | acf-sync 计时 |
| 偏差检测自动化率 | > 80% | 自动/手动比例 |
| 综合效率提升 | > 2x | 对比单仓库手动管理 |
| **ACP 任务启动时间** | **< 5 秒** | **sessions_spawn 计时** |
| **OpenCode 响应时间** | **< 30 秒** | **首次输出计时** |

---

## 11. 变更日志

| 日期 | 版本 | 变更 | 理由 |
|------|------|------|------|
| 2026-03-30 | v3.1 | **ACP 驱动 OpenCode 实现** | 添加 acf-executor Skill，配置 ACP，实现 `sessions_spawn(runtime="acp")` |
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
| **`acf-acp-setup-complete.md`** | **ACP 配置与测试报告** |
| **`acf-opencode-driver-comparison.md`** | **OpenCode 驱动方式比较** |
| **`acf-env-usage.md`** | **环境变量使用指南** |

---

**版本**: v3.1  
**状态**: 生效中  
**下次评审**: 2026-04-05  
**维护人**: DevMate
