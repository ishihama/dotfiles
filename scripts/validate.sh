#!/bin/bash
# validate.sh - Validate dotfiles setup
# Checks symlinks, commands, and Git configuration

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Load core library for logging
source "$SCRIPTS_DIR/lib/core.sh"

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0

validate_item() {
    local description=$1
    local check_command=$2
    local help_text=${3:-}

    if eval "$check_command" >/dev/null 2>&1; then
        log_success "$description"
        ((VALIDATION_PASSED++)) || true
    else
        log_error "$description"
        if [ -n "$help_text" ]; then
            log_info "  Fix: $help_text"
        fi
        ((VALIDATION_FAILED++)) || true
    fi
}

# Assert that a path is a symlink AND that it points where we expect.
# Checking only -L passes a link left over from a moved or deleted checkout.
validate_link() {
    local target=$1
    local expected=$2
    local label=${3:-$target}

    if [ ! -L "$target" ]; then
        if [ -e "$target" ]; then
            log_error "$label exists but is not a symlink"
        else
            log_error "$label missing"
        fi
        log_info "  Fix: Run ./init.sh to create symlinks"
        ((VALIDATION_FAILED++)) || true
        return
    fi

    local actual
    actual=$(readlink "$target")
    if [ "$actual" != "$expected" ]; then
        log_error "$label points at $actual (expected $expected)"
        log_info "  Fix: Run ./init.sh to recreate symlinks"
        ((VALIDATION_FAILED++)) || true
        return
    fi

    if [ ! -e "$target" ]; then
        log_error "$label is a dangling symlink -> $actual"
        log_info "  Fix: Run ./init.sh to recreate symlinks"
        ((VALIDATION_FAILED++)) || true
        return
    fi

    log_success "$label -> $actual"
    ((VALIDATION_PASSED++)) || true
}

# Validate symlinks
validate_symlinks() {
    log_section "Symlinks (Root Dotfiles)"

    local f
    for f in .zshrc .zshrc.osx .zshrc.linux .zshrc.wsl .editorconfig; do
        [ -f "$DOTFILES_DIR/$f" ] || continue
        validate_link "$HOME/$f" "$DOTFILES_DIR/$f" "~/$f"
    done

    log_section "Symlinks (XDG Config)"

    local d
    for d in atuin claude ghostty git gitmux gwq hammerspoon lazygit mise nvim shell tmux; do
        [ -d "$DOTFILES_DIR/.config/$d" ] || continue
        validate_link "$HOME/.config/$d" "$DOTFILES_DIR/.config/$d" "~/.config/$d"
    done

    validate_link "$HOME/.config/starship.toml" \
        "$DOTFILES_DIR/.config/starship.toml" "~/.config/starship.toml"

    log_section "Symlinks (Extra Locations)"

    validate_link "$HOME/.claude/settings.json" \
        "$DOTFILES_DIR/.config/claude/settings.json" "~/.claude/settings.json"
    validate_link "$HOME/.hammerspoon" \
        "$DOTFILES_DIR/.config/hammerspoon" "~/.hammerspoon"
    if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
        validate_link "$HOME/.ssh/config" "$DOTFILES_DIR/.ssh/config" "~/.ssh/config"
    fi

    log_section "Old Paths Should Not Exist"

    local old_path target
    for old_path in ~/.gitconfig ~/.tmux.conf ~/.gitmessage ~/.gitmux.conf ~/.mise.toml; do
        if [ -L "$old_path" ]; then
            target=$(readlink "$old_path")
            if [ "$target" = "$DOTFILES_DIR" ] || [ "${target#"$DOTFILES_DIR"/}" != "$target" ]; then
                log_warn "Old symlink still exists: $old_path -> $target"
                log_info "  Fix: Run ./init.sh to clean up"
                ((VALIDATION_FAILED++)) || true
                continue
            fi
        elif [ -e "$old_path" ]; then
            # A real file here still wins over the XDG config for git and tmux,
            # so reporting it as "no old symlink" hid a genuinely broken setup.
            log_warn "Real file at legacy path shadows the XDG config: $old_path"
            log_info "  Fix: Move it aside (it takes precedence over ~/.config)"
            ((VALIDATION_FAILED++)) || true
            continue
        fi
        log_success "No old config at $old_path"
        ((VALIDATION_PASSED++)) || true
    done
}

# Validate the standalone popup scripts that tmux.conf binds
validate_popup_scripts() {
    log_section "Popup Scripts"

    local s
    for s in ghq-tmux-popup gwq-tmux-popup tmux-session-fzf-popup claude-sidebar-toggle; do
        validate_item \
            "Executable: $s" \
            "[ -x ~/.config/shell/bin/$s ]" \
            "chmod +x $DOTFILES_DIR/.config/shell/bin/$s"
    done

    validate_item \
        "Executable: claude-status" \
        "[ -x ~/.config/claude/bin/claude-status ]" \
        "chmod +x $DOTFILES_DIR/.config/claude/bin/claude-status"
}

# Validate shell modules
validate_shell_modules() {
    log_section "Shell Modules"

    local modules=(env.sh aliases.sh ghq-tmux.sh gwq-tmux.sh gwq-wrapper.sh gh-wrapper.sh fzf-widgets.sh memo.sh completions.sh platform.sh cheat.sh)
    for module in "${modules[@]}"; do
        validate_item \
            "Shell module: $module" \
            "[ -f ~/.config/shell/$module ]" \
            "Shell module missing: $module"
    done
}

# Validate essential commands
validate_commands() {
    log_section "Essential Commands"

    validate_item \
        "brew installed" \
        "command -v brew" \
        "Install Homebrew: https://brew.sh"

    validate_item \
        "zsh installed" \
        "command -v zsh" \
        "brew install zsh"

    validate_item \
        "tmux installed" \
        "command -v tmux" \
        "brew install tmux"

    validate_item \
        "nvim installed" \
        "command -v nvim" \
        "brew install neovim"

    validate_item \
        "fzf installed" \
        "command -v fzf" \
        "brew install fzf"

    validate_item \
        "ghq installed" \
        "command -v ghq" \
        "brew install ghq"

    validate_item \
        "gwq installed" \
        "command -v gwq" \
        "brew install gwq"

    validate_item \
        "mise installed" \
        "command -v mise" \
        "brew install mise"

    validate_item \
        "bat installed" \
        "command -v bat" \
        "brew install bat"

    validate_item \
        "eza installed" \
        "command -v eza" \
        "brew install eza"

    validate_item \
        "ripgrep installed" \
        "command -v rg" \
        "brew install ripgrep"

    validate_item \
        "delta installed" \
        "command -v delta" \
        "brew install git-delta"
}

# Validate Git configuration
validate_git_config() {
    log_section "Git Configuration"

    validate_item \
        "~/.gitconfig.local exists" \
        "[ -f ~/.gitconfig.local ]" \
        "Run ./init.sh and follow Git setup prompts"

    validate_item \
        "Git commit template points to XDG path" \
        "git config --global commit.template | grep -q '.config/git/message'" \
        "Check ~/.config/git/config commit.template setting"

    # Check if Git user is configured (not the INVALID placeholder)
    local git_user_name=$(git config --global user.name 2>/dev/null || echo "")
    if [ "$git_user_name" != "INVALID" ] && [ "$git_user_name" != "" ]; then
        log_success "Git user.name configured: $git_user_name"
        ((VALIDATION_PASSED++)) || true
    else
        log_warn "Git user.name is INVALID or not set"
        log_info "  This is expected. Git user is set per-directory via includeIf"
        log_info "  Test by running 'git config user.name' in a repository directory"
        # Don't count as failure - this is intentional
        ((VALIDATION_PASSED++)) || true
    fi

    # Check if personal config exists if .gitconfig.local exists
    if [ -f ~/.gitconfig.local ]; then
        if grep -q "gitconfig.personal" ~/.gitconfig.local 2>/dev/null; then
            validate_item \
                "~/.gitconfig.personal exists" \
                "[ -f ~/.gitconfig.personal ]" \
                "Run ./init.sh and follow Git setup prompts"
        fi

        if grep -q "gitconfig.work" ~/.gitconfig.local 2>/dev/null; then
            validate_item \
                "~/.gitconfig.work exists" \
                "[ -f ~/.gitconfig.work ]" \
                "Run ./init.sh and follow Git setup prompts"
        fi
    fi
}

# Validate shell environment
validate_shell() {
    log_section "Shell Environment"

    validate_item \
        "oh-my-zsh installed" \
        "[ -d ~/.oh-my-zsh ]" \
        "Run ./init.sh to install oh-my-zsh"

    validate_item \
        "zsh-autosuggestions installed" \
        "[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]" \
        "Run ./init.sh to install plugins"

    validate_item \
        "zsh-syntax-highlighting installed" \
        "[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]" \
        "Run ./init.sh to install plugins"

    validate_item \
        "TPM installed" \
        "[ -d ~/.tmux/plugins/tpm ]" \
        "Run ./init.sh to install TPM"
}

# Main validation
main() {
    log_header "Dotfiles Validation"
    echo

    validate_symlinks
    echo

    validate_shell_modules
    validate_popup_scripts
    echo

    validate_commands
    echo

    validate_git_config
    echo

    validate_shell
    echo

    # Summary
    log_section "Summary"
    local total=$((VALIDATION_PASSED + VALIDATION_FAILED))
    echo "Passed: $VALIDATION_PASSED / $total"

    if [ $VALIDATION_FAILED -eq 0 ]; then
        log_success "All validations passed!"
        return 0
    else
        echo "Failed: $VALIDATION_FAILED / $total"
        log_warn "Some validations failed. See above for details."
        return 1
    fi
}

main "$@"
