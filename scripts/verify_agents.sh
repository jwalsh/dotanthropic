#!/bin/bash

# Set the API endpoint
API_ENDPOINT="http://localhost:11434/api/generate"

# Function to get a simple, non-streaming response from a model
get_model_response() {
  local model=$1
  local prompt=$2

  curl -s -x $HTTP_PROXY -X POST \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"options\":{\"stream\":false}}" \
    "$API_ENDPOINT" | jq -r '.response'
}

# Define the agents and their corresponding prompts
agents=(
  "jwalsh/coordinator:latest"
  "jwalsh/jwalsh:latest"
  "jwalsh/technical-writer:latest"
  "jwalsh/emma:latest"
  "jwalsh/jihye:latest"
)

prompts=(
  "Decompose this task: 'Design a new user interface for a mobile banking app.'"
  "Implement a Python function to calculate the factorial of a number."
  "Write a short user manual for a new smart home thermostat."
  "Brainstorm innovative features for a social media platform that promotes mental well-being."
  "Critically evaluate the following claim: 'Artificial intelligence will inevitably surpass human intelligence within the next decade.'"
)

# Loop through the agents and get responses
for i in "${!agents[@]}"; do
  agent="${agents[$i]}"
  prompt="${prompts[$i]}"

  echo "Agent: $agent"
  echo "Prompt: $prompt"
  response=$(get_model_response "$agent" "$prompt")
  echo "Response: $response"
  echo "--------------------"
done
