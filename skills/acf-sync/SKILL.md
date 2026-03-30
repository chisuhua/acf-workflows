# ZCF Sync Skill

**技能名称**: `acf-sync`  
**用途**: 同步提案仓库架构文档到编码仓库  
**调用方式**: `skill_use acf-sync [--dry-run] [--list]`

---

## 功能

- 检查提案仓库定稿文档
- 生成同步列表
- 执行同步（复制文档）
- 生成同步报告（SYNC-REPORT.md）

---

## 输入参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `dry_run` | bool | ❌ | 是否仅预览（默认 False） |
| `list` | bool | ❌ | 是否仅显示同步列表 |
| `proposal_root` | str | ❌ | 提案仓库路径（默认 `/workspace/mynotes/SkillApps/ecommerce/docs/architecture`） |
| `encoding_root` | str | ❌ | 编码仓库路径（默认 `/workspace/ecommerce/docs/architecture`） |

---

## 输出格式

### 执行成功

```markdown
## ✅ 同步完成

**同步时间**: 2026-03-29 13:00
**源目录**: /workspace/mynotes/.../architecture
**目标目录**: /workspace/ecommerce/docs/architecture

### 同步文件列表
- ecommerce.md
- decisions/ADR-001.md
- decisions/ADR-002.md
- plans/implementation-plan.md

**同步文件数**: 4

### 下一步
1. 验证同步：`ls -la /workspace/ecommerce/docs/architecture/`
2. 提交变更：`cd /workspace/ecommerce && git add . && git commit -m 'sync: 架构文档更新'`
3. 通知编码助手：@OpenCode 架构文档已更新
```

### Dry-run 模式

```markdown
## 🔍 同步预览（Dry-run）

**源目录**: /workspace/mynotes/.../architecture
**目标目录**: /workspace/ecommerce/docs/architecture

### 预计同步文件
- ecommerce.md
- decisions/ADR-001.md

**预计文件数**: 2

执行真实同步：`skill_use acf-sync`（不加 --dry-run）
```

---

## 使用示例

### 示例 1: 执行同步

```bash
skill_use acf-sync
```

### 示例 2: 预览同步

```bash
skill_use acf-sync dry_run=true
```

### 示例 3: 显示同步列表

```bash
skill_use acf-sync list=true
```

---

## 实现细节

**封装脚本**: `scripts/sync-arch-to-encoding.sh`

**核心逻辑**:
```bash
#!/bin/bash
# sync-arch-to-encoding.sh

PROPOSAL_ROOT="${1:-/workspace/mynotes/SkillApps/ecommerce/docs/architecture}"
ENCODING_ROOT="${2:-/workspace/ecommerce/docs/architecture}"
DRY_RUN="${3:-false}"

# 1. 检查源目录
if [ ! -d "$PROPOSAL_ROOT" ]; then
    echo "❌ 错误：提案仓库目录不存在"
    exit 1
fi

# 2. 生成同步列表（标记"可同步"的文档）
SYNC_LIST=$(find "$PROPOSAL_ROOT" -name "*.md" -type f | grep -E "(已发布|已采纳|可同步)")

# 3. 逐文件同步
for file in $SYNC_LIST; do
    rel_path="${file#$PROPOSAL_ROOT/}"
    target_file="$ENCODING_ROOT/$rel_path"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "[预览] 同步：$rel_path"
    else
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
        echo "✅ 同步：$rel_path"
    fi
done

# 4. 生成同步报告
if [ "$DRY_RUN" = "false" ]; then
    cat > "$ENCODING_ROOT/SYNC-REPORT.md" << EOF
# 架构文档同步报告

**同步时间**: $(date +'%Y-%m-%d %H:%M:%S')
**源目录**: $PROPOSAL_ROOT
**目标目录**: $ENCODING_ROOT

## 同步文件列表
$(echo "$SYNC_LIST" | sed "s|$PROPOSAL_ROOT/||")

## 下一步
1. 验证同步
2. 提交变更
3. 通知编码助手
EOF
fi
```

---

## 触发调用

### 架构评审通过后触发

```yaml
# ~/.openclaw/config/acf-triggers.yaml
triggers:
  - name: arch-review-passed
    condition: /zcf:task-review 架构评审通过
    action: skill_use acf-sync
```

---

## 错误处理

| 错误 | 处理方式 |
|------|---------|
| 提案仓库不存在 | 返回错误，建议检查路径 |
| 编码仓库不存在 | 自动创建目录 |
| 无定稿文档 | 返回"无需要同步的文档" |
| 同步失败 | 回滚已同步文件，返回错误 |

---

## 相关 Skills

- `acf-status` - 检查同步状态
- `acf-architect` - 架构文档开发
- `acf-flow` - 同步后继续任务流转

---

**版本**: v1.0  
**创建时间**: 2026-03-29  
**状态**: 已创建
