#!/bin/bash
# Initialize system state
STATE_DIR="/home/computeruse/.anthropic/.state"
mkdir -p "$STATE_DIR"

# Initialize state files
touch "$STATE_DIR/agents.json"
touch "$STATE_DIR/config.json"
touch "$STATE_DIR/status.json"

echo "State initialization complete"