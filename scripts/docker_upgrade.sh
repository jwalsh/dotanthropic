#!/usr/bin/env bash

# docker_upgrade.sh - Upgrade development tools to recent versions
# Place in ~/.anthropic/scripts/docker_upgrade.sh

set -euo pipefail
[ "${TRACE:-0}" = "1" ] && set -x

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }

# Add modern package sources
setup_sources() {
    log "Setting up package sources..."
    
    # Git PPA for newer version
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:git-core/ppa

    # We'll build Emacs from source instead of using PPA
    apt-get install -y build-essential libncurses-dev pkg-config libgtk-3-dev \
        libgnutls28-dev libjansson-dev libxml2-dev

    apt-get update
}

# Install/upgrade packages
upgrade_packages() {
    log "Upgrading packages..."
    
    # Core packages
    apt-get install -y \
        git \
        curl \
        jq \
        imagemagick \
        gpg \
        zsh

    # Poetry (using official installer)
    curl -sSL https://install.python-poetry.org | python3 -
}

build_emacs() {
    log "Building Emacs from source..."
    cd /tmp
    wget https://ftp.gnu.org/gnu/emacs/emacs-29.1.tar.xz
    tar xf emacs-29.1.tar.xz
    cd emacs-29.1
    ./configure --with-gtk3 --with-json --with-modules
    make -j$(nproc)
    make install
    cd ..
    rm -rf emacs-29.1*
}

# Cleanup
cleanup() {
    log "Cleaning up..."
    apt-get clean
    rm -rf /tmp/aws* /tmp/emacs*
}

main() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi

    log "Starting system upgrade..."
    setup_sources
    upgrade_packages
    build_emacs
    cleanup
    success "Upgrade complete. Please check versions with verify_env.sh"
}

# Run main if script is executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
