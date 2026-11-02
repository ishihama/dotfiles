#!/bin/zsh
# claude-wrapper.sh - Auto-switch Claude Code account based on repos directory structure
# Inside ~/repos/github.com/<owner>/, CLAUDE_CONFIG_DIR=~/.claude-<owner>, so the
# canonical checkout and every gwq worktree ({repo}@{branch}) of an owner share
# one account. The directory is created on first use (run /login once).
# Everywhere else Claude Code's own ~/.claude is used.

# Create ~/.claude-<owner> with the shared settings.json / CLAUDE.md links
function _claude_init_config_dir() {
    local config_dir="$1"
    command mkdir -p "$config_dir" || return 1
    local settings="$HOME/.config/claude/settings.json"
    [[ -e "$settings" && ! -e "$config_dir/settings.json" ]] && command ln -s "$settings" "$config_dir/settings.json"
    [[ -e "$HOME/.claude/CLAUDE.md" && ! -e "$config_dir/CLAUDE.md" ]] && command ln -s "$HOME/.claude/CLAUDE.md" "$config_dir/CLAUDE.md"
    print -u2 "claude: created new config $config_dir (run /login once)"
}

function claude() {
    # An explicit CLAUDE_CONFIG_DIR (e.g. `CLAUDE_CONFIG_DIR=... claude`) wins
    if [[ -z "$CLAUDE_CONFIG_DIR" && "$PWD/" =~ "^$HOME/repos/github\.com/([A-Za-z0-9][A-Za-z0-9._-]*)/" ]]; then
        local config_dir="$HOME/.claude-${match[1]}"
        [[ -d "$config_dir" ]] || _claude_init_config_dir "$config_dir" || return 1
        CLAUDE_CONFIG_DIR="$config_dir" command claude "$@"
        return
    fi

    command claude "$@"
}
