# AYGP Scripts

This directory contains scripts for managing the AYGP (Automated Yet Guided Process) system.

## Directory Structure

- `resurrection/`: System resurrection sequence scripts
  - Numbered scripts (00-99) for ordered execution
  - `lib/common.sh` for shared functions
  - `resurrect.sh` main orchestrator

- `setup/`: One-time setup scripts
  - System bootstrapping
  - Framework setup
  - Environment configuration

- `build/`: Build scripts
  - Docker management
  - Emacs build

- `verification/`: Testing and verification
  - Agent verification
  - Environment checks
  - System tests

- `utils/`: Utility scripts
  - Code conversion
  - Changelog generation
  - Version management

## Usage

### System Resurrection
```bash
./resurrection/resurrect.sh
```

### Setup
```bash
./setup/bootstrap.sh
```

### Verification
```bash
./verification/verify_env.sh
```

## Script Dependencies

- resurrection scripts → common.sh
- verification scripts → resurrection state
- setup scripts → independent
- build scripts → independent
- utils → independent

## Adding New Scripts

1. Place in appropriate directory
2. Follow naming conventions
3. Update documentation
4. Add verification if needed
