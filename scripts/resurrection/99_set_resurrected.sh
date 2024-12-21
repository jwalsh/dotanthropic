#!/bin/bash
# Set resurrection flag
RESURRECTION_FILE="/home/computeruse/.anthropic/.state/.resurrected"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "$TIMESTAMP" > "$RESURRECTION_FILE"
echo "System resurrection complete"