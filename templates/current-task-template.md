# 当前任务状态

**项目**: {{Project-Name}}
**更新时间**: YYYY-MM-DD HH:MM:SS
**最后更新任务**: Task XXX

---

## 状态机（P0 新增）

**当前状态**: `{{STATE}}`  ← 可选值：`IDLE` | `EXECUTING` | `WAITING_REVIEW` | `BLOCKED` | `DONE` | `INTERVIEW`

**允许转换**:
```
IDLE → EXECUTING | INTERVIEW
EXECUTING → WAITING_REVIEW | BLOCKED
WAITING_REVIEW → EXECUTING | DONE | BLOCKED
BLOCKED → INTERVIEW | EXECUTING
DONE → IDLE | EXECUTING
INTERVIEW → EXECUTING | IDLE
```

**最后状态转换**: `{{PREV_STATE}}` → `{{STATE}}` (YYYY-MM-DD HH:MM:SS)

**恢复上下文**（Gateway Restart 用）:
- **下一步动作**: `{{NEXT_ACTION}}`  ← 直接可执行命令
- **阻塞原因**: `{{BLOCK_REASON}}`  ← 仅 BLOCKED 状态填写

---

## 任务进度

| 任务 ID | 任务名称 | 状态 | 完成时间 | 评审状态 |
|---------|---------|------|---------|---------|
| Task 001 | {{任务名称}} | ✅ 完成 | HH:MM | ✅ 通过 |
| Task 002 | {{任务名称}} | ✅ 完成 | HH:MM | ✅ 通过 |
| Task 003 | {{任务名称}} | 🔄 进行中 | - | - |
| Task 004 | {{任务名称}} | ⏳ 待执行 | - | - |
| Task 005 | {{任务名称}} | ⏳ 待执行 | - | - |

**进度**: 2/5 (40%)

---

## 当前阶段

**阶段**: Phase X - {{阶段名称}}
**阶段目标**: {{一句话描述}}
**阻塞点**: 无 / {{描述}}

---

## 架构状态

| 检查项 | 状态 | 文件位置 |
|--------|------|---------|
| 架构文档 | ✅ 已定稿 / 🟡 草稿 / ❌ 缺失 | `docs/architecture/` |
| 同步状态 | ✅ 最新 / ⚠️ 待同步 | `docs/architecture/SYNC-REPORT.md` |
| 待评审 ADR | 无 / {{ADR-XXX}} | `docs/architecture/decisions/` |

---

## 需求澄清状态

| 检查项 | 状态 | 记录位置 |
|--------|------|---------|
| 交付物格式 | ✅ 明确 / 🛑 待确认 | `memory/YYYY-MM-DD.md` |
| 技术选型 | ✅ 明确 / 🛑 待确认 | `memory/YYYY-MM-DD.md` |
| 优先级 | ✅ 明确 / 🛑 待确认 | `memory/YYYY-MM-DD.md` |
| 范围边界 | ✅ 明确 / 🛑 待确认 | `memory/YYYY-MM-DD.md` |

---

## 下一步

### 立即执行
**任务**: Task XXX - {{任务名称}}
**验收标准**:
- [ ] 标准 1
- [ ] 标准 2
- [ ] 标准 3

**预计耗时**: XX 分钟
**执行命令**:
```bash
skill_use acf-executor task="Task XXX: {{任务名称}}" cwd="/workspace/{{Project}}"
```

### 后续任务
1. Task XXX+1 - {{任务名称}}
2. Task XXX+2 - {{任务名称}}

---

## 执行日志（今日）

| 时间 | 事件 | 备注 |
|------|------|------|
| HH:MM | Task 001 开始 | - |
| HH:MM | Task 001 完成，提交评审 | - |
| HH:MM | Task 001 评审通过 | 无偏差 |
| HH:MM | Task 002 开始 | - |

---

**模板使用说明**:
1. 复制此模板到 `<Project>/.acf/status/current-task.md`
2. 替换 `{{xxx}}` 占位符为实际内容
3. 每次任务状态变更时更新此文件
4. Gateway Restart 后读取此文件恢复进展
