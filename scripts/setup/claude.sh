#!/bin/bash
# claude.sh - Create per-owner Claude Code config directories
#
# For each ~/repos/github.com/<owner>/ prepares ~/.claude-<owner>/, sharing
# settings.json (dotfiles) and CLAUDE.md (~/.claude) with the default account.
# .config/shell/claude-wrapper.sh then sets CLAUDE_CONFIG_DIR per directory
# (and creates the directory on demand for owners cloned later).

setup_claude() {
    local owner_dir owner found=0

    for owner_dir in "$HOME"/repos/github.com/*/; do
        [ -d "$owner_dir" ] || continue
        owner=$(basename "$owner_dir")
        # The owner becomes part of a path under $HOME
        if [[ ! "$owner" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
            log_warn "Skipping invalid owner name: $owner"
            continue
        fi
        found=1

        local config_dir="$HOME/.claude-$owner"
        run_cmd mkdir -p "$config_dir"
        safe_symlink "$DOTFILES_DIR/.config/claude/settings.json" "$config_dir/settings.json"

        # User-level CLAUDE.md is shared. skills/ is not: it holds skills synced
        # from the logged-in org. Login, history, plugins and user-scope MCP
        # (.claude.json) stay per account too.
        if [ -e "$HOME/.claude/CLAUDE.md" ]; then
            safe_symlink "$HOME/.claude/CLAUDE.md" "$config_dir/CLAUDE.md"
        fi

        if [ ! -f "$config_dir/.claude.json" ]; then
            log_info "Log in once: cd into a repo under $owner_dir, run 'claude', then /login"
        fi
    done

    if [ "$found" -eq 0 ]; then
        log_skip "No owners under ~/repos/github.com yet - config dirs are created on first 'claude' run"
    fi
}
