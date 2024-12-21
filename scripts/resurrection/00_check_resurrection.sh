#!/bin/bash
# Check if system needs resurrection

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize journal at the start
init_journal

if [ -f "$RESURRECTION_FILE" ]; then
    info "System already resurrected ($(read_json_state "$RESURRECTION_FILE" .timestamp))"
    exit 0
else
    info "System needs resurrection"
    init_state_dir
    exit 1
fi