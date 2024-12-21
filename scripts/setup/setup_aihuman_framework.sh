#!/bin/bash

# AI-Human Team Dynamics Framework Setup Script
# Version: 1.0
# Date: 2024-12-04

set -e

# Configuration
WORKSPACE_DIR="${HOME}/.anthropic/workspace/aihuman"
CONFIG_DIR="${HOME}/.anthropic/config/aihuman"
LOG_DIR="${HOME}/.anthropic/logs/aihuman"
DATA_DIR="${HOME}/.anthropic/data/aihuman"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    local level=$1
    shift
    local message=$*
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_DIR}/setup.log"
}

# Error handling
handle_error() {
    local error_message=$*
    log "ERROR" "${RED}${error_message}${NC}"
    exit 1
}

# Create required directories
setup_directories() {
    log "INFO" "Creating required directories..."
    mkdir -p "${WORKSPACE_DIR}" "${CONFIG_DIR}" "${LOG_DIR}" "${DATA_DIR}" || \
        handle_error "Failed to create directories"
    
    # Create subdirectories for different components
    mkdir -p "${WORKSPACE_DIR}/"{ui,engine,analytics} || \
        handle_error "Failed to create component directories"
    
    log "SUCCESS" "${GREEN}Directories created successfully${NC}"
}

# Initialize configuration
init_config() {
    log "INFO" "Initializing configuration..."
    
    # Create base configuration file
    cat > "${CONFIG_DIR}/config.json" <<EOF
{
    "version": "1.0",
    "components": {
        "ui": {
            "port": 8080,
            "debug": false,
            "theme": "light"
        },
        "engine": {
            "workers": 4,
            "queue_size": 1000,
            "timeout": 30
        },
        "analytics": {
            "retention_days": 30,
            "batch_size": 100
        }
    },
    "security": {
        "encryption_enabled": true,
        "audit_logging": true,
        "session_timeout": 3600
    },
    "monitoring": {
        "enabled": true,
        "interval": 60,
        "metrics": [
            "response_time",
            "error_rate",
            "user_satisfaction"
        ]
    }
}
EOF
    
    log "SUCCESS" "${GREEN}Configuration initialized successfully${NC}"
}

# Set up monitoring
setup_monitoring() {
    log "INFO" "Setting up monitoring..."
    
    # Create monitoring configuration
    mkdir -p "${CONFIG_DIR}/monitoring" || \
        handle_error "Failed to create monitoring directory"
    
    # Create monitoring dashboard configuration
    cat > "${CONFIG_DIR}/monitoring/dashboards.json" <<EOF
{
    "dashboards": [
        {
            "name": "System Overview",
            "refresh": "1m",
            "panels": [
                {
                    "title": "Response Time",
                    "type": "graph",
                    "metric": "response_time"
                },
                {
                    "title": "Error Rate",
                    "type": "gauge",
                    "metric": "error_rate"
                },
                {
                    "title": "User Satisfaction",
                    "type": "trend",
                    "metric": "user_satisfaction"
                }
            ]
        }
    ]
}
EOF
    
    log "SUCCESS" "${GREEN}Monitoring setup completed${NC}"
}

# Initialize security
init_security() {
    log "INFO" "Initializing security..."
    
    # Generate encryption key (this is a placeholder - use proper key generation in production)
    openssl rand -base64 32 > "${CONFIG_DIR}/.key" || \
        handle_error "Failed to generate encryption key"
    
    # Set up audit logging
    mkdir -p "${LOG_DIR}/audit" || \
        handle_error "Failed to create audit log directory"
    
    # Create security policy
    cat > "${CONFIG_DIR}/security_policy.json" <<EOF
{
    "password_policy": {
        "min_length": 12,
        "require_special": true,
        "require_numbers": true,
        "require_uppercase": true
    },
    "session_policy": {
        "max_duration": 3600,
        "idle_timeout": 900,
        "max_concurrent": 3
    },
    "audit_policy": {
        "enabled": true,
        "retention_days": 90,
        "log_level": "INFO"
    }
}
EOF
    
    # Set proper permissions
    chmod 600 "${CONFIG_DIR}/.key" || \
        handle_error "Failed to set key permissions"
    chmod 600 "${CONFIG_DIR}/security_policy.json" || \
        handle_error "Failed to set security policy permissions"
    
    log "SUCCESS" "${GREEN}Security initialized successfully${NC}"
}

# Main setup function
main() {
    log "INFO" "Starting AI-Human Team Dynamics Framework setup..."
    
    # Create directories
    setup_directories
    
    # Initialize configuration
    init_config
    
    # Set up monitoring
    setup_monitoring
    
    # Initialize security
    init_security
    
    log "SUCCESS" "${GREEN}Setup completed successfully${NC}"
    log "INFO" "Please check ${LOG_DIR}/setup.log for detailed information"
}

# Execute main function
main "$@"