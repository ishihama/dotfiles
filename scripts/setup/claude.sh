#!/bin/bash
# claude.sh - Create per-account Claude Code config directories
#
# Reads ~/.config/claude-accounts/account-map (NOT git-managed):
#   <owner> <profile>    (owner `*` = any other owner, profile `default` = ~/.claude)
# and prepares ~/.claude-<profile>/ for each profile, sharing settings.json
# (dotfiles) and CLAUDE.md (~/.claude) with the default account.
# .config/shell/claude-wrapper.sh then sets CLAUDE_CONFIG_DIR per directory.

CLAUDE_ACCOUNT_MAP="$HOME/.config/claude-accounts/account-map"

setup_claude() {
    if [ ! -f "$CLAUDE_ACCOUNT_MAP" ]; then
        log_skip "No $CLAUDE_ACCOUNT_MAP - every directory uses ~/.claude"
        log_info "To add an account: echo '<owner> <profile>' >> $CLAUDE_ACCOUNT_MAP and re-run"
        return 0
    fi

    local profiles profile
    profiles=$(awk '$1 !~ /^#/ && NF >= 2 && $2 != "default" { print $2 }' "$CLAUDE_ACCOUNT_MAP" | sort -u)

    for profile in $profiles; do
        # The profile becomes part of a path under $HOME
        if [[ ! "$profile" =~ ^[A-Za-z0-9_-]+$ ]]; then
            log_warn "Skipping invalid profile name: $profile"
            continue
        fi

        local config_dir="$HOME/.claude-$profile"
        run_cmd mkdir -p "$config_dir"
        safe_symlink "$DOTFILES_DIR/.config/claude/settings.json" "$config_dir/settings.json"

        # User-level CLAUDE.md is shared. skills/ is not: it holds skills synced
        # from the logged-in org. Login, history, plugins and user-scope MCP
        # (.claude.json) stay per account too.
        if [ -e "$HOME/.claude/CLAUDE.md" ]; then
            safe_symlink "$HOME/.claude/CLAUDE.md" "$config_dir/CLAUDE.md"
        fi

        if [ ! -f "$config_dir/.claude.json" ]; then
            log_info "Log in once: cd into a mapped repo, run 'claude', then /login"
        fi
    done
}
