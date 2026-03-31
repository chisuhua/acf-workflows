# ACF-Workflow 环境变量使用指南

**版本**: v1.0  
**创建时间**: 2026-03-30  
**用途**: 多项目支持配置指南

---

## 📋 概述

ACF-Workflow 所有脚本和 Skills 都支持环境变量配置，可以在多个项目之间复用，无需修改代码。

---

## 🔧 支持的环境变量

### 全局变量

| 变量 | 说明 | 默认值 | 适用脚本 |
|------|------|--------|---------|
| `PROJECT_PATH` | 项目根目录 | `/workspace/ecommerce` | 所有脚本 |
| `TEMP_DIR` | 临时文件目录 | `$PROJECT_PATH/temp` | auto-flow, create-fix-task |

### acf-status

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PROJECT_PATH` | 项目根目录 | `/workspace/ecommerce` |
| `MODE` | 报告模式 | `full` |

### acf-flow

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PROJECT_PATH` | 项目根目录 | `/workspace/ecommerce` |
| `TEMP_DIR` | 临时文件目录 | `$PROJECT_PATH/temp` |

### acf-sync

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PROPOSAL_ROOT` | 提案仓库路径 | `/workspace/mynotes/SkillApps/ecommerce/docs/architecture` |
| `ENCODING_ROOT` | 编码仓库路径 | `/workspace/ecommerce/docs/architecture` |
| `DRY_RUN` | 是否仅预览 | `false` |

### acf-fix

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PROJECT_PATH` | 项目根目录 | `/workspace/ecommerce` |
| `TEMP_DIR` | 临时文件目录 | `$PROJECT_PATH/temp` |

---

## 🚀 使用方法

### 方法 1: 命令行临时设置

```bash
# 单次执行，临时设置环境变量
PROJECT_PATH=/workspace/my-project skill_use acf-status mode=brief

# 多个变量
PROJECT_PATH=/workspace/my-project \
PROPOSAL_ROOT=/workspace/mynotes/my-project/docs/architecture \
skill_use acf-sync
```

---

### 方法 2: 导出到当前会话

```bash
# 导出变量（当前终端会话有效）
export PROJECT_PATH=/workspace/my-project
export PROPOSAL_ROOT=/workspace/mynotes/my-project/docs/architecture
export ENCODING_ROOT=/workspace/my-project/docs/architecture

# 然后正常使用
skill_use acf-status
skill_use acf-flow
skill_use acf-sync
```

---

### 方法 3: 添加到 shell 配置文件

```bash
# 编辑 ~/.bashrc 或 ~/.zshrc
echo 'export PROJECT_PATH=/workspace/my-project' >> ~/.bashrc
echo 'export PROPOSAL_ROOT=/workspace/mynotes/my-project/docs/architecture' >> ~/.bashrc
echo 'export ENCODING_ROOT=/workspace/my-project/docs/architecture' >> ~/.bashrc

# 重新加载
source ~/.bashrc
```

---

### 方法 4: 在项目目录创建 .env 文件

```bash
# 在项目根目录创建 .env 文件
cat > /workspace/my-project/.env << 'EOF'
PROJECT_PATH=/workspace/my-project
PROPOSAL_ROOT=/workspace/mynotes/my-project/docs/architecture
ENCODING_ROOT=/workspace/my-project/docs/architecture
EOF

# 使用时 source
source /workspace/my-project/.env
```

---

## 📁 多项目示例

### 项目 A：电商系统

```bash
# 设置环境变量
export PROJECT_PATH=/workspace/ecommerce
export PROPOSAL_ROOT=/workspace/mynotes/SkillApps/ecommerce/docs/architecture
export ENCODING_ROOT=/workspace/ecommerce/docs/architecture

# 使用
skill_use acf-status mode=brief
skill_use acf-flow --next
skill_use acf-sync
```

---

### 项目 B：新的 AI 项目

```bash
# 设置环境变量
export PROJECT_PATH=/workspace/ai-assistant
export PROPOSAL_ROOT=/workspace/mynotes/SkillApps/ai-assistant/docs/architecture
export ENCODING_ROOT=/workspace/ai-assistant/docs/architecture

# 使用
skill_use acf-status mode=brief
skill_use acf-flow --next
skill_use acf-sync
```

---

### 项目 C：快速切换

```bash
# 使用函数快速切换项目
switch-project() {
    export PROJECT_PATH=/workspace/$1
    export PROPOSAL_ROOT=/workspace/mynotes/SkillApps/$1/docs/architecture
    export ENCODING_ROOT=/workspace/$1/docs/architecture
    echo "切换到项目：$1"
}

# 使用
switch-project ecommerce
skill_use acf-status

switch-project ai-assistant
skill_use acf-status
```

---

## 🔍 脚本使用示例

### auto-flow.sh

```bash
# 默认（使用 PROJECT_PATH 环境变量）
./auto-flow.sh

# 指定参数
./auto-flow.sh phase1 Task-001

# 指定项目路径
PROJECT_PATH=/workspace/my-project ./auto-flow.sh
```

---

### generate-status.sh

```bash
# 默认模式（full）
./generate-status.sh

# 指定模式
./generate-status.sh brief
./generate-status.sh next

# 指定项目
PROJECT_PATH=/workspace/my-project ./generate-status.sh full
```

---

### sync-arch-to-encoding.sh

```bash
# 正常同步
./sync-arch-to-encoding.sh

# 预览（dry-run）
./sync-arch-to-encoding.sh --dry-run

# 列出可同步文件
./sync-arch-to-encoding.sh --list

# 指定路径
PROPOSAL_ROOT=/workspace/mynotes/my-project/docs/architecture \
ENCODING_ROOT=/workspace/my-project/docs/architecture \
./sync-arch-to-encoding.sh
```

---

### create-fix-task.sh

```bash
# 创建修复任务（自动识别优先级）
./create-fix-task.sh create auto "问题描述" "评审报告路径.md"

# 创建修复任务（指定 P0）
./create-fix-task.sh create P0 "严重问题" "评审报告路径.md"

# 列出修复任务
./create-fix-task.sh list

# 查看任务状态
./create-fix-task.sh status Fix-001

# 指定项目
PROJECT_PATH=/workspace/my-project ./create-fix-task.sh list
```

---

## ⚠️ 注意事项

### 1. 环境变量优先级

```
命令行参数 > 环境变量 > 默认值
```

示例：
```bash
# MODE 环境变量设置为 brief
export MODE=brief

# 但命令行参数优先
./generate-status.sh full  # 使用 full 模式
```

---

### 2. 路径必须存在

```bash
# 错误：路径不存在
export PROJECT_PATH=/workspace/nonexistent
skill_use acf-status  # ❌ 报错

# 正确：先创建目录
mkdir -p /workspace/my-project/{src,tests,docs/architecture,temp}
export PROJECT_PATH=/workspace/my-project
skill_use acf-status  # ✅ 正常
```

---

### 3. 临时目录自动创建

```bash
# TEMP_DIR 不需要预先创建
# 脚本会自动创建必要的子目录

export PROJECT_PATH=/workspace/my-project
# temp/ 目录会在需要时自动创建
```

---

## 📊 完整示例：新项目启动

```bash
# 1. 创建项目目录
PROJECT_NAME="my-new-project"
mkdir -p /workspace/$PROJECT_NAME/{src,tests,docs/architecture,temp}
mkdir -p /workspace/mynotes/SkillApps/$PROJECT_NAME/docs/architecture/{decisions,reviews,plans}

# 2. 设置环境变量
export PROJECT_PATH=/workspace/$PROJECT_NAME
export PROPOSAL_ROOT=/workspace/mynotes/SkillApps/$PROJECT_NAME/docs/architecture
export ENCODING_ROOT=/workspace/$PROJECT_NAME/docs/architecture
export TEMP_DIR=$PROJECT_PATH/temp

# 3. 验证配置
echo "项目路径：$PROJECT_PATH"
echo "提案仓库：$PROPOSAL_ROOT"
echo "编码仓库：$ENCODING_ROOT"

# 4. 开始使用
skill_use acf-status mode=brief  # 应该显示"未开始"状态

# 5. 创建架构文档（DevMate 手工）
# ... 在 $PROPOSAL_ROOT 创建草稿 ...

# 6. 同步到编码仓库
skill_use acf-sync

# 7. 开始任务流转
skill_use acf-flow --next
```

---

## 🔗 相关文档

- `acf-workflow.md` - ACF 工作流完整文档
- `acf-skills-guide.md` - Skills 使用指南
- `acf-quickstart.md` - 快速启动指南
- `acf-implementation-check.md` - 实现检查报告

---

**维护人**: DevMate  
**最后更新**: 2026-03-30  
**版本**: v1.0
