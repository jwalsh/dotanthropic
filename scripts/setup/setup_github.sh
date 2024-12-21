#!/bin/bash
set -euo pipefail

setup_remote() {
    if ! git remote | grep -q '^origin$'; then
        git remote add origin git@github.com:aygp-dr/dotanthropic.git
    fi
    git branch -M main
    git push -u origin main
}

setup_remote
