# ZCF Fix Skill

**技能名称**: `acf-fix`  
**用途**: 创建修复任务（P0/P1/P2 问题）  
**调用方式**: `skill_use acf-fix --create <问题摘要>`

---

## 功能

- 从评审报告提取 P0/P1/P2 问题
- 创建修复任务（`Fix-XXX`）
- 更新任务计划（插入修复任务）
- 追踪修复状态

---

## 输入参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `action` | str | ❌ | 动作：`create`（默认）/`list`/`status` |
| `priority` | str | ❌ | 优先级：`P0`/`P1`/`P2`（默认从问题识别） |
| `summary` | str | ❌ | 问题摘要 |
| `source_review` | str | ❌ | 来源评审报告路径 |

---

## 输出格式

### 创建修复任务

```markdown
## ✅ 修复任务已创建

**任务 ID**: Fix-001
**优先级**: P0（阻塞后续任务）
**问题摘要**: Mock Fixture 路径错误（3 处测试）
**来源评审**: `docs/architecture/reviews/2026-03-29-task-001-review.md`

### 修复内容
- 修复 `test_crawl_taobao_mock` 的 Mock 路径
- 修复 `test_crawl_jd_mock` 的 Mock 路径
- 修复 `test_crawl_playwright_not_installed` 的 Mock 路径

### 验收标准
- 3 个 Mock 测试通过
- 无其他测试失败

### 执行命令
```bash
task(
    category="deep",
    prompt="Fix-001: 修复 Mock Fixture 路径错误",
    load_skills=["subagent-driven-development"]
)
```

### 任务插入位置
- 插入到 `temp/phase1-tasks.md` 顶部
- 标记为"阻塞 Task 002"

---

**状态**: 准备执行 → 执行后运行 `/zcf:task-review "Fix-001 完成"`
```

### 列出修复任务

```markdown
## 📋 修复任务列表

| 任务 ID | 优先级 | 问题摘要 | 状态 | 来源评审 |
|--------|--------|---------|------|---------|
| Fix-001 | P0 | Mock Fixture 路径错误 | 🔄 进行中 | task-001-review |
| Fix-002 | P1 | 测试断言精度问题 | ⏸️ 待开始 | task-001-review |

**P0 任务**: 1 个（阻塞后续任务）
**P1 任务**: 1 个
**P2 任务**: 0 个
```

---

## 使用示例

### 示例 1: 创建修复任务

```bash
skill_use acf-fix action=create summary="Mock Fixture 路径错误" source_review="docs/architecture/reviews/2026-03-29-task-001-review.md"
```

### 示例 2: 列出修复任务

```bash
skill_use acf-fix action=list
```

### 示例 3: 查看修复状态

```bash
skill_use acf-fix action=status task_id="Fix-001"
```

---

## 实现细节

**封装脚本**: `scripts/create-fix-task.sh`

**核心逻辑**:
```bash
#!/bin/bash
# create-fix-task.sh

PRIORITY="${1:-auto}"
SUMMARY="${2:-未指定}"
SOURCE_REVIEW="${3:-}"

# 生成 Fix-XXX 编号
FIX_COUNT=$(grep -c "Fix-" temp/fix-tasks.md 2>/dev/null || echo 0)
FIX_ID=$(printf "Fix-%03d" $((FIX_COUNT + 1)))

# 自动识别优先级（从评审报告）
if [ "$PRIORITY" = "auto" ] && [ -n "$SOURCE_REVIEW" ]; then
    if grep -q "❌ 严重\|P0" "$SOURCE_REVIEW"; then
        PRIORITY="P0"
    elif grep -q "⚠️ 中等\|P1" "$SOURCE_REVIEW"; then
        PRIORITY="P1"
    else
        PRIORITY="P2"
    fi
fi

# 创建修复任务记录
cat >> temp/fix-tasks.md << EOF
### $FIX_ID

- **优先级**: $PRIORITY
- **问题摘要**: $SUMMARY
- **来源评审**: $SOURCE_REVIEW
- **状态**: 待开始
- **创建时间**: $(date +'%Y-%m-%d %H:%M')
- **阻塞任务**: $(identify_blocked_tasks)

EOF

# 插入到任务计划顶部
insert_to_plan_top "$FIX_ID" "$SUMMARY" "$PRIORITY"

echo "✅ 修复任务 $FIX_ID 已创建"
```

---

## 触发调用

### 评审发现 P0 问题时自动触发

```yaml
# ~/.openclaw/config/acf-triggers.yaml
triggers:
  - name: p0-issue-found
    condition: /zcf:task-review 发现 P0 问题
    action: skill_use acf-fix --create --auto-priority
```

---

## 修复任务管理流程

```
评审发现 P0 问题
    ↓
自动触发 acf-fix
    ↓
创建 Fix-XXX 任务
    ↓
插入到任务计划顶部（阻塞后续）
    ↓
执行修复
    ↓
重新运行相关测试
    ↓
测试通过 → 关闭 Fix-XXX
    ↓
恢复原任务流转
```

---

## 相关 Skills

- `acf-reviewer` - 任务评审（发现问题）
- `acf-flow` - 任务流转（修复后恢复）
- `acf-status` - 状态追踪（显示修复任务）

---

**版本**: v1.0  
**创建时间**: 2026-03-29  
**状态**: 已创建
