#!/bin/bash
# tools.sh - Install additional tools (delta, TPM, mise)
# Extracted from init.sh lines 99-130, 163-176

setup_tools() {
    # delta catppuccin theme
    log_info "Setting up delta catppuccin theme..."
    mkdir -p ~/.config/delta
    if [ ! -f ~/.config/delta/catppuccin.gitconfig ]; then
        log_info "Downloading catppuccin theme for delta..."
        if curl -sL https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig -o ~/.config/delta/catppuccin.gitconfig; then
            log_success "delta catppuccin theme installed"
        else
            log_warn "Failed to download delta catppuccin theme"
        fi
    else
        log_skip "delta catppuccin theme already installed"
    fi

    # TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "Installing TPM..."
        if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
            log_success "TPM installed"
        else
            log_warn "Failed to install TPM"
        fi
    else
        log_skip "TPM already installed"
    fi

    # Install/update tmux plugins
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "Installing tmux plugins..."
        if "$HOME/.tmux/plugins/tpm/bin/install_plugins"; then
            log_success "tmux plugins installed"
        else
            log_warn "Some tmux plugins may have failed to install"
        fi
    fi

    # mise
    if command_exists mise; then
        log_info "Setting up mise..."
        cd "$DOTFILES_DIR" || return 1
        mise trust --all
        if mise install; then
            log_success "mise setup complete"
        else
            log_warn "mise install failed (some tools may be missing)"
        fi
        cd - > /dev/null || return 1
    else
        log_warn "mise not found. Run 'brew bundle' first."
    fi
}
