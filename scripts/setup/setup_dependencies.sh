#!/usr/bin/env bash

# setup_dependencies.sh - Install dependencies for both Docker and macOS environments
# Part of ~/.anthropic/scripts collection

set -euo pipefail
[ "${TRACE:-0}" = "1" ] && set -x

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANTHROPIC_DIR="${ANTHROPIC_DIR:-$HOME/.anthropic}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; }

# Detect environment
detect_environment() {
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "docker"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Install dependencies for Docker environment
install_docker_deps() {
    log "Installing Docker environment dependencies..."
    
    # Update package lists
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y \
        curl \
        wget \
        git \
        jq \
        make \
        openssl \
        python3 \
        python3-pip \
        netcat \
        libnss3-tools \
        firefox-esr \
        openjdk-11-jdk \
        nodejs \
        npm
        
    # Install mitmproxy
    python3 -m pip install mitmproxy

    log "Docker dependencies installed successfully"
}

# Install dependencies for macOS environment
install_macos_deps() {
    log "Installing macOS dependencies..."
    
    # Install Homebrew if not present
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required packages
    brew install \
        curl \
        wget \
        git \
        jq \
        make \
        openssl \
        python3 \
        netcat \
        nss \
        firefox \
        openjdk@11 \
        node \
        mitmproxy

    log "macOS dependencies installed successfully"
}

# Main installation function
main() {
    local env_type
    env_type=$(detect_environment)
    
    log "Detected environment: $env_type"
    
    case "$env_type" in
        docker)
            install_docker_deps
            ;;
        macos)
            install_macos_deps
            ;;
        *)
            error "Unsupported environment"
            exit 1
            ;;
    esac
    
    # Create necessary directories
    mkdir -p "$ANTHROPIC_DIR"/{config,certs,tools,.state,logs}
    
    log "Setup complete"
    log "You may need to restart your shell for some changes to take effect"
}

# Allow sourcing without execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
