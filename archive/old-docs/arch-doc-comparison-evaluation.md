# 架构文档生成方式对比评估报告

**评估时间**: 2026-03-29 18:45  
**评估对象**: 手动生成 vs /zcf:arch-doc 生成  
**评估目的**: 确定两种方式的协作机制

---

## 一、两种方式的详细对比

### 方式 A: DevMate 手动生成（当前做法）

**执行流程**:
```
1. DevMate 理解需求
2. DevMate 分析架构要点
3. 使用 write 工具直接创建文档
4. 老板 Review 确认
5. 手动同步到编码仓库
```

**产出物示例**:
```
/workspace/mynotes/agent-news/docs/architecture/
├── 2026-03-29-agent-news-system-architecture.md  (5600 字)
├── 2026-03-29-crawler-module-design.md          (8992 字)
├── 2026-03-29-processor-module-design.md        (7596 字)
└── 2026-03-29-storage-module-design.md          (12484 字)
```

**优点**:
- ✅ 灵活性强，可根据项目特点调整结构
- ✅ 支持多方案对比和讨论
- ✅ 即时决策记录
- ✅ 适合架构讨论（慢循环）

**缺点**:
- ❌ 依赖 DevMate 经验，质量不稳定
- ❌ 文档结构不一致
- ❌ 需要手动同步到编码仓库
- ❌ 无法利用 OpenCode 的能力

---

### 方式 B: /zcf:arch-doc 生成（OpenCode 执行）

**执行流程**:
```
1. DevMate 调用/zcf:arch-doc 命令
2. OpenCode 读取架构需求
3. OpenCode 按模板生成文档
4. DevMate Review 调整
5. 自动保存到正确位置
```

**预期产出物**:
```
/workspace/agent-news/docs/architecture/
├── 2026-03-29-agent-news.md
└── phases/
    └── phase-1-mvp/
        ├── crawler/
        │   ├── detailed-design.md
        │   └── api-spec.md
        ├── processor/
        │   └── detailed-design.md
        └── storage/
            └── detailed-design.md
```

**优点**:
- ✅ 按模板生成，结构标准化
- ✅ 自动保存到正确位置
- ✅ 利用 OpenCode 能力
- ✅ 适合详细设计（快循环）

**缺点**:
- ❌ 结构固定，不够灵活
- ❌ 不支持多方案对比
- ❌ 不适合架构讨论

---

## 二、关键发现：两者定位不同

### 定位对比

| 维度 | 手动生成 | /zcf:arch-doc |
|------|---------|--------------|
| **适用阶段** | 慢循环（架构讨论） | 快循环（详细设计） |
| **执行者** | DevMate | OpenCode |
| **文档类型** | 系统架构、方案设计 | 模块详细设计、API 规范 |
| **灵活性** | 高 | 低（模板约束） |
| **标准化** | 低 | 高 |
| **讨论支持** | ✅ 支持 | ❌ 不支持 |

### 结论

**两种方式不是竞争关系，是互补关系**：
- **手动生成** → 用于慢循环架构讨论
- **/zcf:arch-doc** → 用于快循环详细设计

---

## 三、推荐的协作机制

### 3.1 慢循环 → 快循环 文档流转

```
┌─────────────────────────────────────────────────────────────┐
│ 慢循环（架构讨论）                                           │
│ DevMate 手动创建：                                           │
│ - 系统架构设计                                               │
│ - 模块设计方案                                               │
│ - 技术选型决策                                               │
│                                                             │
│ 产出：/workspace/mynotes/agent-news/docs/architecture/      │
│       - 2026-03-29-agent-news-system-architecture.md        │
│       - 2026-03-29-crawler-module-design.md (设计思路)       │
└─────────────────────────────────────────────────────────────┘
                            ↓ 架构定稿 + 老板确认
                            ↓ 同步到编码仓库
┌─────────────────────────────────────────────────────────────┐
│ 快循环（详细设计）                                           │
│ OpenCode 调用/zcf:arch-doc 生成：                            │
│ - 模块详细设计文档                                           │
│ - API 规范文档                                               │
│ - 数据库设计文档                                             │
│                                                             │
│ 产出：/workspace/agent-news/docs/architecture/              │
│       - phases/phase-1/crawler/detailed-design.md           │
│       - phases/phase-1/crawler/api-spec.md                  │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 文档层级对应关系

| 慢循环文档（手动） | 快循环文档（/zcf:arch-doc） | 关系 |
|------------------|--------------------------|------|
| 系统架构设计 | 模块详细设计 | 指导关系 |
| 模块设计方案 | API 规范 | 细化关系 |
| 技术选型决策 | 数据库设计 | 实现关系 |

**慢循环文档** 是 **快循环文档** 的输入和约束

---

## 四、架构调整流程设计

### 场景 1: 小调整（不影响架构决策）

**适用**: 接口参数调整、实现细节变更

```
快循环中直接调用/zcf:arch-doc 更新:
  ↓
/zcf:arch-doc "更新爬虫模块 API 规范"
  ↓
OpenCode 自动更新详细设计文档
  ↓
记录到 CHANGELOG
```

**无需**同步回提案仓库

---

### 场景 2: 中等调整（影响模块设计）

**适用**: 模块接口变更、新增功能

```
1. DevMate 在提案仓库更新模块设计方案
   ↓
2. 老板确认调整方案
   ↓
3. 手动同步到编码仓库
   ↓
4. 调用/zcf:arch-doc 重新生成详细设计
   ↓
/zcf:arch-doc "阶段 1：爬虫模块详细设计"
```

---

### 场景 3: 重大调整（影响系统架构）

**适用**: 架构风格变更、技术选型变更

```
1. 暂停快循环
   ↓
2. 返回慢循环（架构讨论）
   ↓
3. DevMate + 老板讨论新方案
   ↓
4. 更新系统架构设计（手动）
   ↓
5. 评审通过
   ↓
6. 同步到编码仓库
   ↓
7. 恢复快循环
   ↓
8. 调用/zcf:arch-doc 重新生成所有详细设计
```

---

## 五、避免直接拷贝的方案

### 当前问题

**现状**: 手动 `cp` 同步文档
```bash
cp /workspace/mynotes/agent-news/docs/architecture/*.md \
   /workspace/agent-news/docs/architecture/
```

**问题**:
- 容易遗漏
- 无法追踪版本
- 可能覆盖快循环生成的文档

---

### 推荐方案：使用 acf-sync + /zcf:arch-doc 组合

**步骤 1: 慢循环文档同步**
```bash
skill_use acf-sync
```
仅同步**系统架构**和**模块设计方案**（慢循环文档）

**步骤 2: 快循环文档生成**
```bash
/zcf:arch-doc "阶段 1：爬虫模块详细设计"
/zcf:arch-doc "阶段 1：处理模块详细设计"
/zcf:arch-doc "阶段 1：存储模块详细设计"
```
OpenCode 按模板生成**详细设计文档**

**好处**:
- 避免直接拷贝
- 慢循环文档约束快循环文档
- 快循环文档标准化

---

## 六、文档版本管理

### 版本号规则

```
慢循环文档：YYYY-MM-DD-<描述>-v1.md
快循环文档：detailed-design.md (按模板，无日期)
```

### 变更追踪

| 文档类型 | 变更追踪方式 |
|---------|------------|
| 慢循环文档 | 文件名带日期，保留历史版本 |
| 快循环文档 | Git 提交历史追踪 |

---

## 七、实施建议

### 7.1 立即执行

1. **保留手动生成的架构文档**（慢循环产出）
2. **在编码仓库调用/zcf:arch-doc 生成详细设计**（快循环输入）
3. **更新 ADR-001** 明确两种方式的协作机制

### 7.2 文档结构优化

**慢循环文档**（提案仓库）:
```
/workspace/mynotes/agent-news/docs/architecture/
├── 2026-03-29-system-architecture.md      # 系统架构
├── 2026-03-29-crawler-design.md           # 模块设计方案
├── 2026-03-29-processor-design.md         # 模块设计方案
└── 2026-03-29-storage-design.md           # 模块设计方案
```

**快循环文档**（编码仓库）:
```
/workspace/agent-news/docs/architecture/
├── system-architecture.md                 # 从慢循环同步
└── phases/phase-1-mvp/
    ├── crawler/
    │   ├── detailed-design.md             # /zcf:arch-doc 生成
    │   └── api-spec.md                    # /zcf:arch-doc 生成
    ├── processor/
    │   └── detailed-design.md             # /zcf:arch-doc 生成
    └── storage/
        └── detailed-design.md             # /zcf:arch-doc 生成
```

---

## 八、评估结论

### 结论 1: 两种方式都有价值

| 方式 | 价值 | 适用场景 |
|------|------|---------|
| 手动生成 | 灵活性、讨论支持 | 慢循环架构讨论 |
| /zcf:arch-doc | 标准化、自动化 | 快循环详细设计 |

**建议**: 两者结合使用，不是二选一

---

### 结论 2: 需要明确的边界

| 阶段 | 使用方式 | 文档类型 |
|------|---------|---------|
| 慢循环 | DevMate 手动生成 | 系统架构、方案设计 |
| 快循环 | /zcf:arch-doc 生成 | 详细设计、API 规范 |
| 架构调整（小） | /zcf:arch-doc 直接更新 | 详细设计 |
| 架构调整（中） | 手动更新 + /zcf:arch-doc 重新生成 | 方案设计 + 详细设计 |
| 架构调整（大） | 返回慢循环 | 系统架构 |

---

### 结论 3: 避免直接拷贝的方案可行

**方案**: `skill_use acf-sync` + `/zcf:arch-doc` 组合

**流程**:
1. acf-sync 同步慢循环文档（系统架构）
2. /zcf:arch-doc 生成快循环文档（详细设计）
3. 慢循环文档约束快循环文档

---

**评估人**: DevMate  
**评估时间**: 2026-03-29 18:45  
**建议**: 采纳组合方案，更新 ADR-001
