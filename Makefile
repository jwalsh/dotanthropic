.PHONY: help bootstrap setup nix-shell nix-build nix-clean check-env install-nix github-setup git-config validate-token clean

SHELL := /bin/bash
ANTHROPIC_DIR := $(HOME)/.anthropic
DATE := $(shell date +%Y-%m-%d)
TIME := $(shell date +%H-%M-%S)

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# =================== Installation ===================

install-nix: ## Install Nix package manager
	@echo "Installing Nix package manager..."
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix is already installed"; \
	else \
		sudo install -d -m755 -o $(shell id -u) -g $(shell id -g) /nix && \
		curl -L https://nixos.org/nix/install | sh && \
		. ~/.nix-profile/etc/profile.d/nix.sh; \
	fi
	@echo "You may need to restart your shell"

# =================== Environment Setup ===================

check-env: ## Check environment capabilities
	@echo "Checking environment..."
	@if command -v nix-shell >/dev/null 2>&1; then \
		echo "Nix version: $$(nix --version)"; \
		echo "Shell file: $$(readlink -f shell.nix)"; \
		nix-shell --run "check_env"; \
	else \
		echo "Nix not installed. Run 'make install-nix' first"; \
		exit 1; \
	fi

bootstrap: ## Run initial bootstrap script
	@echo "Running bootstrap..."
	@bash scripts/bootstrap.sh

nix-shell: ## Enter Nix shell environment
	@if command -v nix-shell >/dev/null 2>&1; then \
		nix-shell; \
	else \
		echo "Nix not installed. Run 'make install-nix' first"; \
		exit 1; \
	fi

nix-build: ## Build the Nix environment
	@echo "Building Nix environment..."
	@nix-build -E 'with import <nixpkgs> {}; callPackage ./shell.nix {}'

nix-clean: ## Clean Nix store and environment
	@echo "Cleaning Nix environment..."
	@rm -f result
	@if command -v nix-collect-garbage >/dev/null 2>&1; then \
		nix-collect-garbage -d; \
	fi

# =================== Git Configuration ===================

git-config: ## Configure git user identity
	@echo "Setting up git user configuration..."
	@git config --global user.email "computeruse@defrecord.com"
	@git config --global user.name "computeruse"
	@git config --global init.defaultBranch main
	@echo "Git identity configured:"
	@git config --get user.name
	@git config --get user.email

validate-token: ## Validate GitHub token
	@echo "Validating GitHub token..."
	@if [ -z "$$GITHUB_TOKEN" ] && [ -f "$(ANTHROPIC_DIR)/secrets.json" ]; then \
		export GITHUB_TOKEN=$$(jq -r '.github_token' $(ANTHROPIC_DIR)/secrets.json); \
	fi
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "Error: GITHUB_TOKEN not set and not found in secrets.json"; \
		exit 1; \
	fi
	@if gh api user --jq .login >/dev/null 2>&1; then \
		echo "Token valid for user: $$(gh api user --jq .login)"; \
	else \
		curl -s -H "Authorization: token $$GITHUB_TOKEN" https://api.github.com/user | jq -r '.login // "Token invalid"'; \
	fi

github-setup: validate-token ## Setup GitHub repository and SSH key
	@echo "Setting up GitHub configuration..."
	@bash scripts/setup_github.sh

# =================== Main Targets ===================

setup: git-config bootstrap github-setup nix-build ## Complete environment setup
	@echo "Setting up Anthropic environment..."
	@mkdir -p $(ANTHROPIC_DIR)/{logs,tools,.state}
	@mkdir -p $(ANTHROPIC_DIR)/.gnupg && chmod 700 $(ANTHROPIC_DIR)/.gnupg
	@mkdir -p $(ANTHROPIC_DIR)/.ssh && chmod 700 $(ANTHROPIC_DIR)/.ssh
	@echo "Environment setup complete"
	@make check-env

clean: nix-clean ## Clean up environment
	@echo "Cleaning up environment..."
	@find $(ANTHROPIC_DIR) -name "*.tmp" -delete
	@find $(ANTHROPIC_DIR) -name "*.log" -delete
	@find $(ANTHROPIC_DIR) -name "*.bak" -delete
	@echo "Cleanup complete"

# =================== Status ===================

status: ## Show environment status
	@echo "Environment Status ($(DATE) $(TIME))"
	@echo "=================================="
	@echo "Nix: $$(command -v nix-shell >/dev/null 2>&1 && echo "Installed" || echo "Not installed")"
	@echo "Git: $$(git --version 2>/dev/null || echo "Not installed")"
	@echo "SSH Key: $$(test -f ~/.ssh/id_rsa && echo "Present" || echo "Missing")"
	@echo "Directory: $(ANTHROPIC_DIR)"
	@echo "Tools: $$(ls -1 $(ANTHROPIC_DIR)/tools 2>/dev/null | wc -l) installed"
	@echo
	@make validate-token || true

changelog: ## Generate CHANGELOG.org from git history
	@echo "Generating changelog..."
	@chmod +x scripts/generate_changelog.sh
	@scripts/generate_changelog.sh
	@echo "Changelog generated"

changelog-commit: ## Generate and commit CHANGELOG.org with [skip ci]
	@echo "Generating and committing changelog..."
	@chmod +x scripts/generate_changelog.sh
	@scripts/generate_changelog.sh --commit-message "[skip ci] Update CHANGELOG.org"
	@echo "Changelog committed with CI skip flag"

setup-simple: ## Initial env without Nix
	sh ./scripts/setup_simple.sh

gpg-key: ## Generate and configure GPG key
	@echo "Generating GPG key..."
	@if gpg --list-secret-keys computeruse@defrecord.com >/dev/null 2>&1; then \
		echo "GPG key already exists for computeruse@defrecord.com"; \
	else \
		echo "Creating new GPG key..."; \
		gpg --batch --passphrase '' --quick-gen-key computeruse@defrecord.com default default never; \
	fi
	@GPG_KEY_ID=$$(gpg --list-secret-keys --keyid-format LONG computeruse@defrecord.com | grep sec | awk '{print $$2}' | cut -d'/' -f2); \
	echo "GPG Key ID: $$GPG_KEY_ID"; \
	gpg --armor --export $$GPG_KEY_ID > $(ANTHROPIC_DIR)/.gnupg/gpg_key.pub

github-gpg: validate-token gpg-key ## Upload GPG key to GitHub
	@echo "Uploading GPG key to GitHub..."
	@if [ -f "$(ANTHROPIC_DIR)/.gnupg/gpg_key.pub" ]; then \
		if [ -n "$$GITHUB_TOKEN" ]; then \
			curl -X POST -H "Authorization: token $$GITHUB_TOKEN" \
				-H "Content-Type: application/json" \
				-d "{\"armored_public_key\": \"$$(cat $(ANTHROPIC_DIR)/.gnupg/gpg_key.pub)\"}" \
				https://api.github.com/user/gpg_keys; \
			echo "GPG key uploaded to GitHub"; \
		else \
			echo "Error: GITHUB_TOKEN not set"; \
			exit 1; \
		fi \
	else \
		echo "Error: GPG public key not found"; \
		exit 1; \
	fi
