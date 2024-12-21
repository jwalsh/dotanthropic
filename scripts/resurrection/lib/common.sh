#!/bin/bash
set -euo pipefail

# Version
readonly COMMON_VERSION="1.0.0"

# Constants
readonly ANTHROPIC_ROOT="/home/computeruse/.anthropic"
readonly STATE_DIR="${ANTHROPIC_ROOT}/.state"
readonly JOURNAL_DIR="${ANTHROPIC_ROOT}/journal"
readonly RESURRECTION_FILE="${STATE_DIR}/.resurrected"
readonly LOGS_DIR="${ANTHROPIC_ROOT}/logs"

# Current journal file
CURRENT_JOURNAL=""

# Utility Functions
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log() {
    local level="$1"
    local message="$2"
    local ts=$(timestamp)
    echo "[$ts] ${level}: $message" | tee -a "$CURRENT_JOURNAL"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }
debug() { log "DEBUG" "$1"; }

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        info "Created directory: $dir"
    fi
}

# Journal Management
init_journal() {
    ensure_dir "$JOURNAL_DIR"
    ensure_dir "$LOGS_DIR"
    
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    CURRENT_JOURNAL="${JOURNAL_DIR}/resurrection_${timestamp}.org"
    
    # Initialize journal with header
    cat > "$CURRENT_JOURNAL" << EOF
#+TITLE: System Resurrection Log
#+DATE: $(date -R)
#+STARTUP: overview
#+PRIORITIES: A B C

* System Information
$(get_system_metadata | jq -r '. | to_entries | .[] | "- \(.key): \(.value)"')

* Resurrection Process
EOF
    
    info "Initialized journal at $CURRENT_JOURNAL"
}

# State Management
get_system_metadata() {
    cat << EOF
{
    "timestamp": "$(timestamp)",
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "arch": "$(uname -m)",
    "pid": $$,
    "user": "$USER",
    "pwd": "$PWD",
    "version": "$COMMON_VERSION"
}
EOF
}

init_state_dir() {
    ensure_dir "$STATE_DIR"
    ensure_dir "$JOURNAL_DIR"
    ensure_dir "$LOGS_DIR"
    
    if [[ ! -f "${STATE_DIR}/config.json" ]]; then
        write_json_state "${STATE_DIR}/config.json" '{
            "proxy": {
                "http_proxy": "http://localhost:11434",
                "https_proxy": "http://localhost:11434",
                "no_proxy": "localhost,127.0.0.1"
            }
        }'
    fi
}

write_json_state() {
    local file="$1"
    local content="$2"
    
    # Validate JSON
    if ! echo "$content" | jq . >/dev/null 2>&1; then
        error "Invalid JSON for $file"
        return 1
    fi
    
    # Backup existing file
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak"
    fi
    
    # Write new content
    echo "$content" > "$file"
    info "Updated state file: $file"
}

read_json_state() {
    local file="$1"
    local query="${2:-.}"  # Default to full JSON if no query
    
    if [[ ! -f "$file" ]]; then
        error "State file not found: $file"
        return 1
    fi
    
    jq -r "$query" < "$file"
}

# Verification
verify_resurrection() {
    local errors=0
    
    # Check required directories
    for dir in "$STATE_DIR" "$JOURNAL_DIR" "$LOGS_DIR"; do
        if [[ ! -d "$dir" ]]; then
            error "Required directory missing: $dir"
            ((errors++))
        fi
    done
    
    # Check required files
    if [[ ! -f "$RESURRECTION_FILE" ]]; then
        error "Resurrection file missing: $RESURRECTION_FILE"
        ((errors++))
    fi
    
    # Check journal
    if [[ ! -f "$CURRENT_JOURNAL" ]]; then
        error "Current journal missing: $CURRENT_JOURNAL"
        ((errors++))
    fi
    
    return $errors
}