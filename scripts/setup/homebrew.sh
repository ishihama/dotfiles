#!/bin/bash
# homebrew.sh - Install Homebrew and packages
# Extracted from init.sh lines 73-96

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Linuxbrew install locations: the shared prefix the installer uses when it can
# sudo, then the per-user fallback.
LINUXBREW_CANDIDATES=(
    /home/linuxbrew/.linuxbrew/bin/brew
    "$HOME/.linuxbrew/bin/brew"
)

# Put an installed-but-not-on-PATH Linuxbrew on PATH for the rest of this run.
# Linuxbrew is only added to PATH by .zshrc.linux, so a re-run of init.sh from
# bash (the default login shell on a fresh Ubuntu) would otherwise not see it.
load_linuxbrew_shellenv() {
    local brew_bin
    for brew_bin in "${LINUXBREW_CANDIDATES[@]}"; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

# Third-party formulae used by the Brewfile ("brew \"owner/tap/name\"").
brewfile_tap_formulae() {
    sed -n 's/^[[:space:]]*brew "\([^"/]*\/[^"/]*\/[^"]*\)".*/\1/p' "$DOTFILES_DIR/Brewfile"
}

# Homebrew 7 refuses to load formulae from non-official taps until they are
# trusted ("Refusing to load formula ... from untrusted tap"), which made
# brew bundle skip gwq and sdkman-cli.
#
# Trusting is a security decision: a trusted formula is Ruby that Homebrew runs
# on install/upgrade, and the trust is recorded by name only, so a later change
# to the tap is trusted too. So ask per formula (default No) instead of doing it
# silently, and only for formulae the Brewfile names - never whole taps.
# Already-trusted formulae are not asked again. Older Homebrew has no
# `brew trust` and needs none.
#
# The trust store lives under $XDG_CONFIG_HOME when it is set, and env.sh sets
# it for every zsh. Pin the same value here so later `brew upgrade` runs from
# zsh read the store this bash run wrote.
brew_trust() {
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" brew trust "$@"
}

# owner/tap/name -> https://github.com/owner/homebrew-tap (Homebrew's naming rule)
tap_repo_url() {
    local formula=$1
    local owner=${formula%%/*}
    local rest=${formula#*/}
    printf 'https://github.com/%s/homebrew-%s\n' "$owner" "${rest%%/*}"
}

trust_brewfile_formulae() {
    brew help trust >/dev/null 2>&1 || return 0

    # Collect first: confirm() reads stdin, so the prompt must not run inside a
    # loop whose stdin is the formula list. (No mapfile - macOS /bin/bash is 3.2.)
    local formulae=() formula
    while IFS= read -r formula; do
        [ -n "$formula" ] && formulae+=("$formula")
    done < <(brewfile_tap_formulae)
    [ "${#formulae[@]}" -gt 0 ] || return 0

    local trusted
    trusted=$(brew_trust --json=v1 2>/dev/null || true)

    for formula in "${formulae[@]}"; do
        if printf '%s' "$trusted" | grep -qF "\"$formula\""; then
            log_skip "Already trusted: $formula"
            continue
        fi

        log_info "Homebrew 7+ requires trusting third-party formula: $formula"
        log_info "  Source: $(tap_repo_url "$formula")"
        if ! confirm "Trust $formula? (Homebrew will run its Ruby on install/upgrade)" "n"; then
            log_warn "Not trusted: $formula (brew bundle will skip it; trust later with: brew trust --formula $formula)"
            continue
        fi

        if brew_trust --formula "$formula" >/dev/null 2>&1; then
            log_success "Trusted: $formula"
        else
            log_warn "Failed to trust $formula; brew bundle may skip it"
        fi
    done
}

setup_homebrew() {
    if [ "$(uname -s)" = Linux ] && ! command_exists brew; then
        load_linuxbrew_shellenv || true
    fi

    if is_dry_run; then
        if command_exists brew; then
            log_info "[DRY RUN] Homebrew already installed"
        else
            log_info "[DRY RUN] would install Homebrew"
        fi
        local formula
        while IFS= read -r formula; do
            log_info "[DRY RUN] would ask before: brew trust --formula $formula (Homebrew 7+ only)"
        done < <(brewfile_tap_formulae)
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
        else
            # Linuxbrew: without this, the brew bundle below fails with
            # "brew: command not found" in the same run.
            load_linuxbrew_shellenv || true
        fi
        log_success "Homebrew installed"
    else
        log_skip "Homebrew already installed"
    fi

    trust_brewfile_formulae

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
