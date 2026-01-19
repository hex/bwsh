#!/usr/bin/env bash
# ABOUTME: Installation script for bwsh (Bitwarden Secrets Manager shell wrapper)
# ABOUTME: Installs binary, completions, and optionally configures credentials

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;36m'
DIM='\033[2m'
NC='\033[0m'

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

# Configuration
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/bwsh"
BASH_COMPLETION_DIR="${HOME}/.bash_completion.d"
ZSH_COMPLETION_DIR="${HOME}/.zsh/completions"
REPO_URL="https://raw.githubusercontent.com/hex/bwsh/main"

# Detect if running from cloned repo or web install
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [[ -n "$SCRIPT_DIR" ]] && [[ -f "$SCRIPT_DIR/bin/bwsh" ]]; then
    INSTALL_METHOD="local"
else
    INSTALL_METHOD="web"
fi

# Check for required dependencies
info "Checking dependencies..."

if ! command -v bws >/dev/null 2>&1; then
    warn "bws (Bitwarden Secrets Manager CLI) not found"
    warn "Install from: https://bitwarden.com/help/secrets-manager-cli/"
    echo ""
fi

if ! command -v jq >/dev/null 2>&1; then
    error "jq is required. Install with: brew install jq"
fi

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$BASH_COMPLETION_DIR"
mkdir -p "$ZSH_COMPLETION_DIR"

# Install bwsh script
info "Installing bwsh to $INSTALL_DIR/bwsh"

if [[ "$INSTALL_METHOD" = "local" ]]; then
    cp "$SCRIPT_DIR/bin/bwsh" "$INSTALL_DIR/bwsh"
else
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/bin/bwsh" -o "$INSTALL_DIR/bwsh" || error "Failed to download bwsh"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/bin/bwsh" -O "$INSTALL_DIR/bwsh" || error "Failed to download bwsh"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
fi

chmod +x "$INSTALL_DIR/bwsh"

# Install bash completion
info "Installing bash completion to $BASH_COMPLETION_DIR/bwsh.bash"

if [[ "$INSTALL_METHOD" = "local" ]]; then
    cp "$SCRIPT_DIR/completions/bwsh.bash" "$BASH_COMPLETION_DIR/"
else
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/completions/bwsh.bash" -o "$BASH_COMPLETION_DIR/bwsh.bash" || warn "Failed to download bash completion"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/completions/bwsh.bash" -O "$BASH_COMPLETION_DIR/bwsh.bash" || warn "Failed to download bash completion"
    fi
fi

# Install zsh completion
info "Installing zsh completion to $ZSH_COMPLETION_DIR/_bwsh"

if [[ "$INSTALL_METHOD" = "local" ]]; then
    cp "$SCRIPT_DIR/completions/_bwsh" "$ZSH_COMPLETION_DIR/"
else
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/completions/_bwsh" -o "$ZSH_COMPLETION_DIR/_bwsh" || warn "Failed to download zsh completion"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/completions/_bwsh" -O "$ZSH_COMPLETION_DIR/_bwsh" || warn "Failed to download zsh completion"
    fi
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    warn ""
    warn "WARNING: $INSTALL_DIR is not in your PATH"
    warn ""
    warn "Add this line to your ~/.bashrc, ~/.zshrc, or equivalent:"
    warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    warn ""
fi

# Optional: run setup for credentials
echo ""
read -p "Would you like to configure credentials now? [y/N] " setup_creds
if [[ "$setup_creds" =~ ^[Yy]$ ]]; then
    echo ""
    "$INSTALL_DIR/bwsh" setup
fi

# Success message
echo ""
info "Installation complete!"
echo ""
echo -e "${DIM}+----------------------------------------------------------+${NC}"
echo -e "${DIM}|${NC} ${LIGHT_BLUE}Installed:${NC}"
echo -e "${DIM}|${NC}   - bwsh to $INSTALL_DIR/bwsh"
echo -e "${DIM}|${NC}   - bash completion to $BASH_COMPLETION_DIR/bwsh.bash"
echo -e "${DIM}|${NC}   - zsh completion to $ZSH_COMPLETION_DIR/_bwsh"
echo -e "${DIM}+----------------------------------------------------------+${NC}"
echo ""

# Shell integration instructions
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    bash)
        echo "To enable shell functions and completion, add to ~/.bashrc:"
        echo ""
        echo "  # bwsh - Bitwarden Secrets Manager wrapper"
        echo "  [[ -f ~/.local/bin/bwsh ]] && source ~/.local/bin/bwsh"
        echo "  [[ -f ~/.bash_completion.d/bwsh.bash ]] && source ~/.bash_completion.d/bwsh.bash"
        echo ""
        ;;
    zsh)
        echo "To enable shell functions and completion, add to ~/.zshrc:"
        echo ""
        echo "  # bwsh - Bitwarden Secrets Manager wrapper"
        echo "  [[ -f ~/.local/bin/bwsh ]] && source ~/.local/bin/bwsh"
        echo "  fpath=(~/.zsh/completions \$fpath)"
        echo "  autoload -Uz compinit && compinit"
        echo ""
        ;;
    *)
        echo "To enable shell functions, add to your shell rc file:"
        echo ""
        echo "  source ~/.local/bin/bwsh"
        echo ""
        ;;
esac

echo "Usage examples:"
echo "  bwsh get API_KEY        # Get a secret (CLI mode)"
echo "  bwsh set API_KEY value  # Set a secret (CLI mode)"
echo "  bwgetkey API_KEY        # Get a secret (function mode, after sourcing)"
echo "  bwkey API_KEY value     # Set a secret (function mode)"
echo ""
