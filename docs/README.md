# AYGP Agent Testing Framework

## Overview
This framework provides tools for testing and coordinating multiple AI agents through a proxy interface. It includes functionality for task decomposition, implementation, documentation, innovation, and analysis.

## Components

### test_agents.sh
The main script for coordinating and testing AI agents. It handles:
- Agent communication via HTTP proxy
- Response logging and monitoring
- Error handling and recovery
- State management

### Configuration
Configuration files are stored in `~/.anthropic/config/`:
- `agents.json`: Agent definitions and system settings

### Logs
Logs are stored in `~/.anthropic/logs/`:
- `agents.log`: Main application log
- System state is tracked in `~/.anthropic/.state/`

## Usage

### Basic Usage
```bash
~/.anthropic/tools/test_agents.sh
```

### Options
- `-h`: Show help message
- `-v`: Enable verbose logging

### Environment Variables
- `HTTP_PROXY`: Proxy server for API requests
- `VERBOSE`: Enable verbose output when set to 1

## Maintenance

### Regular Tasks
1. Check logs for errors: `tail -f ~/.anthropic/logs/agents.log`
2. Verify agent status: `test_agents.sh -v`
3. Update configuration as needed in `~/.anthropic/config/agents.json`

### Troubleshooting
Common issues and solutions:

1. Agent Not Responding
   - Check proxy configuration
   - Verify API endpoint status
   - Review logs for errors

2. Configuration Issues
   - Validate JSON syntax in config files
   - Check file permissions
   - Verify environment variables

3. Log Issues
   - Check disk space
   - Verify write permissions
   - Rotate logs if needed

## Security
- All external calls use HTTP_PROXY
- Logging includes security-relevant events
- File permissions are set appropriately
- Input validation is performed