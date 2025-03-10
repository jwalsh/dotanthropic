#!/usr/bin/env bash
# Configuration script for dotanthropic project
# Detects system capabilities and sets up environment preferences

set -euo pipefail

CONFIG_FILE="${HOME}/.anthropic/.config"
DETECTED_MAKE=""

# Create initial config file if it doesn't exist
create_config() {
    if [ ! -f "${CONFIG_FILE}" ]; then
        mkdir -p "$(dirname "${CONFIG_FILE}")"
        cat > "${CONFIG_FILE}" <<EOL
# dotanthropic configuration
# Generated on $(date)

# Make command to use (make or gmake)
USE_MAKE=""

# System detected
SYSTEM="$(uname -s)"

# Path configuration
PATH_ADDITIONS=""
EOL
        echo "Created initial config at ${CONFIG_FILE}"
    fi
}

# Detect the best make command
detect_make() {
    DETECTED_MAKE=$(bash "${HOME}/.anthropic/scripts/detect_make.sh")
    echo "Detected make command: ${DETECTED_MAKE}"
}

# Update the make command in the config
configure_make() {
    local use_make=""
    
    # Get detected make as default suggestion
    detect_make
    
    # Ask the user for preference
    read -p "Which make command do you want to use? [${DETECTED_MAKE}]: " use_make
    use_make=${use_make:-${DETECTED_MAKE}}
    
    # Update the config file
    sed -i.bak "s/^USE_MAKE=.*$/USE_MAKE=\"${use_make}\"/" "${CONFIG_FILE}"
    echo "Set default make command to: ${use_make}"
    
    # Create a .makerc file for environment variables
    cat > "${HOME}/.anthropic/.makerc" <<EOL
# Generated by configure.sh on $(date)
export USE_MAKE="${use_make}"
EOL
    
    # Suggest adding to shell rc
    echo
    echo "Add the following line to your shell initialization file (.bashrc, .zshrc, etc.):"
    echo "  source ${HOME}/.anthropic/.makerc"
}

# Main script
main() {
    echo "Configuring dotanthropic environment..."
    create_config
    configure_make
    echo
    echo "Configuration complete! Use 'make' or '${DETECTED_MAKE}' for building."
    echo "You can override with 'USE_MAKE=gmake make target' or by setting the USE_MAKE environment variable."
}

main "$@"