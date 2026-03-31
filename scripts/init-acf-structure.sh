#!/bin/bash
# init-acf-structure.sh — 初始化 ACF 项目目录结构
# 用法：./init-acf-structure.sh <project-path>

set -e

PROJECT_PATH="${1:-.}"
ACF_DIR="$PROJECT_PATH/.acf"

echo "🔧 初始化 ACF 目录结构：$PROJECT_PATH"

# 创建目录结构
mkdir -p "$ACF_DIR/status"
mkdir -p "$ACF_DIR/temp/task-plans"
mkdir -p "$ACF_DIR/config"

# 复制模板文件
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

if [ -f "$TEMPLATE_DIR/current-task-template.md" ]; then
    cp "$TEMPLATE_DIR/current-task-template.md" "$ACF_DIR/status/current-task.md"
    echo "✅ 创建 current-task.md"
else
    cat > "$ACF_DIR/status/current-task.md" << 'EOF'
# 当前任务状态

**项目**: {{Project-Name}}
**更新时间**: YYYY-MM-DD HH:MM:SS

## 任务进度
| 任务 ID | 状态 | 完成时间 | 评审状态 |
|---------|------|---------|---------|
| Task 001 | ⏳ 待执行 | - | - |

## 下一步
**任务**: Task 001
**执行命令**: `skill_use acf-executor task="Task 001" cwd="$PROJECT_PATH"`
EOF
    echo "✅ 创建 current-task.md（简化版）"
fi

# 创建触发器配置（如不存在）
if [ ! -f "$ACF_DIR/config/acf-triggers.yaml" ]; then
    cat > "$ACF_DIR/config/acf-triggers.yaml" << 'EOF'
# ACF 触发器配置（项目级）
# 继承全局配置：/workspace/acf-workflow/config/acf-triggers.yaml

triggers:
  - name: daily-status
    condition:
      type: cron
      expression: "0 9 * * *"
    action:
      type: skill
      name: acf-status
      params:
        mode: brief
    enabled: true
EOF
    echo "✅ 创建 acf-triggers.yaml"
fi

# 创建任务计划模板（如不存在）
if [ ! -f "$ACF_DIR/temp/task-plans/phase1-tasks.md" ]; then
    cat > "$ACF_DIR/temp/task-plans/phase1-tasks.md" << 'EOF'
# Phase 1 任务计划

| 任务 ID | 任务名称 | 优先级 | 状态 | 负责人 |
|---------|---------|--------|------|--------|
| Task 001 | {{任务名称}} | P0 | ⏳ 待执行 | OpenCode |

## 任务详情

### Task 001
- **描述**: ...
- **交付物**: ...
- **验收标准**: ...
EOF
    echo "✅ 创建 phase1-tasks.md（模板）"
fi

echo ""
echo "✅ ACF 目录结构初始化完成"
echo ""
echo "目录结构:"
find "$ACF_DIR" -type f | sort
echo ""
echo "下一步:"
echo "1. 编辑 $ACF_DIR/status/current-task.md 填写项目信息"
echo "2. 编辑 $ACF_DIR/temp/task-plans/phase1-tasks.md 添加任务计划"
echo "3. 运行 skill_use acf-status mode=brief 查看状态"
