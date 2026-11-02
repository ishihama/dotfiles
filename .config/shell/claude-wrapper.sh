#!/bin/zsh
# claude-wrapper.sh - Auto-switch Claude Code account based on repos directory structure
# Uses ~/repos/github.com/{owner}/ to pick a CLAUDE_CONFIG_DIR, so the canonical
# checkout and every gwq worktree ({repo}@{branch}) of an owner share one account.
#
# ~/.config/claude-accounts/account-map (NOT git-managed) maps owners to profiles:
#   <owner> <profile>    ->  CLAUDE_CONFIG_DIR=~/.claude-<profile>
# Owner `*` matches any owner without its own entry, and profile `default`
# means the default ~/.claude. Unmatched owners and paths outside ~/repos use ~/.claude.
# Profile directories are created by scripts/setup/claude.sh.

function claude() {
    # An explicit CLAUDE_CONFIG_DIR (e.g. `CLAUDE_CONFIG_DIR=... claude`) wins
    if [[ -z "$CLAUDE_CONFIG_DIR" ]]; then
        local account_map="$HOME/.config/claude-accounts/account-map"

        # Extract owner from ~/repos/github.com/{owner}/...
        if [[ -f "$account_map" && "$PWD" =~ "$HOME/repos/github.com/([^/]+)" ]]; then
            local owner="${match[1]}"
            local profile
            profile=$(command awk -v owner="$owner" '
                $1 == owner { print $2; found = 1; exit }
                $1 == "*" && fallback == "" { fallback = $2 }
                END { if (!found) print fallback }' "$account_map")

            if [[ -n "$profile" && "$profile" != "default" ]]; then
                local config_dir="$HOME/.claude-$profile"
                if [[ ! -d "$config_dir" ]]; then
                    print -u2 "claude: $config_dir not found. Run the dotfiles setup (scripts/setup/claude.sh) first."
                    return 1
                fi
                CLAUDE_CONFIG_DIR="$config_dir" command claude "$@"
                return
            fi
        fi
    fi

    command claude "$@"
}
