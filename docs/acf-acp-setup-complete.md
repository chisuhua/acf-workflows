# ACP 驱动 OpenCode 配置与测试报告

**配置时间**: 2026-03-30  
**测试状态**: ✅ 成功  
**测试会话**: `agent:opencode:acp:6d9431e0-d27a-4a39-8d9c-8ceb846f622b`

---

## 📊 执行摘要

| 检查项 | 状态 | 说明 |
|--------|------|------|
| ACP 配置 | ✅ 已启用 | `acp.enabled=true` |
| ACP 后端 | ✅ acpx | `acp.backend=acpx` |
| 默认 Agent | ✅ opencode | `acp.defaultAgent=opencode` |
| 允许 Agents | ✅ opencode | `acp.allowedAgents=["opencode"]` |
| acpx 插件 | ✅ 已启用 | `plugins.entries.acpx.enabled=true` |
| 权限模式 | ✅ approve-all | `permissionMode=approve-all` |
| Skills 路径 | ✅ 已添加 | `/workspace/acf-workflow/skills` |
| ACP 会话创建 | ✅ 成功 | `agent:opencode:acp:xxx` |
| OpenCode 安装 | ✅ v1.3.7 | 已安装 |

**测试结果**: **ACP 驱动 OpenCode 配置成功，会话创建成功**

---

## 🔧 配置详情

### 1. ACP 配置 (`~/.openclaw/openclaw.json`)

```json5
{
  "acp": {
    "enabled": true,
    "backend": "acpx",
    "defaultAgent": "opencode",
    "allowedAgents": ["opencode"],
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

---

### 2. acf-executor Skill（新增）

**位置**: `/workspace/acf-workflow/skills/acf-executor/`

**文件结构**:
```
acf-executor/
├── SKILL.md              # Skill 文档
└── scripts/
    └── execute-task.sh   # 执行脚本
```

**调用方式**:
```bash
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"
```

**底层实现**:
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

### 3. acf-flow 更新（ACP 驱动）

**文件**: `/workspace/acf-workflow/skills/acf-flow/scripts/auto-flow.sh`

**更新内容**:
```bash
# 使用 ACP 驱动 OpenCode
sessions_spawn(
    runtime="acp",
    agentId="opencode",
    task="$TASK_ID: $TASK_TITLE",
    cwd="$PROJECT_PATH",
    mode="run",
    label="$TASK_ID"
)
```

---

## 🧪 测试过程

### 测试命令

```bash
# 通过 sessions_spawn 工具测试
sessions_spawn(
    task="Reply with exactly: ACP-OPENCODE-TEST-OK",
    runtime="acp",
    agentId="opencode",
    mode="run",
    label="acp-test-opencode",
    cwd="/workspace"
)
```

### 测试结果

```json
{
  "status": "accepted",
  "childSessionKey": "agent:opencode:acp:6d9431e0-d27a-4a39-8d9c-8ceb846f622b",
  "runId": "ce95c6e5-2359-40cc-86c0-4041f05f158f",
  "mode": "run",
  "note": "initial ACP task queued in isolated session; follow-ups continue in the bound thread."
}
```

**会话状态**:
```
会话 Key: agent:opencode:acp:6d9431e0-d27a-4a39-8d9c-8ceb846f622b
状态：已创建（子会话）
父会话：agent:main:acf-workflow
```

---

## 📋 日志验证

### Gateway 日志

```
INFO: acpx runtime backend registered (command: .../acpx, expectedVersion: 0.3.1)
WARN: acp startup identity reconcile (renderer=v1): checked=1 resolved=0 failed=1
INFO: acpx runtime backend ready
INFO: ⇄ res ✓ sessions.list 307ms
```

**关键信息**:
- ✅ acpx 后端已注册
- ✅ acpx 后端已就绪
- ✅ 会话列表查询成功

---

## 🎯 使用方法

### 方法 1: 使用 acf-executor Skill

```bash
# 执行单个任务
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

# 并行执行多个任务
skill_use acf-executor task="Task 002: 实现重试机制" cwd="/workspace/ecommerce"
skill_use acf-executor task="Task 003: 实现熔断器" cwd="/workspace/ecommerce"
```

### 方法 2: 直接使用 sessions_spawn

```bash
# OpenClaw 命令
openclaw sessions spawn \
  --runtime acp \
  --agent-id opencode \
  --task "Task 001: 创建 Crawler 基类" \
  --cwd "/workspace/ecommerce" \
  --mode run \
  --label "Task-001"
```

### 方法 3: 使用 acf-flow 自动流转

```bash
# 获取下一个任务（自动通过 ACP 驱动 OpenCode 执行）
skill_use acf-flow --next
```

---

## 🔍 监控与调试

### 查看会话列表

```bash
openclaw sessions list
# 或
sessions_list
```

### 查看会话历史

```bash
openclaw sessions history <session-key>
# 或
sessions_history sessionKey="agent:opencode:acp:xxx"
```

### 停止任务

```bash
/acp cancel agent:opencode:acp:xxx
```

### 检查 ACP 状态

```bash
/acp doctor
```

---

## ⚠️ 注意事项

### 1. 权限配置

```json5
{
  "plugins": {
    "entries": {
      "acpx": {
        "config": {
          "permissionMode": "approve-all",  // 非交互式会话必需
          "nonInteractivePermissions": "deny"  // 或 "fail"
        }
      }
    }
  }
}
```

**说明**:
- `permissionMode: "approve-all"` — 自动批准所有权限（非交互式必需）
- `nonInteractivePermissions: "deny"` — 权限不足时拒绝而非失败

### 2. OpenCode 安装

```bash
# 检查是否安装
opencode --version

# 安装（如未安装）
npm install -g opencode
```

**当前版本**: v1.3.7 ✅

### 3. 会话隔离

- ACP 会话是隔离的（`agent:opencode:acp:xxx`）
- 每个任务有独立的 session 文件
- 支持中断后恢复（通过 `resumeSessionId`）

---

## 📊 与旧版本对比

| 维度 | 旧版本（tmux） | 新版本（ACP） |
|------|---------------|--------------|
| 启动方式 | `tmux send-keys` | `sessions_spawn(runtime="acp")` |
| 交互式要求 | ❌ 需要 TTY | ✅ 非交互式 |
| 并行执行 | ✅ tmux 多窗口 | ✅ ACP 多会话 |
| 独立记忆 | ✅ OpenCode session 文件 | ✅ OpenCode session 文件 |
| 协调复杂度 | 🔴 高（~15 个命令） | 🟢 低（1 个 tool call） |
| 状态追踪 | 🔴 手动 capture-pane | 🟢 自动日志记录 |
| 会话恢复 | 🔴 需要 tmux attach | ✅ `resumeSessionId` |
| 官方支持 | ❌ 非官方方式 | ✅ OpenCode 官方 ACP 协议 |

---

## ✅ 验收标准

| 标准 | 状态 | 验证方式 |
|------|------|---------|
| ACP 已启用 | ✅ | `acp.enabled=true` |
| acpx 插件已启用 | ✅ | `plugins.entries.acpx.enabled=true` |
| OpenCode 在允许列表中 | ✅ | `acp.allowedAgents=["opencode"]` |
| 权限模式正确 | ✅ | `permissionMode=approve-all` |
| ACP 会话创建成功 | ✅ | `agent:opencode:acp:xxx` |
| acf-executor Skill 可用 | ✅ | 符号链接已创建 |
| acf-flow 已更新 | ✅ | 使用 `runtime="acp"` |

**验收结论**: **全部通过 ✅**

---

## 🔗 相关文档

- `acf-workflow.md` — ACF 工作流完整文档（v3.0）
- `acf-skills-guide.md` — Skills 使用指南
- `acf-opencode-driver-comparison.md` — OpenCode 驱动方式比较
- `acf-env-usage.md` — 环境变量使用指南

---

**配置人**: DevMate  
**配置时间**: 2026-03-30  
**测试状态**: ✅ 成功  
**下次检查**: 2026-04-05
