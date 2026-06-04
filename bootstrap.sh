#!/bin/bash
# bootstrap.sh - New Mac entry point for dotfiles setup
# Clones the repository to the ghq-compatible path and runs init.sh
#
# Usage (on a fresh Mac):
#   curl -fsSL https://raw.githubusercontent.com/ishihama/dotfiles/main/bootstrap.sh | bash
#
# Standalone by design: does NOT depend on scripts/lib/core.sh
# (the repository may not be cloned yet when this script runs)

set -euo pipefail

# Repository location (must match ghq root and Git includeIf directory structure)
REPO_OWNER="ishihama"
REPO_NAME="dotfiles"
DOTFILES_DIR="$HOME/repos/github.com/$REPO_OWNER/$REPO_NAME"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME.git"

# Color codes for output (same palette as scripts/lib/core.sh)
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'

log_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}===================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}$1${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}===================================================${COLOR_RESET}"
}

log_info() {
    echo -e "${COLOR_CYAN}ℹ $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}" >&2
}

log_skip() {
    echo -e "${COLOR_YELLOW}⊘ $1${COLOR_RESET}"
}

main() {
    log_header "Dotfiles Bootstrap"

    # 1. Xcode Command Line Tools (provides git, required by Homebrew too)
    if xcode-select -p >/dev/null 2>&1; then
        log_skip "Xcode Command Line Tools already installed"
    else
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warn "Complete the installation in the dialog, then re-run this script:"
        echo
        echo "  curl -fsSL https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/bootstrap.sh | bash"
        echo
        exit 1
    fi

    # 2. Clone the repository via HTTPS (no SSH key required yet)
    if [ -d "$DOTFILES_DIR" ]; then
        log_skip "Repository already exists: $DOTFILES_DIR"
    else
        log_info "Cloning $REPO_URL to $DOTFILES_DIR"
        mkdir -p "$(dirname "$DOTFILES_DIR")"
        git clone "$REPO_URL" "$DOTFILES_DIR"
        log_success "Repository cloned"
    fi

    # 3. Run init.sh (restore stdin to the terminal so interactive
    #    Git setup prompts work even when piped via `curl | bash`)
    log_info "Running init.sh..."
    cd "$DOTFILES_DIR"
    if [ ! -t 0 ] && (: < /dev/tty) 2>/dev/null; then
        exec ./init.sh "$@" < /dev/tty
    else
        exec ./init.sh "$@"
    fi
}

main "$@"
