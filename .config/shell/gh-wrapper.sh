#!/bin/zsh
# gh-wrapper.sh - Auto-switch gh CLI account based on repos directory structure
# Uses ~/repos/github.com/{owner}/ to determine which gh account to use

function gh() {
    local gh_user=""
    local account_map="$HOME/.config/gh/account-map"

    # Extract owner from ~/repos/github.com/{owner}/...
    if [[ "$PWD" =~ "$HOME/repos/github.com/([^/]+)" ]]; then
        local owner="${match[1]}"

        # Look up gh username from account-map
        if [[ -f "$account_map" ]]; then
            gh_user=$(command awk -v owner="$owner" '$1 == owner { print $2 }' "$account_map")
        fi

        # If no mapping found, use owner name directly
        : ${gh_user:=$owner}
    fi

    if [[ -n "$gh_user" ]]; then
        local token
        token=$(command gh auth token --user "$gh_user" 2>/dev/null)
        if [[ -n "$token" ]]; then
            GH_TOKEN="$token" command gh "$@"
            return
        fi
    fi

    command gh "$@"
}
