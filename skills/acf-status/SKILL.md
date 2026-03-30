# ZCF Status Skill

**技能名称**: `acf-status`  
**用途**: 分析项目状态，生成进度报告  
**调用方式**: `skill_use acf-status [full|brief|next]`

---

## 功能

- 检查同步状态（SYNC-REPORT.md）
- 分析架构文档完成度
- 检查编码进度（源代码/测试文件数）
- 追踪架构问题（temp/arch-issues.md）
- 生成状态报告（完整/简要/仅下一步）

---

## 输入参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `mode` | str | ❌ | 报告模式：`full`（默认）/`brief`/`next` |
| `project_path` | str | ❌ | 项目路径（默认 `/workspace/ecommerce`） |

---

## 输出格式

### 完整模式（full）

```markdown
# 项目状态报告

**生成时间**: 2026-03-29 12:00
**项目**: /workspace/ecommerce

---

## 📊 总体状态

| 维度 | 状态 | 说明 |
|------|------|------|
| 同步状态 | 🟢 最新 | 最后同步：2026-03-29 08:00 |
| 架构文档 | 🟢 完整 | 主文档 + 4 个 ADR |
| 编码进度 | 🟡 进行中 | 阶段 2，进度 67% |
| 架构问题 | ✅ 无 | 无阻塞问题 |

**总体进度**: 67%

---

## 📄 架构文档状态
...

## 💻 编码进度
...

## 🎯 下一步建议
...
```

### 简要模式（brief）

```markdown
## 📊 项目状态简报

**生成时间**: 2026-03-29 12:00
**总体进度**: 67%

| 维度 | 状态 |
|------|------|
| 同步状态 | 🟢 最新 |
| 架构文档 | 🟢 完整 |
| 编码进度 | 🟡 进行中 |
| 架构问题 | ✅ 无 |

**下一步**: `skill_use acf-flow --next-task`
```

### 仅下一步（next）

```markdown
## 🎯 下一步建议

### 立即执行
```bash
skill_use acf-flow --next-task
```

### 后续步骤
1. 执行 Task 008
2. 完成后 `/zcf:task-review "Task 008 完成"`
```

---

## 使用示例

### 示例 1: 完整状态报告

```bash
skill_use acf-status mode=full
```

### 示例 2: 简要状态

```bash
skill_use acf-status mode=brief
```

### 示例 3: 仅下一步

```bash
skill_use acf-status mode=next
```

---

## 实现细节

**封装脚本**: `scripts/generate-status.sh`

**核心逻辑**:
```bash
#!/bin/bash
# generate-status.sh

PROJECT_PATH="${1:-/workspace/ecommerce}"
MODE="${2:-full}"

# 1. 检查同步状态
if [ -f "$PROJECT_PATH/docs/architecture/SYNC-REPORT.md" ]; then
    SYNC_STATUS="🟢 最新"
    SYNC_TIME=$(grep "同步时间" "$PROJECT_PATH/docs/architecture/SYNC-REPORT.md" | cut -d':' -f2-)
else
    SYNC_STATUS="❌ 缺失"
    SYNC_TIME="N/A"
fi

# 2. 检查架构文档
DOC_COUNT=$(find "$PROJECT_PATH/docs/architecture" -name "*.md" | wc -l)
if [ $DOC_COUNT -ge 10 ]; then
    DOC_STATUS="🟢 完整"
else
    DOC_STATUS="🟡 部分"
fi

# 3. 检查编码进度
SRC_COUNT=$(find "$PROJECT_PATH/src" -name "*.py" 2>/dev/null | wc -l)
TEST_COUNT=$(find "$PROJECT_PATH/tests" -name "*.py" 2>/dev/null | wc -l)

# 4. 检查架构问题
if [ -f "$PROJECT_PATH/temp/arch-issues.md" ]; then
    ISSUES=$(grep -c "❌ 严重" "$PROJECT_PATH/temp/arch-issues.md" 2>/dev/null || echo 0)
    if [ $ISSUES -gt 0 ]; then
        ISSUE_STATUS="🔴 有阻塞"
    else
        ISSUE_STATUS="🟡 有待评审"
    fi
else
    ISSUE_STATUS="✅ 无"
fi

# 5. 生成报告
case $MODE in
    full)
        generate_full_report
        ;;
    brief)
        generate_brief_report
        ;;
    next)
        generate_next_report
        ;;
esac
```

---

## 触发调用

### 每日定时触发

```yaml
# ~/.openclaw/config/acf-triggers.yaml
triggers:
  - name: daily-status
    condition: cron "0 9 * * *"  # 每日 9:00
    action: skill_use acf-status mode=brief
    target: feishu  # 发送到飞书
```

### 阶段完成后触发

```yaml
triggers:
  - name: phase-completed
    condition: /zcf:task-review 阶段完成
    action: skill_use acf-status mode=full
```

---

## 错误处理

| 错误 | 处理方式 |
|------|---------|
| 项目路径不存在 | 返回错误提示，建议检查路径 |
| 无架构文档 | 返回"准备期"状态 |
| 无源代码 | 返回"未开始"状态 |

---

## 相关 Skills

- `acf-flow` - 任务流转（下一步执行）
- `acf-sync` - 同步架构文档
- `acf-fix` - 修复任务创建

---

**版本**: v1.0  
**创建时间**: 2026-03-29  
**状态**: 已创建
