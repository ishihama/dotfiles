#!/bin/bash
# tools.sh - Install additional tools (delta, TPM, mise)
# Extracted from init.sh lines 99-130, 163-176

setup_tools() {
    if is_dry_run; then
        log_info "[DRY RUN] would download the catppuccin themes for delta and bat"
        log_info "[DRY RUN] would install TPM and its tmux plugins"
        log_info "[DRY RUN] would run: mise trust $DOTFILES_DIR && mise install"
        return 0
    fi

    # delta catppuccin theme
    log_info "Setting up delta catppuccin theme..."
    mkdir -p ~/.config/delta
    if [ ! -f ~/.config/delta/catppuccin.gitconfig ]; then
        log_info "Downloading catppuccin theme for delta..."
        download_git_config \
            "https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig" \
            ~/.config/delta/catppuccin.gitconfig \
            && log_success "delta catppuccin theme installed" \
            || log_warn "Failed to download delta catppuccin theme"
    else
        log_skip "delta catppuccin theme already installed"
    fi

    # bat catppuccin theme (needed for delta's syntax-theme)
    if ! command_exists bat; then
        log_warn "bat not found, skipping catppuccin themes. Run 'brew bundle' first."
    else
        log_info "Setting up bat catppuccin theme..."
        local bat_theme_dir
        bat_theme_dir="$(bat --config-dir)/themes"
        mkdir -p "$bat_theme_dir"
        if [ ! -f "$bat_theme_dir/Catppuccin Mocha.tmTheme" ]; then
            log_info "Downloading catppuccin themes for bat..."
            local base_url="https://github.com/catppuccin/bat/raw/main/themes"
            local download_ok=true
            local theme encoded_theme
            for theme in "Catppuccin Latte" "Catppuccin Frappe" "Catppuccin Macchiato" "Catppuccin Mocha"; do
                encoded_theme="${theme// /%20}"
                if ! curl -fsSL "$base_url/${encoded_theme}.tmTheme" -o "$bat_theme_dir/${theme}.tmTheme"; then
                    log_warn "Failed to download ${theme}.tmTheme"
                    rm -f "$bat_theme_dir/${theme}.tmTheme"
                    download_ok=false
                fi
            done
            if $download_ok; then
                bat cache --build
                log_success "bat catppuccin themes installed"
            else
                log_warn "Some bat themes failed to download"
            fi
        else
            log_skip "bat catppuccin themes already installed"
        fi
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
        # Run in a subshell so a failure part-way through cannot leave the
        # caller's working directory changed.
        # `mise trust --all` would trust every mise config on the machine,
        # including ones inside third-party repos, so scope it to this repo.
        if (
            cd "$DOTFILES_DIR" || exit 1
            mise trust "$DOTFILES_DIR" >/dev/null || exit 1
            mise install
        ); then
            log_success "mise setup complete"
        else
            log_warn "mise install failed (some tools may be missing)"
        fi
    else
        log_warn "mise not found. Run 'brew bundle' first."
    fi
}

# Download a file that git will `include` and verify it actually parses as git
# config before putting it in place. Without this a 404 HTML body lands in
# ~/.config/delta/catppuccin.gitconfig and every later git command dies with
# "fatal: bad config line 1".
download_git_config() {
    local url=$1
    local dest=$2

    local tmp
    tmp=$(mktemp) || return 1

    if ! curl -fsSL "$url" -o "$tmp"; then
        log_error "Download failed: $url"
        rm -f "$tmp"
        return 1
    fi

    if ! git config -f "$tmp" --list >/dev/null 2>&1; then
        log_error "Downloaded file is not valid git config: $url"
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$dest"
}
