#!/usr/bin/env bash

# setup_mitm.sh - MITM proxy configuration for development environments
# Part of ~/.anthropic/scripts collection

set -euo pipefail
[ "${TRACE:-0}" = "1" ] && set -x

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANTHROPIC_DIR="${ANTHROPIC_DIR:-$HOME/.anthropic}"

# Environment detection
IN_DOCKER=0
if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    IN_DOCKER=1
fi

# Default locations to check for certificate
CERT_LOCATIONS=(
    "$ANTHROPIC_DIR/certs/mitmproxy-ca-cert.pem"
    "$HOME/.mitm/mitmproxy-ca-cert.pem"
    "$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
    "/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
)

# Default configuration with Docker awareness
if [ "$IN_DOCKER" -eq 1 ]; then
    PROXY_HOST=${PROXY_HOST:-"host.docker.internal"}
else
    PROXY_HOST=${PROXY_HOST:-"localhost"}
fi
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

check_proxy_host() {
    if [ "$IN_DOCKER" -eq 1 ]; then
        if ! getent hosts host.docker.internal >/dev/null 2>&1; then
            warn "host.docker.internal not resolvable. Adding to /etc/hosts..."
            echo "127.0.0.1 host.docker.internal" | sudo tee -a /etc/hosts >/dev/null
        fi
    fi
}

find_certificate() {
    for loc in "${CERT_LOCATIONS[@]}"; do
        if [ -f "$loc" ]; then
            CERT_SOURCE="$loc"
            log "Found certificate at $loc"
            return 0
        fi
    done

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


# Updates to the check_dependencies function
check_dependencies() {
    local deps=(openssl curl python3)
    local optional_deps=(npm java bb)
    local missing=()
    local missing_optional=()
    
    # Check for libnss3-tools package instead of just certutil
    if ! dpkg -l | grep -q libnss3-tools; then
        warn "libnss3-tools not found - Firefox certificate management will be disabled"
        warn "Install with: sudo apt-get install -y libnss3-tools"
    fi
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_optional+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        warn "Please install required dependencies and try again"
        exit 1
    fi
    
    if [ ${#missing_optional[@]} -ne 0 ]; then
        warn "Missing optional dependencies: ${missing_optional[*]}"
        warn "Some features will be skipped"
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
    local config_dir="$ANTHROPIC_DIR/config"
    local proxy_config="$config_dir/proxy.sh"
    
    mkdir -p "$config_dir"
    
    cat > "$proxy_config" << EOL
#!/bin/bash
# Proxy configuration for Anthropic environment
export HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
export HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
export NO_PROXY="localhost,127.0.0.1"
export REQUESTS_CA_BUNDLE="$CERT_DEST"

# Additional environment variables for specific tools
export CURL_CA_BUNDLE="$CERT_DEST"
export NODE_EXTRA_CA_CERTS="$CERT_DEST"
export SSL_CERT_FILE="$CERT_DEST"
EOL
    
    chmod +x "$proxy_config"
    
    local rc_files=("$HOME/.bashrc" "$HOME/.zshrc")
    local proxy_source_line="source $proxy_config"
    
    for rc_file in "${rc_files[@]}"; do
        if [ -f "$rc_file" ] && ! grep -q "source.*$proxy_config" "$rc_file"; then
            echo "$proxy_source_line" >> "$rc_file"
        fi
    done
}

setup_npm() {
    log "Configuring npm..."
    if ! command -v npm >/dev/null 2>&1; then
        warn "npm not found - skipping npm configuration"
        return
    fi

    npm config set proxy "$HTTP_PROXY"
    npm config set https-proxy "$HTTPS_PROXY"
    npm config set cafile "$CERT_DEST"
    npm config set strict-ssl true
    
    if npm ping >/dev/null 2>&1; then
        log "npm configuration successful"
    else
        warn "npm configuration may not be working correctly"
        warn "Please check npm's proxy settings manually"
    fi
}


# Updated Java setup function
setup_java() {
    log "Configuring Java..."
    if ! command -v java >/dev/null 2>&1; then
        warn "Java not found - skipping Java configuration"
        return
    fi

    # Enhanced Java home detection for different architectures
    if [ -z "${JAVA_HOME:-}" ]; then
        # Check common ARM64 locations first
        local java_locations=(
            "/usr/lib/jvm/java-11-openjdk-arm64"
            "/usr/lib/jvm/java-17-openjdk-arm64"
            "/usr/lib/jvm/java-8-openjdk-arm64"
            "/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home"
            "/usr/java/latest"
        )
        
        for loc in "${java_locations[@]}"; do
            if [ -d "$loc" ]; then
                JAVA_HOME="$loc"
                break
            fi
        done
        
        if [ -z "${JAVA_HOME:-}" ]; then
            JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        fi
        
        log "Setting JAVA_HOME to: $JAVA_HOME"
    fi

    # Update environment file with JAVA_HOME
    local config_dir="$ANTHROPIC_DIR/config"
    local java_config="$config_dir/java.sh"
    
    cat > "$java_config" << EOL
#!/bin/bash
export JAVA_HOME="$JAVA_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOL
    
    chmod +x "$java_config"
    
    # Source the java config in the proxy config
    echo "source $java_config" >> "$config_dir/proxy.sh"

    local CACERTS="$JAVA_HOME/lib/security/cacerts"
    if [ ! -f "$CACERTS" ]; then
        warn "Java cacerts not found at $CACERTS"
        return
    fi

    if ! keytool -list -keystore "$CACERTS" -storepass changeit | grep -q "mitmproxy"; then
        log "Adding certificate to Java keystore..."
        sudo keytool -importcert \
            -file "$CERT_SOURCE" \
            -alias mitmproxy \
            -keystore "$CACERTS" \
            -storepass changeit \
            -noprompt \
            -cacerts
    else
        log "Certificate already in Java keystore"
    fi
}



setup_babashka() {
    log "Configuring Babashka..."
    if ! command -v bb >/dev/null 2>&1; then
        warn "Babashka not found - skipping Babashka configuration"
        return
    fi

    local BB_CONFIG_DIR="$HOME/.babashka"
    local BB_CONFIG_FILE="$BB_CONFIG_DIR/config.edn"

    mkdir -p "$BB_CONFIG_DIR"
    
    cat > "$BB_CONFIG_FILE" << EOL
{:certificate-authorities ["$CERT_DEST"]
 :proxy-url "$HTTP_PROXY"}
EOL
    
    log "Babashka configuration created at $BB_CONFIG_FILE"
}

setup_firefox() {
    log "Configuring Firefox..."
    
    # Check for Firefox or Firefox-ESR installation
    if ! command -v firefox >/dev/null 2>&1 && ! command -v firefox-esr >/dev/null 2>&1; then
        warn "Neither Firefox nor Firefox-ESR found - skipping profile setup"
        warn "Install Firefox with: sudo apt-get install -y firefox-esr"
        return
    fi

    # Determine Firefox binary and profile location
    FIREFOX_BIN="firefox"
    if ! command -v firefox >/dev/null 2>&1 && command -v firefox-esr >/dev/null 2>&1; then
        FIREFOX_BIN="firefox-esr"
        log "Using Firefox ESR installation"
    fi
    
    # Set up profile directory based on environment
    if [ "$IN_DOCKER" -eq 1 ]; then
        local FIREFOX_DIR="$ANTHROPIC_DIR/.mozilla/firefox"
        mkdir -p "$FIREFOX_DIR"
    else
        local FIREFOX_DIR="$HOME/.mozilla/firefox"
    fi
    
    if [ ! -d "$FIREFOX_DIR" ]; then
        log "Creating Firefox profile directory at $FIREFOX_DIR"
        mkdir -p "$FIREFOX_DIR"
    fi

    # Ensure libnss3-tools is installed
    if ! dpkg -l | grep -q libnss3-tools; then
        warn "Installing libnss3-tools for Firefox certificate management..."
        sudo apt-get update && sudo apt-get install -y libnss3-tools
    fi

    # Find or create Firefox profile
    local PROFILE_DIR
    if [ -f "$FIREFOX_DIR/profiles.ini" ]; then
        PROFILE_DIR=$(grep "Path=.*\.default" "$FIREFOX_DIR/profiles.ini" | cut -d'=' -f2)
        if [ -z "$PROFILE_DIR" ]; then
            PROFILE_DIR=$(grep "Path=.*\.default-esr" "$FIREFOX_DIR/profiles.ini" | cut -d'=' -f2)
        fi
    fi
    
    if [ -z "${PROFILE_DIR:-}" ]; then
        PROFILE_DIR="default"
        mkdir -p "$FIREFOX_DIR/$PROFILE_DIR"
        
        # Create minimal profiles.ini if it doesn't exist
        if [ ! -f "$FIREFOX_DIR/profiles.ini" ]; then
            cat > "$FIREFOX_DIR/profiles.ini" << EOL
[Profile0]
Name=default
IsRelative=1
Path=default
Default=1
EOL
        fi
    fi

    log "Using Firefox profile: $PROFILE_DIR"
    
    # Create Firefox proxy configuration
    local user_js="$FIREFOX_DIR/$PROFILE_DIR/user.js"
    cat > "$user_js" << EOL
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "${PROXY_HOST}");
user_pref("network.proxy.http_port", ${PROXY_PORT});
user_pref("network.proxy.ssl", "${PROXY_HOST}");
user_pref("network.proxy.ssl_port", ${PROXY_PORT});
user_pref("network.proxy.no_proxies_on", "localhost,127.0.0.1");
user_pref("security.enterprise_roots.enabled", true);
EOL
    
    log "Firefox proxy configuration created at $user_js"
    
    # Import certificate if certutil is available
    if command -v certutil >/dev/null 2>&1; then
        certutil -A -n "mitmproxy" \
            -t "C,," \
            -i "$CERT_SOURCE" \
            -d "sql:$FIREFOX_DIR/$PROFILE_DIR" 2>/dev/null || true
        log "Certificate imported to Firefox profile"
    else
        warn "certutil not available - certificate must be imported manually"
    fi

    # Enable system certificates
    local policies_dir="/usr/lib/${FIREFOX_BIN}/distribution"
    local policies_file="$policies_dir/policies.json"
    if [ ! -f "$policies_file" ]; then
        log "Creating Firefox policies for system certificates..."
        sudo mkdir -p "$policies_dir"
        sudo tee "$policies_file" > /dev/null << EOL
{
    "policies": {
        "Certificates": {
            "Install": ["$CERT_DEST"]
        }
    }
}
EOL
        log "Firefox system certificate policies created"
    fi
}


test_setup() {
    log "Testing proxy setup..."
    
    source "$ANTHROPIC_DIR/config/proxy.sh"
    
    log "Proxy Configuration:"
    log "  HTTP_PROXY=$HTTP_PROXY"
    log "  HTTPS_PROXY=$HTTPS_PROXY"
    log "  NO_PROXY=$NO_PROXY"
    log "  CERT_DEST=$CERT_DEST"
    
    if [ "$IN_DOCKER" -eq 1 ]; then
        log "Docker Environment:"
        log "  Resolving host.docker.internal..."
        getent hosts host.docker.internal || true
    fi
    
    log "Testing proxy connection..."
    if nc -z "$PROXY_HOST" "$PROXY_PORT" 2>/dev/null; then
        log "Proxy is reachable at $PROXY_HOST:$PROXY_PORT"
    else
        warn "Cannot connect to proxy at $PROXY_HOST:$PROXY_PORT"
        return 1
    fi
    
    log "Testing HTTPS connection..."
    if curl -v --connect-timeout 5 https://example.com > /dev/null 2>&1; then
        log "HTTPS connection successful"
    else
        warn "HTTPS connection failed"
        warn "Check proxy connection and certificate configuration"
        return 1
    fi
}

main() {
    log "Starting MITM proxy setup..."
    
    check_dependencies
    check_proxy_host
    
    if ! find_certificate; then
        exit 1
    fi
    
    setup_system_cert
    setup_environment
    setup_npm
    setup_java
    setup_babashka
    setup_firefox
    
    if ! test_setup; then
        warn "Setup completed with warnings - some tests failed"
        warn "Please check your proxy configuration and try again"
        exit 1
    fi
    
    log "MITM proxy setup complete"
    warn "Please restart your shell or run: source $ANTHROPIC_DIR/config/proxy.sh"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
