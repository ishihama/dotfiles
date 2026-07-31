#!/bin/bash
# shell.sh - Set up shell environment (oh-my-zsh and plugins)
# Extracted from init.sh lines 136-157

OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

setup_shell() {
    if is_dry_run; then
        [ -d "$HOME/.oh-my-zsh" ] \
            && log_info "[DRY RUN] oh-my-zsh already installed" \
            || log_info "[DRY RUN] would install oh-my-zsh (KEEP_ZSHRC=yes)"
        log_info "[DRY RUN] would install zsh-autosuggestions and zsh-syntax-highlighting"
        return 0
    fi

    # Install oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing oh-my-zsh..."

        local installer
        installer=$(fetch_installer "$OMZ_INSTALL_URL") || return 1

        # KEEP_ZSHRC=yes is essential: symlinks.sh has already pointed ~/.zshrc at
        # this repo, and without it the installer moves that symlink aside to
        # ~/.zshrc.pre-oh-my-zsh and drops in its own template - so none of the
        # shell modules under .config/shell/ would ever load.
        KEEP_ZSHRC=yes sh "$installer" --unattended
        local rc=$?
        rm -f "$installer"

        if [ $rc -ne 0 ]; then
            log_error "oh-my-zsh installation failed (exit $rc)"
            return 1
        fi
        log_success "oh-my-zsh installed"
    else
        log_skip "oh-my-zsh already installed"
    fi

    # Install zsh plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    clone_zsh_plugin zsh-autosuggestions \
        https://github.com/zsh-users/zsh-autosuggestions || return 1
    clone_zsh_plugin zsh-syntax-highlighting \
        https://github.com/zsh-users/zsh-syntax-highlighting || return 1
}

clone_zsh_plugin() {
    local name=$1
    local url=$2
    local dest="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

    if [ -d "$dest" ]; then
        log_skip "$name already installed"
        return 0
    fi

    log_info "Installing $name..."
    if git clone --depth 1 "$url" "$dest"; then
        log_success "$name installed"
        return 0
    fi

    log_error "Failed to clone $name"
    return 1
}
