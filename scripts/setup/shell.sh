#!/bin/bash
# shell.sh - Set up shell environment (oh-my-zsh and plugins)
# Extracted from init.sh lines 136-157

OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

setup_shell() {
    if is_dry_run; then
        if [ -d "$HOME/.oh-my-zsh" ]; then
            log_info "[DRY RUN] oh-my-zsh already installed"
        else
            log_info "[DRY RUN] would install oh-my-zsh (KEEP_ZSHRC=yes)"
        fi
        log_info "[DRY RUN] would install zsh-autosuggestions and zsh-syntax-highlighting"
        ensure_login_shell_zsh
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

    ensure_login_shell_zsh
}

# Make zsh the login shell on Linux/WSL. A fresh Ubuntu (WSL included) starts
# users on bash, which never reads ~/.zshrc. macOS has defaulted to zsh since
# Catalina, so it is left alone there.
#
# Only a zsh listed in /etc/shells is used: chsh refuses anything else, and
# Linuxbrew's zsh is not registered there. Failing to switch is a warning, not
# a setup failure - everything else still works from an explicit `zsh`.
ensure_login_shell_zsh() {
    [ "$(uname -s)" = Linux ] || return 0

    local user current
    user=$(id -un)
    current=$(getent passwd "$user" | cut -d: -f7)
    if [ "${current##*/}" = zsh ]; then
        log_skip "Login shell is already zsh ($current)"
        return 0
    fi

    local zsh_path="" candidate
    for candidate in /usr/bin/zsh /bin/zsh; do
        if [ -x "$candidate" ] && grep -qx "$candidate" /etc/shells 2>/dev/null; then
            zsh_path=$candidate
            break
        fi
    done
    if [ -z "$zsh_path" ]; then
        zsh_path=$(grep -E '/zsh$' /etc/shells 2>/dev/null | head -n 1 || true)
    fi
    if [ -z "$zsh_path" ] || [ ! -x "$zsh_path" ]; then
        log_warn "No zsh registered in /etc/shells; login shell stays ${current:-unknown}"
        log_info "  Fix: sudo apt install zsh && chsh -s /usr/bin/zsh"
        return 0
    fi

    log_info "Changing login shell: ${current:-unknown} -> $zsh_path"
    if run_cmd chsh -s "$zsh_path"; then
        is_dry_run || log_success "Login shell set to $zsh_path (takes effect on next login)"
    else
        log_warn "chsh failed; run it manually: chsh -s $zsh_path"
    fi
    return 0
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
