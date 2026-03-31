# ACF Executor Skill

**技能名称**: `acf-executor`  
**用途**: 执行任务（通过 ACP 驱动 OpenCode）  
**调用方式**: `skill_use acf-executor task="Task 001: xxx" [cwd="/workspace/project"]`

---

## 功能

- 通过 `sessions_spawn` 工具启动 ACP 驱动的 OpenCode
- 传递任务 Prompt 给 OpenCode
- 支持并行执行多个任务
- 支持任务标签和状态追踪

---

## 输入参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `task` | str | ✅ | 任务描述（如 "Task 001: 创建 Crawler 基类"） |
| `cwd` | str | ❌ | 工作目录（默认：`/workspace/ecommerce`） |
| `mode` | str | ❌ | 执行模式：`run`（一次性）/`session`（持久）（默认：run） |
| `label` | str | ❌ | 任务标签（默认：任务 ID） |
| `parallel` | bool | ❌ | 是否并行执行（默认：false） |

---

## 输出格式

### 执行成功

```markdown
## ✅ 任务已启动

**任务 ID**: Task 001
**任务描述**: 创建 Crawler 基类
**执行模式**: ACP + OpenCode
**工作目录**: /workspace/ecommerce
**Session Key**: agent:opencode:acp:xxx-xxx-xxx

### 状态
- 🔄 执行中...

### 监控
- 查看日志：`sessions_history sessionKey="agent:opencode:acp:xxx"`
- 停止任务：`/acp cancel agent:opencode:acp:xxx`

---

**下一步**: 等待任务完成 → 运行 `/zcf/task-review "Task 001 完成"`
```

### 执行失败

```markdown
## ❌ 任务启动失败

**错误信息**: {{错误详情}}

**可能原因**:
1. ACP 未启用 → 检查配置 `acp.enabled=true`
2. OpenCode 未安装 → 运行 `npm install -g opencode`
3. 权限不足 → 检查 `plugins.entries.acpx.config.permissionMode`

**解决方案**:
\`\`\`bash
# 检查 ACP 状态
/acp doctor

# 检查配置
openclaw config show acp
\`\`\`
```

---

## 前置检查流程（🔴 强制）

**在调用 `acf-executor` 执行任务前，DevMate 必须完成以下检查**：

### 检查 1: 需求澄清状态

```bash
# 读取记忆文件，确认需求已澄清
cat memory/YYYY-MM-DD.md | grep -A 5 "任务 ID"

# 检查项：
# □ 交付物格式明确？
# □ 技术选型/偏好明确？
# □ 优先级明确？
# □ 范围边界明确？
```

**如果任一未明确** → 🛑 暂停，先执行 Interview（见 `docs/acf-workflow.md#3.4`）

---

### 检查 2: 架构评估状态

```bash
# 检查架构文档是否存在
ls -la docs/architecture/*.md

# 检查同步状态
cat docs/architecture/SYNC-REPORT.md 2>/dev/null || echo "⚠️ 无同步报告"

# 检查项：
# □ 是否涉及新领域/新技术栈？
# □ 是否影响现有系统架构？
# □ 是否有重大技术选型决策？
# □ 预估工作量 > 1 天？
```

**如果有任一是** → 🛑 暂停，先走架构循环（创建草稿 → 老板评审 → /zcf/arch-doc → 对比评审 → acf-sync）

---

### 检查 3: 任务计划文件

```bash
# 检查任务计划是否存在
cat temp/phase*-tasks.md 2>/dev/null || echo "⚠️ 无任务计划"

# 确认当前任务在计划中
grep "Task XXX" temp/phase*-tasks.md
```

---

### 检查清单（快速版）

```markdown
## 任务执行前检查清单

- [ ] 需求澄清：✅ 已完成（见 memory/YYYY-MM-DD.md）
- [ ] 架构评估：🟢 简单 / 🟡 复杂（已走架构循环）
- [ ] 任务计划：✅ 已定义（见 temp/phase*-tasks.md）
- [ ] 工作目录：✅ 已确认（cwd="/workspace/xxx"）

**检查人**: DevMate  
**检查时间**: YYYY-MM-DD HH:MM  
**状态**: ✅ 通过，可以执行
```

---

## 使用示例

### 示例 1: 执行单个任务

```bash
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"
```

### 示例 2: 并行执行多个任务

```bash
# 同时启动 3 个任务
skill_use acf-executor task="Task 002: 实现重试机制" cwd="/workspace/ecommerce" parallel=true
skill_use acf-executor task="Task 003: 实现熔断器" cwd="/workspace/ecommerce" parallel=true
skill_use acf-executor task="Task 005: 数据存储工具" cwd="/workspace/ecommerce" parallel=true
```

### 示例 3: 持久会话模式

```bash
# 创建持久会话（用于长期任务）
skill_use acf-executor task="阶段 1: 爬虫模块" cwd="/workspace/ecommerce" mode="session" label="phase-1-crawler"
```

---

## 实现细节

**封装脚本**: `scripts/execute-task.sh`

**核心逻辑**:
```bash
#!/bin/bash
# execute-task.sh

TASK="${1:-}"
CWD="${2:-/workspace/ecommerce}"
MODE="${3:-run}"
LABEL="${4:-task}"

# 使用 OpenClaw sessions spawn 启动 ACP 驱动的 OpenCode
openclaw sessions spawn \
  --runtime acp \
  --agent-id opencode \
  --task "$TASK" \
  --cwd "$CWD" \
  --mode "$MODE" \
  --label "$LABEL"
```

**OpenClaw 工具调用**（推荐）:
```json
{
  "tool": "sessions_spawn",
  "params": {
    "runtime": "acp",
    "agentId": "opencode",
    "task": "Task 001: 创建 Crawler 基类",
    "cwd": "/workspace/ecommerce",
    "mode": "run",
    "label": "Task 001"
  }
}
```

---

## ACP 配置要求

### 必需配置

```json5
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

### 检查命令

```bash
# 检查 ACP 状态
/acp doctor

# 检查配置
openclaw config show acp
openclaw config show plugins.entries.acpx

# 列出可用 Agents
agents_list
```

---

## 与 /zcf/ 命令的集成

### 任务执行流程

```
skill_use acf-executor
        ↓
sessions_spawn(runtime="acp", agentId="opencode")
        ↓
OpenCode 执行任务
        ↓
DevMate → OpenCode: /zcf/task-review "Task 001 完成"
        ↓
触发器监听 → acf-flow → 下一个任务
```

### 评审命令格式

| 编码架构师 | 评审命令格式 |
|-----------|-------------|
| OpenCode | `/zcf/task-review "Task 001 完成"` |
| Claude Code | `/zcf:task-review "Task 001 完成"` |

---

## 错误处理

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `ACP runtime backend is not configured` | ACP 未启用 | `openclaw config set acp.enabled true` |
| `ACP agent "opencode" is not allowed` | Agent 不在白名单 | `openclaw config set acp.allowedAgents '["opencode"]'` |
| `Permission prompt unavailable` | 权限模式配置错误 | `openclaw config set plugins.entries.acpx.config.permissionMode approve-all` |
| `opencode: command not found` | OpenCode 未安装 | `npm install -g opencode` |

---

## 相关 Skills

- `acf-flow` - 任务流转（获取下一个任务）
- `acf-reviewer` - 任务评审
- `acf-fix` - 修复任务创建
- `acf-status` - 状态追踪

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-03-30 | 初始版本（ACP 驱动 OpenCode） |

---

**版本**: v1.0  
**创建时间**: 2026-03-30  
**状态**: 已创建
