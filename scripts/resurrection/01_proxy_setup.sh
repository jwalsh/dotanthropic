#!/bin/bash
# Configure and verify proxy settings

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Proxy-specific constants
PROXY_URL="http://localhost:11434"
HEALTH_ENDPOINT="${PROXY_URL}/api/health"

# Configure proxy
export HTTP_PROXY="${PROXY_URL}"
export HTTPS_PROXY="${HTTP_PROXY}"
export NO_PROXY="localhost,127.0.0.1"

# Read proxy config if exists
PROXY_CONFIG="$STATE_DIR/config.json"
if [[ -f "$PROXY_CONFIG" ]]; then
    info "Loading proxy configuration from $PROXY_CONFIG"
    HTTP_PROXY="$(read_json_state "$PROXY_CONFIG" .proxy.http_proxy)"
    HTTPS_PROXY="$(read_json_state "$PROXY_CONFIG" .proxy.https_proxy)"
    NO_PROXY="$(read_json_state "$PROXY_CONFIG" .proxy.no_proxy)"
fi

# Verify proxy with timeout and retry
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
    info "Verifying proxy configuration (attempt $attempt/$max_attempts)"
    if timeout 10s curl -s -x "$HTTP_PROXY" "$HEALTH_ENDPOINT" >/dev/null; then
        # Update state with successful configuration
        write_json_state "${STATE_DIR}/proxy_status.json" "{
            \"status\": \"configured\",
            \"timestamp\": \"$(timestamp)\",
            \"config\": {
                \"http_proxy\": \"$HTTP_PROXY\",
                \"https_proxy\": \"$HTTPS_PROXY\",
                \"no_proxy\": \"$NO_PROXY\"
            }
        }"
        info "Proxy configuration successful"
        exit 0
    fi
    
    warn "Proxy verification failed, attempt $attempt"
    ((attempt++))
    sleep 2
done

error "Proxy configuration failed after $max_attempts attempts"
exit 1