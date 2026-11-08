#!/bin/bash
# windows_terminal.sh - Configure Windows Terminal from WSL (WSL only)
#
# Windows Terminal owns its settings.json and rewrites it from the GUI, and it
# cannot follow a symlink into \\wsl$, so the dotfiles side is a partial config
# (.config/windows-terminal/settings.json) merged into the real file:
#   - a "Ubuntu (tmux)" profile (fixed GUID) that attaches to tmux session
#     "main", made the default profile - same as Ghostty's `command`
#   - the Catppuccin Mocha scheme
#   - Alt+key -> tmux prefix (Ctrl+T) sequences, the Windows stand-in for
#     Ghostty's Cmd+key bindings (Win+key is taken by the OS)
# Everything else in the user's settings.json is left alone, so re-running is
# idempotent and GUI edits survive.

WT_DOTFILES_CONFIG="$DOTFILES_DIR/.config/windows-terminal/settings.json"
WT_ACTION_PREFIX="User.dotfiles."
WT_FONT_FAMILY="JetBrainsMono Nerd Font"
WT_FONT_WINGET_ID="DEVCOM.JetBrainsMonoNerdFont"

setup_windows_terminal() {
    if ! is_wsl; then
        log_skip "Not WSL, skipping Windows Terminal"
        return 0
    fi

    if ! command_exists jq; then
        log_warn "jq not found, skipping Windows Terminal. Run 'brew bundle' first."
        return 0
    fi

    wt_install_font

    local settings
    if ! settings=$(wt_find_settings); then
        log_warn "Windows Terminal settings.json not found. Launch Windows Terminal once, then re-run init.sh."
        return 0
    fi
    log_info "Windows Terminal settings: $settings"

    wt_merge_settings "$settings"
}

# Print %LOCALAPPDATA% as a WSL path. cmd.exe prints in the console code page
# (CP932 on Japanese Windows), which garbles a non-ASCII user name, so ask
# PowerShell for UTF-8 explicitly.
wt_localappdata() {
    local win_path
    # shellcheck disable=SC2016  # PowerShell expression, not shell
    win_path=$(powershell.exe -NoProfile -NonInteractive -Command \
        '[Console]::OutputEncoding=[Text.Encoding]::UTF8; $env:LOCALAPPDATA' 2>/dev/null | tr -d '\r')
    [ -n "$win_path" ] || return 1
    wslpath -u "$win_path"
}

wt_find_settings() {
    local localappdata
    localappdata=$(wt_localappdata) || return 1

    local candidate
    for candidate in \
        "$localappdata/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
        "$localappdata/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json" \
        "$localappdata/Microsoft/Windows Terminal/settings.json"; do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

wt_merge_settings() {
    local settings=$1

    # `-e` below bypasses the login shell, so PATH has no Linuxbrew yet:
    # resolve tmux now. tmux then starts the login shell for each pane.
    local tmux_bin
    if ! tmux_bin=$(command -v tmux); then
        log_warn "tmux not found, skipping Windows Terminal. Run 'brew bundle' first."
        return 0
    fi
    local distro=${WSL_DISTRO_NAME:-}
    if [ -z "$distro" ]; then
        log_warn "WSL_DISTRO_NAME is not set, skipping Windows Terminal"
        return 0
    fi
    local commandline="wsl.exe -d $distro --cd ~ -e $tmux_bin new-session -A -s main"

    if ! jq -e . "$settings" >/dev/null 2>&1; then
        # Windows Terminal accepts JSON with comments; jq does not.
        log_warn "Cannot parse $settings as plain JSON (comments?), skipping Windows Terminal"
        return 0
    fi
    if ! jq -e '.profiles | type == "object"' "$settings" >/dev/null; then
        log_warn "Unsupported profiles layout in $settings (expected {defaults, list}), skipping"
        return 0
    fi

    local tmp
    tmp=$(mktemp) || return 1

    # shellcheck disable=SC2016  # jq program, not shell
    if ! jq --indent 4 \
        --slurpfile d "$WT_DOTFILES_CONFIG" \
        --arg cmd "$commandline" \
        --arg prefix "$WT_ACTION_PREFIX" '
        $d[0] as $d
        | ($d.tmuxKeys | map({
              command: { action: "sendInput", input: ("\u0014" + .input) },
              id: ($prefix + "tmux." + .name)
          })) as $actions
        | ($d.tmuxKeys | map((.keys | if type == "array" then .[] else . end) as $k
              | { keys: $k, id: ($prefix + "tmux." + .name) })) as $bindings
        | ($bindings | map(.keys | ascii_downcase)) as $ourKeys
        | def ours: (.id // "") | startswith($prefix);
          . + $d.globals
        | .defaultProfile = $d.profile.guid
        | .profiles.list = ([$d.profile + { commandline: $cmd }]
              + ((.profiles.list // []) | map(select(.guid != $d.profile.guid))))
        | .schemes = (((.schemes // []) | map(select(.name != $d.scheme.name))) + [$d.scheme])
        | .actions = (((.actions // []) | map(select(ours | not))) + $actions)
        | .keybindings = (((.keybindings // [])
              | map(select((ours | not)
                  and (((.keys // "") | ascii_downcase) as $k | $ourKeys | index($k) | not))))
              + $bindings)
        ' "$settings" > "$tmp" || ! jq -e . "$tmp" >/dev/null 2>&1; then
        log_error "Failed to merge Windows Terminal settings"
        rm -f "$tmp"
        return 1
    fi

    # Windows Terminal rewrites settings.json on every load and reorders
    # actions/keybindings, so compare them as sets.
    local canon='(.actions // []) |= sort_by(.id) | (.keybindings // []) |= sort_by(.id, .keys)'
    if jq -S "$canon" "$settings" | cmp -s - <(jq -S "$canon" "$tmp"); then
        rm -f "$tmp"
        log_skip "Windows Terminal settings already up to date"
        return 0
    fi

    if is_dry_run; then
        log_info "[DRY RUN] would update $settings:"
        diff -u <(jq -S "$canon" "$settings") <(jq -S "$canon" "$tmp") || true
        rm -f "$tmp"
        return 0
    fi

    if ! backup_path "$settings"; then
        rm -f "$tmp"
        return 1
    fi
    # Windows Terminal hot-reloads settings.json and shows an error for a
    # half-written file, so stage the result next to it and rename.
    local staged
    if ! staged=$(mktemp "$(dirname "$settings")/settings.json.tmp.XXXXXX") \
        || ! cp "$tmp" "$staged" || ! mv "$staged" "$settings"; then
        log_error "Failed to write $settings"
        rm -f "$tmp" ${staged:+"$staged"}
        return 1
    fi
    rm -f "$tmp"
    log_success "Windows Terminal settings updated (default profile: Ubuntu (tmux))"
}

wt_font_installed() {
    local hive
    for hive in HKCU HKLM; do
        # Font names are ASCII, so the CP932 output is safe to grep
        if reg.exe query "$hive\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" 2>/dev/null \
            | grep -a -q -i "$WT_FONT_FAMILY"; then
            return 0
        fi
    done
    return 1
}

# The profile uses JetBrainsMono Nerd Font like Ghostty. The winget package is
# a community-maintained MSI (machine-wide, UAC prompt), so ask first.
wt_install_font() {
    if wt_font_installed; then
        log_skip "$WT_FONT_FAMILY already installed on Windows"
        return 0
    fi
    if is_dry_run; then
        log_info "[DRY RUN] would offer: winget.exe install --id $WT_FONT_WINGET_ID"
        return 0
    fi
    if ! command_exists winget.exe; then
        log_warn "$WT_FONT_FAMILY is not installed and winget.exe is unavailable; Windows Terminal will fall back to its default font"
        return 0
    fi
    if ! confirm "Install $WT_FONT_FAMILY on Windows via winget ($WT_FONT_WINGET_ID, needs admin)?"; then
        log_skip "Skipped font install; Windows Terminal will fall back to its default font"
        return 0
    fi
    if winget.exe install --id "$WT_FONT_WINGET_ID" -e \
        --accept-source-agreements --accept-package-agreements; then
        log_success "$WT_FONT_FAMILY installed (restart Windows Terminal to pick it up)"
    else
        log_warn "Font install failed; Windows Terminal will fall back to its default font"
    fi
}
