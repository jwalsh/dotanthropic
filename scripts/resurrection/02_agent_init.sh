#!/bin/bash
# Initialize and verify agent connectivity

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Agent configuration
declare -A AGENTS=(
    ["coordinator"]="jwalsh/coordinator:latest"
    ["implementation"]="jwalsh/jwalsh:latest"
    ["documentation"]="jwalsh/technical-writer:latest"
    ["innovation"]="jwalsh/emma:latest"
    ["analysis"]="jwalsh/jihye:latest"
)

# Initialize agents state
AGENTS_STATE="${STATE_DIR}/agents.json"
write_json_state "$AGENTS_STATE" '{"agents": {}, "timestamp": null}'

info "Starting agent initialization"

# Initialize agents
failed_agents=0
for agent_name in "${!AGENTS[@]}"; do
    image="${AGENTS[$agent_name]}"
    info "Initializing $agent_name agent ($image)"
    
    # Verify agent health
    if timeout 10s curl -s -x "$HTTP_PROXY" "http://localhost:11434/api/agents/${agent_name}/health" >/dev/null; then
        # Update agent status in state
        temp_file=$(mktemp)
        jq --arg name "$agent_name" \
           --arg image "$image" \
           --arg ts "$(timestamp)" \
           '.agents[$name] = {"image": $image, "status": "ready", "timestamp": $ts}' \
           "$AGENTS_STATE" > "$temp_file" && mv "$temp_file" "$AGENTS_STATE"
        
        info "Successfully initialized $agent_name"
    else
        error "Failed to initialize $agent_name"
        # Update agent status as failed
        temp_file=$(mktemp)
        jq --arg name "$agent_name" \
           --arg image "$image" \
           --arg ts "$(timestamp)" \
           '.agents[$name] = {"image": $image, "status": "failed", "timestamp": $ts}' \
           "$AGENTS_STATE" > "$temp_file" && mv "$temp_file" "$AGENTS_STATE"
        ((failed_agents++))
    fi
done

# Update final timestamp
write_json_state "$AGENTS_STATE" "$(jq --arg ts "$(timestamp)" '. + {"timestamp": $ts}' "$AGENTS_STATE")"

if [ $failed_agents -eq 0 ]; then
    info "All agents initialized successfully"
    exit 0
else
    error "$failed_agents agent(s) failed to initialize"
    exit 1
fi