#!/usr/bin/env bash

# verify_env.sh - Verify development environment tool versions with flexible matching
# Place in ~/.anthropic/scripts/verify_env.sh

set -euo pipefail
[ "${TRACE:-0}" = "1" ] && set -x

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Version requirements - now with minimums instead of exact matches
declare -A VERSION_REQUIREMENTS=(
    # Tool    Min Version  Critical?
    ["git"]="2.34.0 false"        # Git 2.34+ is fine
    ["jq"]="1.6 false"           # jq 1.6+ is fine
    ["curl"]="7.81.0 false"      # curl 7.81+ is fine
    ["emacs"]="27.1 false"       # Emacs 27.1+ is fine
    ["imagemagick"]="6.9.0 false" # ImageMagick 6.9+ is fine
    ["aws"]="2.0.0 false"        # AWS CLI v2+ is fine
    ["bash"]="5.1.0 false"       # Bash 5.1+ is fine
    ["gpg"]="2.2.0 false"        # GPG 2.2+ is fine
    ["zsh"]="5.8 false"          # Zsh 5.8+ is fine
    ["poetry"]="1.8.0 true"      # Poetry 1.8+ is required
)

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }

# Convert version string to comparable number
version_to_number() {
    echo "$1" | awk -F. '{ printf("%d%03d%03d\n", $1, $2, $3) }'
}

# Compare versions
compare_versions() {
    local current=$1
    local required=$2
    local current_num=$(version_to_number "$current")
    local required_num=$(version_to_number "$required")
    [ "$current_num" -ge "$required_num" ]
}

# Version check with minimum version
version_check() {
    local tool=$1
    local current_version=$2
    local requirement=(${VERSION_REQUIREMENTS[$tool]})
    local min_version=${requirement[0]}
    local is_critical=${requirement[1]}

    if compare_versions "$current_version" "$min_version"; then
        success "$tool: $current_version (>= $min_version)"
        return 0
    elif [ "$is_critical" = "true" ]; then
        error "$tool: Found $current_version, requires >= $min_version (CRITICAL)"
        return 1
    else
        warn "$tool: Found $current_version, recommends >= $min_version"
        return 0
    fi
}

# Extract version using command
get_version() {
    local tool=$1
    case $tool in
        "git") git --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' ;;
        "jq") jq --version | grep -Eo '[0-9]+\.[0-9]+' ;;
        "curl") curl --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        "emacs") emacs --version | grep -Eo '[0-9]+\.[0-9]+' | head -1 ;;
        "imagemagick") convert -version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' | head -1 ;;
        "aws") aws --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        "bash") bash --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        "gpg") gpg --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        "zsh") zsh --version | grep -Eo '[0-9]+\.[0-9]+' | tr -d '\n' ;;
        "poetry") poetry --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Check tool versions
check_versions() {
    local critical_failures=0
    
    log "Checking tool versions..."
    echo
    
    for tool in "${!VERSION_REQUIREMENTS[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            local requirement=(${VERSION_REQUIREMENTS[$tool]})
            local is_critical=${requirement[1]}
            if [ "$is_critical" = "true" ]; then
                error "$tool: Not installed (CRITICAL)"
                critical_failures=$((critical_failures + 1))
            else
                warn "$tool: Not installed (OPTIONAL)"
            fi
            continue
        fi
        
        version=$(get_version "$tool")
        if [ "$version" = "UNKNOWN" ]; then
            warn "$tool: Could not determine version"
            continue
        fi
        
        if ! version_check "$tool" "$version"; then
            critical_failures=$((critical_failures + 1))
        fi
    done
    
    echo
    if [ $critical_failures -eq 0 ]; then
        success "All critical version requirements met"
        return 0
    else
        error "$critical_failures critical version requirement(s) not met"
        return 1
    fi
}

# Main execution
main() {
    check_versions
}

# Allow sourcing without execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
