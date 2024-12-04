#!/usr/bin/env bash

# setup_mitm.sh - MITM proxy configuration for development environments
# Part of ~/.anthropic/scripts collection

set -euo pipefail
[ "${TRACE:-0}" = "1" ] && set -x

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default locations to check for certificate
CERT_LOCATIONS=(
    "$HOME/.mitm/mitmproxy-ca-cert.pem"
    "$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
    "/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
    "$HOME/.anthropic/certs/mitmproxy-ca-cert.pem"
)

# Default configuration
PROXY_HOST=${PROXY_HOST:-"proxy"}
PROXY_PORT=${PROXY_PORT:-8080}
CERT_DEST="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
CERT_SOURCE=""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; }

find_certificate() {
    for loc in "${CERT_LOCATIONS[@]}"; do
        if [ -f "$loc" ]; then
            CERT_SOURCE="$loc"
            log "Found certificate at $loc"
            return 0
        fi
    done

    # If no certificate found, offer to create ~/.mitm directory
    if [ ! -d "$HOME/.mitm" ]; then
        warn "No certificate found in standard locations"
        read -p "Would you like to create ~/.mitm directory? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$HOME/.mitm"
            warn "Created $HOME/.mitm - please place your mitmproxy-ca-cert.pem here"
            warn "You can get this by running mitmproxy and copying from:"
            warn "~/.mitmproxy/mitmproxy-ca-cert.pem (if using mitmproxy)"
            warn "Then run this script again"
        fi
    fi
    
    return 1
}

check_dependencies() {
    local deps=(openssl curl python3)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        warn "Please install required dependencies and try again"
        exit 1
    fi
}

setup_system_cert() {
    if [ ! -f "$CERT_SOURCE" ]; then
        error "No valid certificate found"
        warn "Please ensure certificate exists in one of these locations:"
        for loc in "${CERT_LOCATIONS[@]}"; do
            warn "  - $loc"
        done
        exit 1
    fi

    if [ ! -f "$CERT_DEST" ] || ! diff -q "$CERT_SOURCE" "$CERT_DEST" >/dev/null 2>&1; then
        log "Installing system certificate..."
        sudo mkdir -p "$(dirname "$CERT_DEST")"
        sudo cp "$CERT_SOURCE" "$CERT_DEST"
        sudo update-ca-certificates
    else
        log "System certificate already up to date"
    fi
}

setup_environment() {
    local config_dir="$HOME/.anthropic/config"
    local proxy_config="$config_dir/proxy.sh"
    
    mkdir -p "$config_dir"
    
    cat > "$proxy_config" << EOL
#!/bin/bash
export HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
export HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
export NO_PROXY="localhost,127.0.0.1"
export REQUESTS_CA_BUNDLE="$CERT_DEST"
EOL
    
    chmod +x "$proxy_config"
    
    # Add to bashrc if not already there
    if ! grep -q "source.*$proxy_config" "$HOME/.bashrc"; then
        echo "source $proxy_config" >> "$HOME/.bashrc"
    fi

    # Also add to zshrc if it exists
    if [ -f "$HOME/.zshrc" ] && ! grep -q "source.*$proxy_config" "$HOME/.zshrc"; then
        echo "source $proxy_config" >> "$HOME/.zshrc"
    fi
}

test_setup() {
    log "Testing proxy setup..."
    
    # Source the proxy configuration
    source "$HOME/.anthropic/config/proxy.sh"
    
    # Test HTTPS request
    if curl -s https://example.com > /dev/null; then
        log "HTTPS connection successful"
    else
        warn "HTTPS connection failed"
        warn "Please check your proxy configuration and certificate installation"
    fi
    
    # Test Python requests if requests module is available
    if python3 -c "import requests" 2>/dev/null; then
        if python3 -c "import requests; requests.get('https://example.com')" 2>/dev/null; then
            log "Python requests successful"
        else
            warn "Python requests failed"
            warn "Please check your Python environment and certificate configuration"
        fi
    else
        warn "Python requests module not installed - skipping Python test"
    fi
}

main() {
    log "Starting MITM proxy setup..."
    
    check_dependencies
    
    if ! find_certificate; then
        exit 1
    fi
    
    setup_system_cert
    setup_environment
    test_setup
    
    log "MITM proxy setup complete"
    warn "Please restart your shell or run: source ~/.anthropic/config/proxy.sh"
}

# Allow sourcing without execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
