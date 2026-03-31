# ACF-Workflow 配置示例

**版本**: v1.0  
**创建时间**: 2026-04-01  
**维护人**: DevMate

---

## ~/.openclaw/config.json 配置示例

```json5
{
  // ACP 配置
  acp: {
    enabled: true,
    backend: "acpx",
    defaultAgent: "opencode",
    allowedAgents: ["opencode", "codex", "claude"],
    maxConcurrentSessions: 4
  },
  
  // ACF-Workflow 配置
  acf: {
    executor: {
      // 最大并发数（非关键任务并行执行时）
      maxConcurrent: 4,
      
      // claim 过期时间（分钟），超时自动释放
      claimTimeoutMinutes: 120,
      
      // 关键任务标记值（任务计划表中"关键"列的值）
      criticalTaskMarker: ["是", "true", "yes", "critical"]
    },
    flow: {
      // 关键任务执行后强制评审
      requireReviewAfterCritical: true,
      
      // 非关键任务批量评审阈值
      batchReviewThreshold: 3
    }
  },
  
  // 插件配置
  plugins: {
    entries: {
      acpx: {
        enabled: true,
        config: {
          permissionMode: "approve-all",
          nonInteractivePermissions: "deny"
        }
      }
    }
  },
  
  // Skills 配置
  skills: {
    load: {
      extraDirs: [
        "~/.agents/skills",
        "/workspace/acf-workflow/skills"
      ]
    }
  },
  
  // Cron 配置（定时清理 claims）
  cron: {
    jobs: [
      {
        "name": "cleanup-claims",
        "schedule": { "kind": "cron", "expr": "0 * * * *" },
        "payload": {
          "kind": "systemEvent",
          "text": "bash /workspace/acf-workflow/scripts/cleanup-claims.sh"
        },
        "sessionTarget": "isolated",
        "delivery": { "mode": "none" },
        "enabled": true
      }
    ]
  }
}
```

---

## 配置说明

### acf.executor.maxConcurrent

**说明**: 非关键任务并行执行时的最大并发数

**默认值**: 4

**建议值**:
- 小型项目：2-4
- 中型项目：4-6
- 大型项目：6-8（需足够系统资源）

---

### acf.executor.claimTimeoutMinutes

**说明**: claim 过期时间（分钟），超时自动释放

**默认值**: 120（2 小时）

**建议值**:
- 短任务为主：60-90
- 长任务为主：120-180
- 混合任务：120

**计算方式**: `过期时间 = 任务预计耗时 × 2`

---

### acf.executor.criticalTaskMarker

**说明**: 关键任务标记值（任务计划表中"关键"列的值）

**默认值**: `["是", "true", "yes", "critical"]`

**任务计划表示例**:
```markdown
| Task ID | 任务名称 | 依赖 | 并行组 | 关键 | 状态 |
|---------|---------|------|--------|------|------|
| Task 001 | 创建 Crawler 基类 | 无 | group-A | 是 | pending |
| Task 002 | 实现重试机制 | 无 | group-A | 否 | pending |
```

---

### cron.jobs（cleanup-claims）

**说明**: 定时清理过期 claims

**执行频率**: 每小时（`0 * * * *`）

**作用**:
- 清理因异常退出未释放的 claims
- 防止 claims.json 无限增长
- 释放被占用的任务 ID

**手动执行**:
```bash
bash /workspace/acf-workflow/scripts/cleanup-claims.sh
```

---

## 配置检查命令

```bash
# 检查 ACP 配置
openclaw config show acp.enabled
openclaw config show acp.allowedAgents

# 检查 ACF 配置
openclaw config show acf.executor.maxConcurrent
openclaw config show acf.executor.claimTimeoutMinutes

# 检查 Cron 配置
openclaw cron list
```

---

## 配置变更流程

1. **编辑配置文件**
   ```bash
   # 方式 A: 直接编辑
   vim ~/.openclaw/config.json
   
   # 方式 B: 使用命令
   openclaw config set acf.executor.maxConcurrent 4
   ```

2. **验证配置**
   ```bash
   openclaw config show acf.executor
   ```

3. **重启 Gateway**（如需要）
   ```bash
   openclaw gateway restart
   ```

---

**版本**: v1.0  
**创建时间**: 2026-04-01  
**维护人**: DevMate
