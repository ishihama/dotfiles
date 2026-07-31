#!/bin/bash
# init.sh - Dotfiles setup orchestrator
# This script coordinates the setup process using modular scripts

# -E so the ERR trap below is inherited by shell functions; without it
# error_handler never fires.
set -Eeuo pipefail

# Determine script directory
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            export DRY_RUN=true
            ;;
    esac
done

# Load core libraries
source "$SCRIPTS_DIR/lib/core.sh"
source "$SCRIPTS_DIR/lib/platform.sh"

# Set up error handling
trap 'error_handler $? $LINENO' ERR

# Main setup function
main() {
    log_header "Dotfiles Setup"
    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE - no changes will be made"
    fi
    log_info "Platform: $(detect_platform)"
    log_info "Source: $DOTFILES_DIR"
    echo

    # Execute setup modules in order
    run_setup_module "symlinks" "Symlinking dotfiles"
    run_setup_module "homebrew" "Installing Homebrew packages"
    run_setup_module "shell" "Setting up shell environment"
    run_setup_module "git" "Configuring Git"
    run_setup_module "tools" "Installing additional tools"

    # Validation. A failing check is worth reporting, but it must not swallow
    # the summary and next-steps output below.
    echo
    log_section "Validation"
    local validation_rc=0
    if [ -f "$SCRIPTS_DIR/validate.sh" ]; then
        "$SCRIPTS_DIR/validate.sh" || validation_rc=$?
    else
        log_warn "Validation script not found"
    fi

    echo
    if [ "$validation_rc" -ne 0 ]; then
        log_warn "Setup finished, but some validations failed (see above)"
    elif is_dry_run; then
        log_success "Dry run complete - no changes were made"
    else
        log_success "Setup complete!"
    fi
    print_next_steps
    return "$validation_rc"
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
