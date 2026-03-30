# ACF 工作流快速启动指南

**版本**: v1.0  
**创建时间**: 2026-03-30  
**用途**: 新项目快速启动 ACF 工作流

---

## 🚀 新项目启动流程

### Step 1: 创建项目目录（5 分钟）

```bash
# 项目根目录
PROJECT_NAME="my-project"

# 创建编码仓库
mkdir -p /workspace/$PROJECT_NAME/{.acf/{status,temp,config},src,tests,docs/architecture}

# 创建提案仓库
mkdir -p /workspace/mynotes/$PROJECT_NAME/docs/architecture/{decisions,reviews,plans}
```

---

### Step 2: 创建配置文件（5 分钟）

```bash
# 复制领域配置模板
cp /workspace/acf-workflow/templates/domains-config.yaml \
   /workspace/mynotes/$PROJECT_NAME/docs/architecture/plans/

# 复制触发器配置
cp /workspace/acf-workflow/config/acf-triggers.yaml \
   /workspace/$PROJECT_NAME/.acf/config/

# 创建项目 AGENTS.md
cat > /workspace/$PROJECT_NAME/AGENTS.md << 'EOF'
# $PROJECT_NAME - ACF 工作流项目

**架构文档位置**: `docs/architecture/`
**ACF 运行时目录**: `.acf/`

## 快速开始

### 查看项目状态
skill_use acf-status mode=brief

### 获取下一个任务
skill_use acf-flow action=next

### 任务评审
/zcf:task-review "Task XXX 完成"
EOF
```

---

### Step 3: 启动慢循环（架构设计）（30-60 分钟）

**参与人**: DevMate + 老板

**流程**:
1. DevMate + 老板讨论架构需求
2. DevMate 创建系统架构设计
3. 老板评审确认
4. 同步到编码仓库

**产出物**:
- `mynotes/$PROJECT_NAME/docs/architecture/YYYY-MM-DD-system-architecture.md`
- `mynotes/$PROJECT_NAME/docs/architecture/plans/domains-config.yaml`
- `mynotes/$PROJECT_NAME/docs/architecture/reviews/YYYY-MM-DD-architecture-review.md`

---

### Step 4: 开始快循环（阶段 1）（2-4 小时）

**流程**:
1. 创建阶段 1 任务计划
2. 执行 Task 001, Task 002, ...
3. 阶段完成后执行阶段审查

**阶段审查**:
- 填写 `docs/architecture/reviews/YYYY-MM-DD-phase-1-review.md`
- 决策：继续快循环 vs 切换到慢循环

---

## 📋 阶段审查检查清单

### 架构一致性（5 项）

- [ ] 模块结构一致
- [ ] 接口设计一致
- [ ] 数据流正确
- [ ] 依赖关系正确
- [ ] 错误处理符合策略

### 实现质量（4 项）

- [ ] 测试覆盖率 >80%
- [ ] 测试通过率 100%
- [ ] 代码质量良好
- [ ] 文档完整

### 架构调整需求（4 项）

- [ ] 无需求变更
- [ ] 无技术选型变更
- [ ] 无架构缺陷
- [ ] 无扩展需求

**全部通过** → ✅ 继续快循环  
**任一不通过** → ❌ 切换到慢循环

---

## 🔀 切换到慢循环的条件

满足以下**任一条件**即切换到慢循环：

1. ❌ 架构缺陷（严重）
2. ❌ 技术选型变更
3. ❌ 需求重大变更（>30%）
4. ❌ 新增模块
5. ❌ 老板决策

---

## 📁 项目目录结构

```
/workspace/$PROJECT_NAME/
├── .acf/                           # ACF 运行时
│   ├── status/                     # 状态追踪
│   ├── temp/                       # 临时文件（任务计划）
│   └── config/                     # 配置（触发器）
├── src/                            # 源代码
├── tests/                          # 测试代码
└── docs/architecture/              # 架构文档（只读，从 mynotes 同步）

/workspace/mynotes/$PROJECT_NAME/
└── docs/architecture/              # 架构讨论（提案仓库）
    ├── decisions/                  # ADR
    ├── reviews/                    # 评审报告
    └── plans/                      # 计划（领域配置、任务计划）
```

---

## 🎯 关键决策点

| 决策点 | 决策人 | 决策依据 |
|--------|--------|---------|
| 架构设计确认 | 老板 | 业务需求、技术可行性 |
| 阶段审查结论 | DevMate + 老板 | 审查检查清单 |
| 切换到慢循环 | 老板 | 严重架构问题 |

---

## 📄 模板文件

| 模板 | 位置 | 用途 |
|------|------|------|
| 领域配置 | `acf-workflow/templates/domains-config.yaml` | 配置支持的领域 |
| 触发器配置 | `acf-workflow/config/acf-triggers.yaml` | 自动触发规则 |
| 审查报告 | `acf-workflow/docs/phase-review-process.md` | 阶段审查模板 |

---

## 🚀 快速命令参考

```bash
# 查看项目状态
skill_use acf-status mode=brief

# 获取下一个任务
skill_use acf-flow action=next

# 任务评审
/zcf:task-review "Task XXX 完成"

# 同步架构文档
skill_use acf-sync

# 创建修复任务
skill_use acf-fix action=create summary="问题描述"
```

---

**维护人**: DevMate  
**最后更新**: 2026-03-30  
**适用项目**: 所有使用 ACF 工作流的新项目
