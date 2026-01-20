#!/usr/bin/env bash
# ABOUTME: Installation script for bwsh (Bitwarden Secrets Manager shell wrapper)
# ABOUTME: Installs binary and shell completions

set -euo pipefail

# Colors - warm palette (orange/yellow)
RED='\033[38;2;247;118;142m'
GREEN='\033[38;2;158;206;106m'
YELLOW='\033[38;2;224;175;104m'
ORANGE='\033[38;2;255;158;100m'
GOLD='\033[38;2;255;199;119m'
BLUE='\033[38;2;122;162;247m'
COMMENT='\033[38;2;86;95;137m'
NC='\033[0m'

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

installed() {
    echo -e "   ${COMMENT}Installed${NC} $1 ${COMMENT}→${NC} ${GOLD}$2${NC}"
}

show_banner() {
    echo ""
    echo -e "   ${ORANGE}╭─────────────╮${NC}"
    echo -e "   ${ORANGE}│${NC}    ${GOLD}bwsh${NC}     ${GOLD}│${NC}"
    echo -e "   ${GOLD}╰─────────────╯${NC}"
    echo ""
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
if ! command -v jq >/dev/null 2>&1; then
    error "jq is required. Install with: brew install jq"
fi

if ! command -v bws >/dev/null 2>&1; then
    warn "   bws (Bitwarden Secrets Manager CLI) not found"
    warn "   Install from: https://bitwarden.com/help/secrets-manager-cli/"
    echo ""
fi

# Show banner
show_banner

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$BASH_COMPLETION_DIR"
mkdir -p "$ZSH_COMPLETION_DIR"

# Install bwsh script
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
installed "bwsh" "$INSTALL_DIR/bwsh"

# Install bash completion
if [[ "$INSTALL_METHOD" = "local" ]]; then
    cp "$SCRIPT_DIR/completions/bwsh.bash" "$BASH_COMPLETION_DIR/"
else
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/completions/bwsh.bash" -o "$BASH_COMPLETION_DIR/bwsh.bash" 2>/dev/null || true
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/completions/bwsh.bash" -O "$BASH_COMPLETION_DIR/bwsh.bash" 2>/dev/null || true
    fi
fi

# Install zsh completion
if [[ "$INSTALL_METHOD" = "local" ]]; then
    cp "$SCRIPT_DIR/completions/_bwsh" "$ZSH_COMPLETION_DIR/"
else
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/completions/_bwsh" -o "$ZSH_COMPLETION_DIR/_bwsh" 2>/dev/null || true
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/completions/_bwsh" -O "$ZSH_COMPLETION_DIR/_bwsh" 2>/dev/null || true
    fi
fi
installed "completions" "bash, zsh"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    warn "   WARNING: $INSTALL_DIR is not in your PATH"
    echo ""
    warn "   Add this line to your ~/.bashrc, ~/.zshrc, or equivalent:"
    warn "     export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Get version for completion message
BWSH_VERSION=$(grep -m1 "^BWSH_VERSION=" "$INSTALL_DIR/bwsh" 2>/dev/null | cut -d'"' -f2 || echo "unknown")

echo ""
echo -e "   ${GREEN}✓${NC} ${BLUE}Installation complete${NC} ${COMMENT}(${BWSH_VERSION})${NC}"
echo ""

# Check if completion setup is needed
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    bash)
        if ! grep -q 'source.*bwsh' "$HOME/.bashrc" 2>/dev/null; then
            warn "   To enable shell functions, add to ~/.bashrc:"
            warn "     [[ -f ~/.local/bin/bwsh ]] && source ~/.local/bin/bwsh"
            echo ""
        fi
        ;;
    zsh)
        if ! grep -q 'source.*bwsh' "$HOME/.zshrc" 2>/dev/null; then
            warn "   To enable shell functions, add to ~/.zshrc:"
            warn "     [[ -f ~/.local/bin/bwsh ]] && source ~/.local/bin/bwsh"
            echo ""
        fi
        ;;
esac

echo -e "   ${ORANGE}Usage:${NC} bwsh ${GOLD}<command>${NC}"
echo ""
echo -e "   ${COMMENT}Examples:${NC}"
echo -e "     ${COMMENT}bwsh${NC} ${GOLD}get API_KEY${NC}        ${COMMENT}# Get a secret${NC}"
echo -e "     ${COMMENT}bwsh${NC} ${GOLD}set API_KEY value${NC}  ${COMMENT}# Set a secret${NC}"
echo -e "     ${COMMENT}bwsh${NC} ${GOLD}setup${NC}              ${COMMENT}# Configure credentials${NC}"
echo ""
