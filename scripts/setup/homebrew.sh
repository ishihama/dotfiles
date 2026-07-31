#!/bin/bash
# homebrew.sh - Install Homebrew and packages
# Extracted from init.sh lines 73-96

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

setup_homebrew() {
    if is_dry_run; then
        command_exists brew \
            && log_info "[DRY RUN] Homebrew already installed" \
            || log_info "[DRY RUN] would install Homebrew"
        log_info "[DRY RUN] would run: brew bundle --file=$DOTFILES_DIR/Brewfile"
        log_info "[DRY RUN] would install the benelan/gh-fzf gh extension"
        return 0
    fi

    # Install Homebrew if not present
    if ! command_exists brew; then
        log_info "Installing Homebrew..."

        local installer
        installer=$(fetch_installer "$BREW_INSTALL_URL") || return 1
        /bin/bash "$installer"
        local rc=$?
        rm -f "$installer"

        if [ $rc -ne 0 ]; then
            log_error "Homebrew installation failed (exit $rc)"
            return 1
        fi

        # Add Homebrew to PATH for this session
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        log_success "Homebrew installed"
    else
        log_skip "Homebrew already installed"
    fi

    # Install packages from Brewfile
    log_info "Running brew bundle..."
    if brew bundle --file="$DOTFILES_DIR/Brewfile"; then
        log_success "Homebrew packages installed"
    else
        log_warn "Some Homebrew packages may have failed to install"
    fi

    # Install gh extensions
    if command_exists gh; then
        log_info "Installing gh extensions..."
        if gh extension list | grep -q "benelan/gh-fzf"; then
            log_skip "gh-fzf already installed"
        else
            if gh extension install benelan/gh-fzf 2>/dev/null; then
                log_success "Installed gh-fzf extension"
            else
                log_warn "Failed to install gh-fzf extension (may already exist)"
            fi
        fi
    else
        log_warn "gh command not found, skipping extensions"
    fi
}
