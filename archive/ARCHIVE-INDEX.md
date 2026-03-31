# ACF-Workflow 归档索引

**归档时间**: 2026-03-30  
**归档原因**: 清理过时、重复或不再适用的文档

---

## 📁 归档目录结构

```
archive/
├── zcf-workflow-旧项目/           # 旧版本工作流（tmux 方案）
│   ├── docs/
│   │   ├── architecture/         # 旧架构文档
│   │   ├── decisions/            # 旧 ADR
│   │   └── guides/               # 旧指南（含 tmux 速查表）
│   ├── templates/                 # 旧模板
│   └── scripts/                   # 旧脚本
└── old-docs/                      # 过时文档（v3.1 之前）
    ├── acf-cleanup-*.md           # 清理相关文档
    ├── acf-migration-*.md         # 迁移相关文档
    ├── acf-workflow-summary.md    # 旧总结
    ├── acf-workflow-arch-review.md # 架构评审
    ├── acf-workflow-file-map.md   # 文件映射
    ├── acf-ecommerce-case-study.md # 电商案例
    ├── acf-ready-checklist.md     # 准备清单
    ├── acf-improvement-plan.md    # 改进计划
    ├── arch-doc-comparison-evaluation.md # 架构文档比较
    ├── phase-review-process.md    # 阶段评审流程
    └── adr-001-slow-cycle-human-collaboration.md # ADR-001
```

---

## 📋 归档文件清单

### archive/zcf-workflow-旧项目/ （旧版本工作流）

**归档时间**: 2026-03-29  
**归档原因**: tmux 方案已被 ACP 方案替代，不再使用

| 文件 | 用途 | 替代文档 |
|------|------|---------|
| `docs/architecture/WORKFLOW-DESIGN.md` | 旧工作流设计 | `docs/acf-workflow.md` (v3.1) |
| `docs/architecture/MULTI-AGENT.md` | 多 Agent 协作指南 | `docs/acf-workflow.md` §3 |
| `docs/architecture/MULTI-AGENT-TRIAL-REPORT.md` | 多 Agent 试用报告 | `docs/acf-opencode-driver-comparison.md` |
| `docs/architecture/ADR-003-multi-agent-architecture.md` | tmux+OpenCode 架构决策 | `docs/acf-opencode-driver-comparison.md` |
| `docs/guides/TMUX-CHEATSHEET.md` | tmux 速查表 | 不再使用（ACP 方案无需 tmux） |
| `docs/guides/QUICKSTART.md` | 旧快速启动指南 | `docs/acf-quickstart.md` (v2.0) |
| `templates/task-prompt.md` | 旧任务 Prompt 模板 | 内置于 `/zcf/arch-doc` 技能 |
| `templates/task-handoff.md` | 旧交接清单 | 不再使用（ACP 有独立记忆） |

---

### archive/old-docs/ （过时文档）

**归档时间**: 2026-03-30  
**归档原因**: 内容已过时、重复或被新文档替代

| 文件 | 原用途 | 替代文档 | 归档原因 |
|------|--------|---------|---------|
| `acf-cleanup-complete.md` | 清理完成报告 | - | 临时文档，已完成 |
| `acf-cleanup-final.md` | 最终清理报告 | - | 临时文档，已完成 |
| `acf-cleanup-legacy.md` | 遗留清理报告 | - | 临时文档，已完成 |
| `acf-migration-plan.md` | 迁移计划 | - | 临时文档，已完成 |
| `acf-migration-complete.md` | 迁移完成报告 | - | 临时文档，已完成 |
| `acf-workflow-summary.md` | 工作流总结 | `README.md` + `CHANGELOG-v3.1.md` | 内容已整合 |
| `acf-workflow-arch-review.md` | 架构评审报告 | `docs/acf-implementation-check.md` | 内容已过时 |
| `acf-workflow-file-map.md` | 文件映射 | `README.md` §项目结构 | 内容已整合 |
| `acf-ecommerce-case-study.md` | 电商案例复盘 | - | 案例特定，非通用文档 |
| `acf-ready-checklist.md` | 准备清单 | `docs/acf-quickstart.md` | 内容已整合 |
| `acf-improvement-plan.md` | 改进计划 | `CHANGELOG-v3.1.md` | 改进已完成 |
| `arch-doc-comparison-evaluation.md` | 架构文档比较 | `docs/acf-opencode-driver-comparison.md` | 内容已更新 |
| `phase-review-process.md` | 阶段评审流程 | `docs/acf-workflow.md` §3.2.3 | 内容已整合 |
| `adr-001-slow-cycle-human-collaboration.md` | ADR-001（慢循环） | `docs/acf-workflow.md` §1.1 | 内容已整合 |
| `verify-acf-migration.sh` | 迁移验证脚本 | - | 临时脚本，已完成 |

---

## 🎯 当前有效文档

### 核心文档（3 个）
- ✅ `docs/acf-workflow.md` — 工作流完整文档（v3.1）
- ✅ `docs/acf-skills-guide.md` — Skills 使用指南（v2.0）
- ✅ `docs/acf-quickstart.md` — 快速启动指南（v2.0）

### 技术文档（4 个）
- ✅ `docs/acf-acp-setup-complete.md` — ACP 配置与测试报告
- ✅ `docs/acf-opencode-driver-comparison.md` — OpenCode 驱动方式比较
- ✅ `docs/acf-env-usage.md` — 环境变量使用指南
- ✅ `docs/acf-implementation-check.md` — 实现检查报告

### 变更记录（1 个）
- ✅ `docs/CHANGELOG-v3.1.md` — v3.1 变更日志

### 配置文件（1 个）
- ✅ `config/acf-triggers.yaml` — 触发器配置

### 模板文件（1 个）
- ✅ `templates/domains-config.yaml` — 领域配置模板

---

## 📊 归档统计

| 类别 | 数量 | 说明 |
|------|------|------|
| **归档文件** | ~25 个 | 旧版本工作流 + 过时文档 |
| **有效文档** | 10 个 | 核心文档 + 技术文档 + 变更记录 |
| **Skills** | 5 个 | acf-executor, acf-flow, acf-status, acf-fix, acf-sync |
| **精简率** | ~71% | (25/35) 文档已归档 |

---

## 🔍 如何查找归档内容

### 按主题查找

**tmux 方案相关**:
```bash
find archive/zcf-workflow-旧项目 -name "*tmux*" -o -name "*MULTI-AGENT*"
```

**架构决策相关**:
```bash
find archive/zcf-workflow-旧项目/docs/decisions -name "ADR-*.md"
```

**清理迁移相关**:
```bash
find archive/old-docs -name "*cleanup*" -o -name "*migration*"
```

### 按时间查找

**2026-03-28 之前**:
```bash
find archive/zcf-workflow-旧项目 -type f -mtime +2
```

**2026-03-29 临时文档**:
```bash
ls archive/old-docs/acf-cleanup-* archive/old-docs/acf-migration-*
```

---

## ⚠️ 使用注意

1. **归档文档仅供参考** — 不要基于归档文档执行操作
2. **使用最新文档** — 始终参考 `docs/` 目录下的最新文档
3. **历史追溯** — 如需了解决策历史，可查阅归档的 ADR 和评审报告

---

**归档人**: DevMate  
**归档时间**: 2026-03-30  
**下次整理**: 2026-04-05（或文档数量超过 20 个时）
