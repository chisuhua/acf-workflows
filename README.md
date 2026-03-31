# ACF-Workflow — ACP 驱动的双循环工作流

**版本**: v3.1（ACP 驱动 OpenCode 实现）  
**最后更新**: 2026-03-30  
**状态**: 生效中

---

## 📖 简介

ACF-Workflow 是一个**ACP 驱动的双循环工作流**，用于协调 DevMate、老板和编码架构师（OpenCode/Claude Code）之间的高效协作。

**核心理念**:
- **架构循环（慢循环）**: 老板 + DevMate + 编码架构师三方协作，产出架构决策
- **编码循环（快循环）**: DevMate + 编码架构师双方协作，通过 ACP 驱动 OpenCode 执行任务

---

## 🚀 快速开始

### 1. 配置 ACP

```json5
// ~/.openclaw/openclaw.json
{
  "acp": {
    "enabled": true,
    "backend": "acpx",
    "defaultAgent": "opencode",
    "allowedAgents": ["opencode"]
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

### 2. 执行任务

```bash
# 执行任务（ACP 驱动 OpenCode）
skill_use acf-executor task="Task 001: 创建 Crawler 基类" cwd="/workspace/ecommerce"

# 获取下一个任务
skill_use acf-flow --next

# 任务评审
/zcf/task-review "Task 001 完成"      # OpenCode
/zcf:task-review "Task 001 完成"      # Claude Code
```

---

## 📁 项目结构

```
/workspace/acf-workflow/
├── README.md                  # 本文件
├── docs/                      # 文档目录
│   ├── acf-workflow.md        # 工作流完整文档（v3.1）
│   ├── acf-skills-guide.md    # Skills 使用指南（v2.0）
│   ├── acf-quickstart.md      # 快速启动指南（v2.0）
│   ├── acf-acp-setup-complete.md      # ACP 配置与测试报告
│   ├── acf-opencode-driver-comparison.md  # OpenCode 驱动方式比较
│   ├── acf-env-usage.md       # 环境变量使用指南
│   ├── CHANGELOG-v3.1.md      # v3.1 变更日志
│   └── acf-implementation-check.md  # 实现检查报告
├── skills/                    # ACF Skills
│   ├── acf-executor/          # 任务执行（ACP 驱动 OpenCode）
│   ├── acf-flow/              # 任务自动流转
│   ├── acf-status/            # 项目状态分析
│   ├── acf-fix/               # 修复任务创建
│   └── acf-sync/              # 架构文档同步
├── config/                    # 配置文件
│   └── acf-triggers.yaml      # 触发器配置
├── archive/                   # 归档目录
│   ├── zcf-workflow-旧项目/   # 旧版本工作流（tmux 方案）
│   └── old-docs/              # 过时文档
└── templates/                 # 模板文件
    └── domains-config.yaml    # 领域配置模板
```

---

## 📋 核心 Skills

| Skill | 用途 | 调用方式 |
|-------|------|---------|
| `acf-executor` | 任务执行（ACP 驱动 OpenCode） | `skill_use acf-executor task="..."` |
| `acf-flow` | 任务自动流转 | `skill_use acf-flow --next` |
| `acf-status` | 项目状态分析 | `skill_use acf-status [mode]` |
| `acf-fix` | 修复任务创建 | `skill_use acf-fix action=create` |
| `acf-sync` | 架构文档同步 | `skill_use acf-sync` |

---

## 🔗 文档链接

### 核心文档
- **[acf-workflow.md](docs/acf-workflow.md)** — 工作流完整文档（v3.1）
- **[acf-skills-guide.md](docs/acf-skills-guide.md)** — Skills 使用指南（v2.0）
- **[acf-quickstart.md](docs/acf-quickstart.md)** — 快速启动指南（v2.0）

### 技术文档
- **[acf-acp-setup-complete.md](docs/acf-acp-setup-complete.md)** — ACP 配置与测试报告
- **[acf-opencode-driver-comparison.md](docs/acf-opencode-driver-comparison.md)** — OpenCode 驱动方式比较
- **[acf-env-usage.md](docs/acf-env-usage.md)** — 环境变量使用指南
- **[acf-implementation-check.md](docs/acf-implementation-check.md)** — 实现检查报告

### 变更记录
- **[CHANGELOG-v3.1.md](docs/CHANGELOG-v3.1.md)** — v3.1 变更日志

---

## 📊 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v3.1 | 2026-03-30 | ACP 驱动 OpenCode 实现、新增 acf-executor Skill |
| v3.0 | 2026-03-30 | 角色与命令澄清 |
| v2.1 | 2026-03-29 | 任务流转规则、修复任务管理 |
| v2.0 | 2026-03-29 | 权威版（合并 v1.0 + v2.0 草案） |

---

## 🎯 关键特性

### v3.1 新增
- ✅ **ACP 驱动 OpenCode** — 使用 `sessions_spawn(runtime="acp", agentId="opencode")`
- ✅ **acf-executor Skill** — 标准化任务执行接口
- ✅ **触发器支持两种格式** — `/zcf[:/]task-review` 支持 OpenCode 和 Claude Code
- ✅ **多项目支持** — 所有脚本支持环境变量配置

---

## 🛠️ 开发与维护

### 添加新 Skill

```bash
# 创建 Skill 目录
mkdir -p /workspace/acf-workflow/skills/acf-new-skill/scripts

# 创建 SKILL.md
cat > /workspace/acf-workflow/skills/acf-new-skill/SKILL.md << 'EOF'
# ACF New Skill
**用途**: xxx
**调用方式**: skill_use acf-new-skill xxx
EOF

# 创建符号链接
ln -sf /workspace/acf-workflow/skills/acf-new-skill ~/.openclaw/workspace/skills/acf-new-skill
```

### 归档过时文档

```bash
# 创建归档目录
mkdir -p /workspace/acf-workflow/archive/old-docs

# 移动过时文档
mv /workspace/acf-workflow/docs/old-xxx.md /workspace/acf-workflow/archive/old-docs/
```

---

## 📞 支持

- **问题反馈**: 在 `/workspace/mynotes/acf-workflow/` 创建提案
- **文档改进**: 遵循双循环流程（提案→评审→同步→实施）

---

**维护人**: DevMate  
**最后更新**: 2026-03-30  
**版本**: v3.1
