#!/bin/bash
# homebrew.sh - Install Homebrew and packages
# Extracted from init.sh lines 73-96

setup_homebrew() {
    # Install Homebrew if not present
    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
