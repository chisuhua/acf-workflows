#!/bin/bash
# claims.sh — Claims 管理库（防重复 Spawn 机制）
# 用法：source scripts/lib/claims.sh

set -e

# 环境变量（可被调用方覆盖）
CLAIMS_FILE="${CLAIMS_FILE:-.acf/temp/claims.json}"

# 确保 claims 目录存在
claims_init() {
    local claims_dir="$(dirname "$CLAIMS_FILE")"
    mkdir -p "$claims_dir"
    if [ ! -f "$CLAIMS_FILE" ]; then
        echo "{}" > "$CLAIMS_FILE"
    fi
}

# 清理过期 claims
# 参数：timeout_minutes（可选，默认 120）
cleanup_claims() {
    local timeout_minutes="${1:-120}"
    local cutoff=$(date -u -d "$timeout_minutes minutes ago" +%Y-%m-%dT%H:%M:%SZ)
    
    claims_init
    
    local claims=$(cat "$CLAIMS_FILE" | jq --arg cutoff "$cutoff" '
        to_entries | map(select(.value.expires_at > $cutoff)) | from_entries
    ')
    echo "$claims" > "$CLAIMS_FILE"
    
    # 返回清理结果
    local count=$(echo "$claims" | jq 'length')
    echo "$count"
}

# 检查 claim 是否存在
# 参数：task_id
# 返回：0=存在，1=不存在
check_claim() {
    local task_id="$1"
    
    claims_init
    
    if jq -e --arg id "$task_id" '.[$id]' "$CLAIMS_FILE" > /dev/null 2>&1; then
        # 存在，输出详情
        local agent_id=$(jq -r --arg id "$task_id" '.[$id].agent_id' "$CLAIMS_FILE")
        local started_at=$(jq -r --arg id "$task_id" '.[$id].started_at' "$CLAIMS_FILE")
        echo "exists:$agent_id:$started_at"
        return 0
    fi
    
    echo "not_exists"
    return 1
}

# 写入 claim
# 参数：task_id, agent_id, timeout_minutes（可选）
write_claim() {
    local task_id="$1"
    local agent_id="$2"
    local timeout_minutes="${3:-120}"
    
    claims_init
    
    local started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local expires_at=$(date -u -d "+$timeout_minutes minutes" +%Y-%m-%dT%H:%M:%SZ)
    
    local claims=$(cat "$CLAIMS_FILE" | jq --arg id "$task_id" \
        --arg agent "$agent_id" \
        --arg start "$started_at" \
        --arg end "$expires_at" \
        '.[$id] = {"agent_id": $agent, "started_at": $start, "expires_at": $end, "status": "executing"}')
    echo "$claims" > "$CLAIMS_FILE"
    
    echo "✅ Claim 已写入：$task_id → $agent_id (expires: $expires_at)"
}

# 释放 claim（任务完成后）
# 参数：task_id
release_claim() {
    local task_id="$1"
    
    claims_init
    
    local claims=$(cat "$CLAIMS_FILE" | jq --arg id "$task_id" 'del(.[$id])')
    echo "$claims" > "$CLAIMS_FILE"
    
    echo "✅ Claim 已释放：$task_id"
}

# 更新 claim 状态
# 参数：task_id, status
update_claim_status() {
    local task_id="$1"
    local status="$2"
    
    claims_init
    
    local claims=$(cat "$CLAIMS_FILE" | jq --arg id "$task_id" \
        --arg status "$status" \
        '.[$id].status = $status')
    echo "$claims" > "$CLAIMS_FILE"
}

# 获取 claim 详情
# 参数：task_id
get_claim() {
    local task_id="$1"
    
    claims_init
    
    jq -r --arg id "$task_id" '.[$id] // empty' "$CLAIMS_FILE"
}

# 列出所有活跃 claims
list_claims() {
    claims_init
    cat "$CLAIMS_FILE" | jq -r 'to_entries[] | "\(.key): \(.value.agent_id) (\(.value.status))"'
}

# 统计活跃 claims 数量
count_claims() {
    claims_init
    cat "$CLAIMS_FILE" | jq 'length'
}

# 检查任务是否可执行（无 claim 且未过期）
# 参数：task_id, timeout_minutes（可选）
# 返回：0=可执行，1=不可执行
can_execute() {
    local task_id="$1"
    local timeout_minutes="${2:-120}"
    
    claims_init
    
    # 清理过期 claims
    cleanup_claims "$timeout_minutes" > /dev/null
    
    # 检查是否存在
    local result=$(check_claim "$task_id")
    if [[ "$result" == exists:* ]]; then
        return 1  # 已在处理中
    fi
    
    return 0  # 可执行
}
