# ZCF Flow Skill

**技能名称**: `acf-flow`  
**用途**: 任务自动流转（读取计划 → 执行下一个 Task）  
**调用方式**: `skill_use acf-flow [--next] [--task XXX]`

---

## 功能

- 读取任务计划（`phase*-tasks.md`）
- 识别下一个待执行任务
- 生成任务执行 Prompt
- 触发任务执行（调用 `acf-executor` 或 OpenCode）

---

## 输入参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--parallel` | bool | ❌ | 是否并行执行非关键任务（默认 false） |
| `--max-concurrent` | int | ❌ | 最大并发数（默认：配置值或 4） |

## 并行执行策略（P3 新增）

**关键任务**: 串行执行 → 立即评审 → 决策点

**非关键任务**: 并行执行（最多 max-concurrent 个）→ 批量评审

**任务计划格式**:
```markdown
| Task ID | 任务名称 | 依赖 | 并行组 | 关键 | 状态 |
|---------|---------|------|--------|------|------|
| Task 001 | 创建 Crawler 基类 | 无 | group-A | 是 | pending |
| Task 002 | 实现重试机制 | 无 | group-A | 否 | pending |
```

**使用示例**:
```bash
# 串行执行（默认）
skill_use acf-flow

# 并行执行（关键任务串行，非关键任务并行）
skill_use acf-flow --parallel

# 指定最大并发数
skill_use acf-flow --parallel --max-concurrent 2
```

---

## 输出格式

### 下一个任务

```markdown
## 📋 下一个任务

**任务 ID**: Task 008
**任务名称**: 编排 Agent
**优先级**: P0
**预计耗时**: 45 分钟

### 交付物
- `~/.agents/agents/ecommerce/orchestrator.md`

### 验收标准
- 能解析用户意图
- 能正确分派任务给对应 Skill
- 支持并行执行多个 Skill

### 执行命令
```bash
task(
    category="deep",
    prompt="Task 008: 编排 Agent",
    load_skills=["subagent-driven-development"]
)
```

### 架构上下文
- 主文档：`docs/architecture/2026-03-26-ecommerce-analysis-system.md`
- ADR 约束：ADR-001, ADR-002

---

**状态**: 准备执行 → 执行后运行 `/zcf:task-review "Task 008 完成"`
```

### 无更多任务

```markdown
## ✅ 当前阶段任务全部完成

**阶段**: 阶段 2
**完成时间**: 2026-03-29 09:00

### 下一步建议

1. 执行阶段评审
   ```bash
   /zcf:task-review "阶段 2 完成"
   ```

2. 规划下一阶段
   ```bash
   skill_use acf-architect "阶段 3：集成测试架构"
   ```
```

---

## 使用示例

### 示例 1: 获取下一个任务

```bash
skill_use acf-flow
```

### 示例 2: 获取指定任务

```bash
skill_use acf-flow task_id="Task 008"
```

### 示例 3: 获取指定阶段的任务

```bash
skill_use acf-flow phase=phase2
```

---

## 实现细节

**封装脚本**: `scripts/auto-flow.sh`

**核心逻辑**:
```bash
#!/bin/bash
# auto-flow.sh

PHASE="${1:-auto}"
TASK_ID="${2:-next}"

# 1. 查找任务计划文件
PLAN_FILE=$(find /workspace/ecommerce/temp -name "phase*-tasks.md" | head -1)

# 2. 解析任务状态
if [ "$TASK_ID" = "next" ]; then
    # 查找第一个状态为 pending/in_progress 的任务
    NEXT_TASK=$(grep -A 5 "| Task" "$PLAN_FILE" | grep -E "pending|in_progress" | head -1)
    TASK_ID=$(echo "$NEXT_TASK" | awk -F'|' '{print $2}' | xargs)
fi

# 3. 提取任务详情
TASK_TITLE=$(grep "^### $TASK_ID" "$PLAN_FILE" -A 10 | grep "任务名称" | cut -d':' -f2)
DELIVERABLES=$(grep "^### $TASK_ID" "$PLAN_FILE" -A 20 | grep "交付物" -A 5)

# 4. 生成执行 Prompt
cat << EOF
## 任务：$TASK_ID - $TASK_TITLE

$DELIVERABLES

### 执行命令
task(
    category="deep",
    prompt="$TASK_ID: $TASK_TITLE",
    load_skills=["subagent-driven-development"]
)
EOF
```

---

## 触发调用

### Task 评审通过后自动触发

```yaml
# ~/.openclaw/config/acf-triggers.yaml
triggers:
  - name: task-completed
    condition: /zcf:task-review 评审通过
    action: skill_use acf-flow --next
```

---

## 错误处理

| 错误 | 处理方式 |
|------|---------|
| 任务计划文件不存在 | 返回"无任务计划，请先创建" |
| 所有任务已完成 | 返回"阶段完成"提示 |
| 指定任务不存在 | 返回错误，列出可用任务 |

---

## 相关 Skills

- `acf-executor` - 任务执行
- `acf-reviewer` - 任务评审
- `acf-fix` - 修复任务创建

---

**版本**: v1.0  
**创建时间**: 2026-03-29  
**状态**: 已创建
