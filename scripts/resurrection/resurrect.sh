#!/bin/bash
# Master resurrection script for AYGP system
# Executes all resurrection scripts in order

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOG_DIR="/home/computeruse/.anthropic/logs"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$LOG_DIR/resurrection_$TIMESTAMP.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log "Starting system resurrection process"
log "Logging to: $LOG_FILE"

# Create required directories if they don't exist
mkdir -p "/home/computeruse/.anthropic/.state"
mkdir -p "/home/computeruse/.anthropic/journal"

# Execute all numbered scripts in order
for script in "$SCRIPT_DIR"/[0-9][0-9]_*.sh; do
    if [[ "$script" == *"*"* ]]; then
        log "No resurrection scripts found"
        exit 1
    fi
    if [ -x "$script" ]; then
        script_name=$(basename "$script")
        log "Executing $script_name"
        
        "$script" 2>&1 | tee -a "$LOG_FILE"
        exit_code=${PIPESTATUS[0]}
        
        # Special case for 00_check_resurrection.sh - exit code 1 means resurrection needed
        if [[ "$script_name" == "00_check_resurrection.sh" && $exit_code -eq 1 ]]; then
            log "Proceeding with resurrection process"
            continue
        elif [ $exit_code -ne 0 ]; then
            log "ERROR: $script_name failed with exit code $exit_code"
            log "Resurrection process aborted"
            exit $exit_code
        fi
        
        log "Successfully completed $script_name"
    else
        log "WARNING: $script is not executable, skipping"
    fi
done

log "Resurrection process completed successfully"

# Final verification
if [ -f "/home/computeruse/.anthropic/.state/.resurrected" ]; then
    log "System successfully resurrected"
    log "Resurrection timestamp: $(cat /home/computeruse/.anthropic/.state/.resurrected)"
    exit 0
else
    log "ERROR: Resurrection verification failed"
    exit 1
fi