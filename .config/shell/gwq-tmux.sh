# gwq-tmux.sh - gwq + fzf + tmux integration

# Interactive-only: ZLE widget + keybinding
if [[ -o interactive ]]; then
    function gwq-tmux-widget() {
        zle -I
        local gwq_basedir=$(gwq config get worktree.basedir | /usr/bin/sed "s|^~|$HOME|")

        local worktree_relative=$(
            exec < /dev/tty
            gwq list -g --json 2>/dev/null | \
                jq -r '.[] | .path' | \
                /usr/bin/sed "s|^$gwq_basedir/||" | \
                fzf --prompt="Worktree > " \
                    --preview="git -C '$gwq_basedir'/{} log --oneline -10 --color=always" \
                    --preview-window=right:60%
        )

        if [[ -n "$worktree_relative" ]]; then
            local worktree="${gwq_basedir}/${worktree_relative}"
            local session_name=$(gwq-session-name "$worktree")
            BUFFER="gwq-tmux-exec '$session_name' '$worktree'"
            zle accept-line
        fi
        zle reset-prompt
    }
    zle -N gwq-tmux-widget
    bindkey '^W' gwq-tmux-widget
fi

function gwq-tmux-exec() {
    local session_name="$1"
    local worktree="$2"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$worktree"
    fi

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    elif [[ -t 0 ]]; then
        tmux attach-session -t "$session_name"
    else
        echo "Session '$session_name' created. Run: tmux attach -t '$session_name'"
    fi
}

# Generate session name from gwq worktree path (remove owner + branch prefix)
function gwq-session-name() {
    local dir_name=$(basename "$1")
    if [[ "$dir_name" == *@* ]]; then
        local repo_part="${dir_name%%@*}"
        local branch_part="${dir_name#*@}"
        branch_part="${branch_part#feature-}"
        branch_part="${branch_part#fix-}"
        branch_part="${branch_part#bugfix-}"
        branch_part="${branch_part#hotfix-}"
        echo "${repo_part}-${branch_part}" | tr './' '--'
    else
        echo "$dir_name" | tr './@' '---'
    fi
}

function gwq-cd-or-switch() {
    local wt_path="$1"
    if [[ -n "$TMUX" ]]; then
        local session_name=$(gwq-session-name "$wt_path")
        gwq-tmux-exec "$session_name" "$wt_path"
    else
        cd "$wt_path"
    fi
}

function gwq-tmux() {
    local gwq_basedir=$(gwq config get worktree.basedir | /usr/bin/sed "s|^~|$HOME|")
    local worktree_relative=$(
        gwq list -g --json 2>/dev/null | \
            jq -r '.[] | .path' | \
            /usr/bin/sed "s|^$gwq_basedir/||" | \
            fzf --prompt="Worktree > " \
                --preview="git -C '$gwq_basedir'/{} log --oneline -10 --color=always" \
                --preview-window=right:50%
    )

    [[ -z "$worktree_relative" ]] && return

    local worktree="${gwq_basedir}/${worktree_relative}"
    local session_name=$(gwq-session-name "$worktree")
    gwq-tmux-exec "$session_name" "$worktree"
}

# tmux session switcher (fzf + preview)
function tmux-session-fzf() {
    local session=$(tmux list-sessions -F '#{session_name}' | \
        fzf --prompt="Session > " \
            --preview="tmux list-windows -t {} -F '  #{window_index}: #{window_name} [#{pane_current_command}] #{?window_active,(active),}'" \
            --preview-window=right:50%)

    [[ -z "$session" ]] && return

    tmux switch-client -t "$session"
}
