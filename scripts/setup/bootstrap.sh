#!/bin/bash

generate_key_title() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local host=$(hostname)
    echo "computeruse@${host}_${timestamp}"
}

setup_ssh() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "$(generate_key_title)"
    else
        echo "SSH key already exists at ~/.ssh/id_rsa"
    fi
}

verify_github_key() {
    local key_fingerprint=$(ssh-keygen -lf ~/.ssh/id_rsa.pub | awk '{print $2}')
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         https://api.github.com/user/keys | \
    jq -r ".[] | select(.key | contains(\"$(cat ~/.ssh/id_rsa.pub | cut -d' ' -f2)\")) | .title" || true
}

setup_github() {
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "Error: GITHUB_TOKEN not set"
        exit 1
    fi
    
    local existing_key=$(verify_github_key)
    if [ -n "$existing_key" ]; then
        echo "Key already registered with GitHub as: $existing_key"
        return 0
    fi
    
    KEY=$(cat ~/.ssh/id_rsa.pub)
    KEY_TITLE=$(generate_key_title)
    
    echo "Adding SSH key with title: $KEY_TITLE"
    curl -s -X POST \
         -H "Authorization: token $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         https://api.github.com/user/keys \
         -d "{\"title\":\"$KEY_TITLE\",\"key\":\"$KEY\"}"
}

main() {
    echo "Checking SSH configuration..."
    setup_ssh
    echo "Verifying GitHub SSH key..."
    setup_github
}

main "$@"

