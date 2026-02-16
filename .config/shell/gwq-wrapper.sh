# gwq-wrapper.sh - gwq wrapper: add -i for interactive branch selection + auto cd after add

function gwq() {
    if [[ "$1" == "add" && "$2" == "-i" ]]; then
        # Custom interactive mode
        local branch=$(git branch -a --sort=-committerdate 2>/dev/null | \
            command sed 's/^[*+ ]*//' | \
            command sed 's/remotes\///' | \
            fzf --prompt="Branch > " \
                --preview='git log --oneline --graph -10 {}')

        [[ -z "$branch" ]] && return

        local target_branch="$branch"
        if [[ "$branch" == origin/* ]]; then
            target_branch="${branch#origin/}"
            command gwq add -b "$target_branch" "$branch" || return
        else
            command gwq add "$branch" || return
        fi
        # Move to created worktree (switch to new session if inside tmux)
        local wt_path=$(command gwq get "$target_branch" 2>/dev/null)
        [[ -n "$wt_path" ]] && gwq-cd-or-switch "$wt_path"
    elif [[ "$1" == "add" ]]; then
        # Remove -s/--stay (wrapper handles cd/session-switch itself)
        local -a filtered_args=()
        local target_branch=""
        local i=1
        while [[ $i -le $# ]]; do
            local arg="${@[$i]}"
            if [[ "$arg" == "-s" || "$arg" == "--stay" ]]; then
                ((i++))
                continue
            fi
            if [[ "$arg" == "-b" ]]; then
                filtered_args+=("$arg")
                ((i++))
                [[ $i -le $# ]] && { target_branch="${@[$i]}"; filtered_args+=("$target_branch"); }
                ((i++))
                continue
            fi
            filtered_args+=("$arg")
            ((i++))
        done
        command gwq "${filtered_args[@]}" || return
        [[ -z "$target_branch" ]] && target_branch="${filtered_args[-1]}"
        local wt_path=$(command gwq get "$target_branch" 2>/dev/null)
        [[ -n "$wt_path" ]] && gwq-cd-or-switch "$wt_path"
    else
        command gwq "$@"
    fi
}
