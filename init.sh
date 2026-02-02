#!/bin/bash
# init.sh - Dotfiles setup orchestrator
# This script coordinates the setup process using modular scripts

set -euo pipefail

# Determine script directory
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Load core libraries
source "$SCRIPTS_DIR/lib/core.sh"
source "$SCRIPTS_DIR/lib/platform.sh"

# Set up error handling
trap 'error_handler $? $LINENO' ERR

# Main setup function
main() {
    log_header "Dotfiles Setup"
    log_info "Platform: $(detect_platform)"
    log_info "Source: $DOTFILES_DIR"
    echo

    # Execute setup modules in order
    run_setup_module "symlinks" "Symlinking dotfiles"
    run_setup_module "homebrew" "Installing Homebrew packages"
    run_setup_module "shell" "Setting up shell environment"
    run_setup_module "git" "Configuring Git"
    run_setup_module "tools" "Installing additional tools"

    # Validation
    echo
    log_section "Validation"
    if [ -f "$SCRIPTS_DIR/validate.sh" ]; then
        "$SCRIPTS_DIR/validate.sh"
    else
        log_warn "Validation script not found (will be available in Phase 6)"
    fi

    # Success
    echo
    log_success "Setup complete!"
    print_next_steps
}

# Print helpful next steps
print_next_steps() {
    echo
    echo "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Run 'setup-completions' to enable CLI completions"
    echo "  3. Launch Neovim - plugins will auto-install"
    echo
}

# Run main
main "$@"
