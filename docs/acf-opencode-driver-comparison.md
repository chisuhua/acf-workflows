# ACF-Workflow OpenCode 驱动方式深度比较报告

**比较时间**: 2026-03-30  
**比较对象**: 当前版本 (acf-workflow) vs 旧版本 (archive/zcf-workflow-旧项目)  
**焦点问题**: 如何驱动 OpenCode？是否通过 ACP？

---

## 📊 执行摘要

| 维度 | 旧版本 (archive) | 当前版本 (acf-workflow) | 状态 |
|------|-----------------|------------------------|------|
| **OpenCode 启动方式** | tmux + send-keys | `task()` 函数（未明确实现） | ⚠️ 模糊 |
| **并行执行** | tmux 多窗口 | sessions_spawn（文档提到） | ⚠️ 需确认 |
| **ACP 使用** | ❌ 未使用 | ❌ 未明确使用 | 🔴 缺失 |
| **交互式问题** | ❌ tmux 无法启动 OpenCode | 未解决 | 🔴 风险 |
| **记忆机制** | OpenCode 独立 session 文件 | 未明确 | 🔴 缺失 |

**核心发现**: **当前版本没有明确说明如何驱动 OpenCode，`task()` 函数实现模糊，ACP 未使用**

---

## 🔍 详细比较

### 1. OpenCode 启动方式

#### 旧版本（archive）— tmux + send-keys

**实现方式**:
```bash
# ADR-003-multi-agent-architecture.md
# 阶段 2: 启动 OpenCode

# 创建 tmux 窗口
tmux new-window -n task-002
tmux new-window -n task-003
tmux new-window -n task-005

# 启动 OpenCode 实例
tmux send-keys -t task-002 "opencode --workdir /workspace/ecommerce --session task-002" Enter
tmux send-keys -t task-003 "opencode --workdir /workspace/ecommerce --session task-003" Enter
tmux send-keys -t task-005 "opencode --workdir /workspace/ecommerce --session task-005" Enter
```

**问题**（MULTI-AGENT-TRIAL-REPORT.md）:
```
问题 1: OpenCode 未实际启动
发现时间：20:00
严重级别：⚠️ 中等
问题描述：tmux 窗口创建成功，但 OpenCode 实例未实际启动（需要交互式终端）
影响：无法真正并行执行，改为 DevMate 模拟执行
根因：OpenCode 需要交互式终端，tmux send-keys 无法启动
```

**解决方案建议**（旧版本文档）:
```
方案 A: 使用 `openclaw sessions_spawn` 创建子会话（推荐）
方案 B: 使用脚本自动化 OpenCode 启动
方案 C: 继续使用 DevMate 模拟（当前方案）
```

---

#### 当前版本（acf-workflow）— `task()` 函数

**实现方式**（文档中）:
```bash
# acf-workflow.md
# 编码循环流程
task(prompt="Task 001: 创建 Crawler 基类")

# acf-flow/scripts/auto-flow.sh
task(
    category="deep",
    prompt="$TASK_ID: $TASK_TITLE",
    load_skills=["subagent-driven-development"]
)
```

**问题**:
1. **`task()` 是什么？** — 不是 OpenClaw 内置工具
2. **如何实现？** — 没有 `acf-executor` Skill
3. **是否启动 OpenCode？** — 未明确说明
4. **是否使用 ACP？** — 未提及

**文档中的模糊引用**:
```bash
# acf-ecommerce-case-study.md
- ✅ Agents 使用 OpenClaw 的 sessions_spawn 并行执行
| 支持并行执行 | ✅ sessions_spawn 并行 | ✅ |
```

但这只是**案例复盘中的描述**，不是实际实现。

---

### 2. 并行执行机制

#### 旧版本（archive）— tmux 多窗口

```bash
# start-multi-agent.sh
for task in "${TASKS[@]}"; do
    WINDOW_NAME="${task,,}"
    tmux new-window -n "$WINDOW_NAME"
    tmux send-keys -t "$WINDOW_NAME" "echo '=== $task ===' && date" Enter
done
```

**优点**:
- ✅ 真正并行（多个 tmux 窗口）
- ✅ 每个 OpenCode 实例独立

**缺点**:
- ❌ OpenCode 无法通过 tmux send-keys 启动（需要交互式终端）
- ❌ 协调复杂度高

---

#### 当前版本（acf-workflow）— sessions_spawn（文档提到）

```bash
# acf-ecommerce-case-study.md（仅文档描述）
Agents 使用 OpenClaw 的 sessions_spawn 并行执行
```

**但实际代码中**:
```bash
# acf-flow/scripts/auto-flow.sh
task(
    category="deep",
    prompt="$TASK_ID: $TASK_TITLE",
    load_skills=["subagent-driven-development"]
)
```

**问题**:
- `task()` 是否调用 `sessions_spawn`？— 未明确
- `runtime="subagent"` 还是 `runtime="acp"`？— 未指定
- 是否真正并行？— 未验证

---

### 3. ACP 使用情况

#### 旧版本（archive）— ❌ 未使用

```bash
# 搜索 archive 目录
grep -r "ACP\|acp" archive/  # 无结果（除了 ADR 中提到的 sessions_spawn 建议）
```

**原因**: 旧版本设计时 ACP 可能还未成熟

---

#### 当前版本（acf-workflow）— ❌ 未明确使用

```bash
# 搜索 acf-workflow 目录（排除 archive）
grep -r "ACP\|acp\|runtime.*acp" /workspace/acf-workflow/ --exclude-dir=archive
# 结果：仅 acf-ecommerce-case-study.md 中提到 sessions_spawn
```

**问题**:
- 当前版本**没有使用 ACP 驱动 OpenCode**
- `task()` 函数可能使用的是 `runtime="subagent"`（OpenClaw 原生）
- 这意味着**无法利用 OpenCode 的专业编码能力**

---

### 4. 记忆机制

#### 旧版本（archive）— OpenCode 独立 session 文件

```bash
# ADR-003
### OpenCode 记忆（执行层）
位置：~/.local/share/opencode/sessions/<session-id>.jsonl

记录内容:
- 任务理解
- 执行计划
- 代码实现过程
- 测试结果
- handoff 内容
```

**优点**:
- ✅ 每个任务有完整历史
- ✅ 可追溯决策过程
- ✅ 支持中断后恢复

---

#### 当前版本（acf-workflow）— 未明确

```bash
# 未找到记忆机制相关文档
grep -r "session.*file\|memory\|\.jsonl" /workspace/acf-workflow/ --exclude-dir=archive
# 结果：无
```

**问题**:
- 如果使用 `runtime="subagent"`，记忆继承父会话
- 如果使用 `runtime="acp"`，应有独立 session 文件
- 当前**未明确记忆机制**

---

### 5. 命令格式支持

#### 旧版本（archive）— OpenCode 直接启动

```bash
# 不使用 /zcf/ 命令，直接启动 opencode
tmux send-keys -t task-002 "opencode --workdir /workspace/ecommerce --session task-002" Enter
```

**原因**: 旧版本中 `/zcf/` 命令是 OpenCode 的 Commands，但通过 tmux 无法正确使用

---

#### 当前版本（acf-workflow）— `/zcf/` 命令（触发器）

```bash
# acf-triggers.yaml
trigger:
  name: task-completed
  condition:
    type: command
    pattern: "/zcf[:/]task-review.*评审通过"  # ✅ 已修复支持两种格式
  action:
    type: skill
    name: acf-flow
```

**但问题**:
- 触发器监听 `/zcf/` 命令
- 但**谁在执行 `/zcf/` 命令**？— 文档说 OpenCode，但实际未启动 OpenCode
- **矛盾点**: 如果 `task()` 使用 subagent，subagent 无法执行 `/zcf/` 命令（这是 OpenCode 的 Commands）

---

## 🔴 核心问题识别

### 问题 1: `task()` 函数实现模糊

**现状**:
```bash
# acf-flow/scripts/auto-flow.sh
task(
    category="deep",
    prompt="$TASK_ID: $TASK_TITLE",
    load_skills=["subagent-driven-development"]
)
```

**问题**:
- `task()` 不是 OpenClaw 内置工具
- 没有 `acf-executor` Skill 实现这个函数
- 这是一个**占位符/伪代码**

**可能的实现**:
1. **OpenClaw sessions_spawn**（subagent 模式）
   ```python
   sessions_spawn(
       runtime="subagent",
       task="Task 001: ...",
       mode="run"
   )
   ```

2. **OpenClaw sessions_spawn**（ACP 模式）
   ```python
   sessions_spawn(
       runtime="acp",
       agentId="opencode",
       task="Task 001: ...",
       mode="run"
   )
   ```

3. **直接调用 OpenCode CLI**
   ```bash
   opencode run "Task 001: ..."
   ```

**当前状态**: **未实现**

---

### 问题 2: ACP 未使用

**搜索结果**:
```bash
# 当前版本（排除 archive）
grep -r "runtime.*acp\|sessions_spawn.*acp" /workspace/acf-workflow/ --exclude-dir=archive
# 结果：无
```

**影响**:
- 如果使用 `runtime="subagent"`：
  - ❌ 无法利用 OpenCode 的专业编码能力
  - ❌ 无法使用 `/zcf/` 命令（这是 OpenCode 的 Commands）
  - ❌ 无独立记忆（继承父会话）
  - ✅ 沙箱隔离（安全）

- 如果使用 `runtime="acp"`：
  - ✅ 利用 OpenCode 的专业编码能力
  - ✅ 可以使用 `/zcf/` 命令
  - ✅ 独立记忆
  - ❌ 无法在沙箱中运行

**当前状态**: **未明确，但倾向于是 subagent（因为没配置 ACP）**

---

### 问题 3: 交互式启动问题未解决

**旧版本问题**（MULTI-AGENT-TRIAL-REPORT.md）:
```
OpenCode 需要交互式终端，tmux send-keys 无法启动
```

**当前版本**:
- 如果使用 `task()` → `sessions_spawn(runtime="subagent")`：
  - ✅ 不需要交互式终端（OpenClaw 管理）
  - 但❌ 不是 OpenCode

- 如果使用 `task()` → `sessions_spawn(runtime="acp", agentId="opencode")`：
  - ✅ 不需要交互式终端（ACP 协议）
  - ✅ 是 OpenCode
  - 但❌ 需要配置 ACP

**当前状态**: **未明确是否解决**

---

## 📋 架构对比图

### 旧版本架构（archive）

```
┌─────────────────────────────────────────────────────────────┐
│  DevMate（协调层）                                           │
│  ↓ tmux send-keys（❌ 无法启动 OpenCode）                     │
├─────────────────────────────────────────────────────────────┤
│  tmux 窗口                                                   │
│  ├── task-002 → opencode（❌ 启动失败）                      │
│  ├── task-003 → opencode（❌ 启动失败）                      │
│  └── task-005 → opencode（❌ 启动失败）                      │
└─────────────────────────────────────────────────────────────┘
```

---

### 当前版本架构（acf-workflow）— 理论设计

```
┌─────────────────────────────────────────────────────────────┐
│  DevMate                                                     │
│  ↓ skill_use acf-flow                                        │
├─────────────────────────────────────────────────────────────┤
│  acf-flow Skill                                              │
│  ↓ task() 函数（❌ 未实现）                                   │
├─────────────────────────────────────────────────────────────┤
│  预期：OpenCode（通过 ACP 或 subagent）                       │
│  实际：❌ 未知                                                │
└─────────────────────────────────────────────────────────────┘
```

---

### 实际应该的架构（推荐）

```
┌─────────────────────────────────────────────────────────────┐
│  DevMate                                                     │
│  ↓ skill_use acf-flow                                        │
├─────────────────────────────────────────────────────────────┤
│  acf-flow Skill                                              │
│  ↓ sessions_spawn(runtime="acp", agentId="opencode")        │
├─────────────────────────────────────────────────────────────┤
│  ACP Backend (acpx 插件)                                     │
│  ↓ ACP 协议                                                   │
├─────────────────────────────────────────────────────────────┤
│  OpenCode（编码架构师）                                      │
│  ↓ /zcf/task-review 自评                                     │
├─────────────────────────────────────────────────────────────┤
│  触发器监听 /zcf/ 命令 → acf-flow → 下一个任务               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 建议的修复行动

### P0: 明确 `task()` 函数实现

**选项 A: 使用 ACP + OpenCode（推荐）**
```python
# acf-flow/scripts/auto-flow.sh 或 acf-flow Skill
sessions_spawn(
    runtime="acp",
    agentId="opencode",
    task=f"{TASK_ID}: {TASK_TITLE}",
    cwd=PROJECT_PATH,
    mode="run"
)
```

**选项 B: 使用 subagent（简单但能力弱）**
```python
sessions_spawn(
    runtime="subagent",
    task=f"{TASK_ID}: {TASK_TITLE}",
    cwd=PROJECT_PATH,
    mode="run"
)
```

**建议**: **选项 A**（ACP + OpenCode），因为：
1. 工作流设计初衷是使用 OpenCode 的专业能力
2. `/zcf/` 命令是 OpenCode 的 Commands，subagent 无法执行
3. 独立记忆机制

---

### P1: 配置 ACP

```json5
// ~/.openclaw/config.json
{
  acp: {
    enabled: true,
    backend: "acpx",
    defaultAgent: "opencode",
    allowedAgents: ["opencode", "codex", "claude"],
  },
  plugins: {
    entries: {
      acpx: {
        enabled: true,
        config: {
          permissionMode: "approve-all",
          nonInteractivePermissions: "deny",
        }
      }
    }
  }
}
```

---

### P2: 更新文档

**需要更新的文档**:
1. `acf-workflow.md` — 明确 `task()` 函数实现
2. `acf-skills-guide.md` — 添加 ACP 配置要求
3. `acf-quickstart.md` — 添加 ACP 安装步骤
4. 创建 `acf-acp-setup.md` — ACP 配置指南

---

### P3: 添加记忆机制说明

**文档更新**:
```markdown
## 记忆机制

### DevMate 记忆（协调层）
位置：`~/.openclaw/agents/main/sessions/<session-id>.jsonl`

### OpenCode 记忆（执行层，通过 ACP）
位置：`~/.local/share/opencode/sessions/<session-id>.jsonl`
或 `~/.openclaw/agents/opencode/sessions/<session-id>.jsonl`
```

---

## 📊 总结

| 问题 | 旧版本 | 当前版本 | 状态 |
|------|--------|---------|------|
| OpenCode 启动 | tmux（失败） | `task()`（未实现） | 🔴 未解决 |
| ACP 使用 | ❌ 未使用 | ❌ 未使用 | 🔴 缺失 |
| 并行执行 | tmux 多窗口 | sessions_spawn（文档） | ⚠️ 需确认 |
| 记忆机制 | OpenCode session 文件 | 未明确 | 🔴 缺失 |
| 交互式问题 | ❌ tmux 无法启动 | 未解决（取决于实现） | ⚠️ 风险 |

**核心结论**: **当前版本（acf-workflow）相比旧版本（archive）在文档上更清晰，但核心问题（如何驱动 OpenCode）仍未明确实现。`task()` 函数是占位符，ACP 未使用，记忆机制未明确。**

**建议优先级**:
1. P0: 实现 `task()` 函数（使用 `sessions_spawn(runtime="acp", agentId="opencode")`）
2. P1: 配置 ACP
3. P2: 更新文档
4. P3: 添加记忆机制说明

---

**检查人**: DevMate  
**检查时间**: 2026-03-30  
**下次检查**: 实现 P0/P1 后复验
