# gwq-tmux.sh - gwq + fzf + tmux integration

# Resolve gwq's worktree basedir, expanding a leading ~.
# Echoes nothing and returns non-zero when gwq is unavailable or unconfigured,
# so callers can report that instead of silently searching an empty path.
function gwq-basedir() {
    local raw
    raw=$(command gwq config get worktree.basedir 2>/dev/null) || return 1
    [[ -z "$raw" ]] && return 1
    # Plain parameter expansion - avoids feeding $HOME into a sed regex
    printf '%s\n' "${raw/#\~/$HOME}"
}

# List worktrees relative to the basedir
function gwq-list-relative() {
    local basedir="$1"
    local path
    /usr/bin/find "$basedir" -maxdepth 4 -type d -name '*@*' 2>/dev/null | \
        while IFS= read -r path; do
            printf '%s\n' "${path#"$basedir"/}"
        done | sort
}

# Interactive-only: ZLE widget + keybinding
if [[ -o interactive ]]; then
    function gwq-tmux-widget() {
        zle -I

        local gwq_basedir
        if ! gwq_basedir=$(gwq-basedir); then
            zle -M "gwq: worktree.basedir is not configured"
            zle reset-prompt
            return 1
        fi

        local worktree_relative=$(
            exec < /dev/tty
            gwq-list-relative "$gwq_basedir" | \
                fzf --prompt="Worktree > " \
                    --preview="git -C ${(q)gwq_basedir}/{} log --oneline -10 --color=always" \
                    --preview-window=right:60%
        )

        if [[ -n "$worktree_relative" ]]; then
            local worktree="${gwq_basedir}/${worktree_relative}"
            local session_name=$(gwq-session-name "$worktree")
            # ${(q)} quoting: worktree dir names embed branch names, and git
            # refnames may contain quotes or $(...) which accept-line would run.
            BUFFER="gwq-tmux-exec ${(q)session_name} ${(q)worktree}"
            zle accept-line
        fi
        zle reset-prompt
    }
    zle -N gwq-tmux-widget
    bindkey '^Xw' gwq-tmux-widget
fi

function gwq-tmux-exec() {
    local session_name="$1"
    local worktree="$2"

    # "=" forces an exact match; tmux otherwise resolves -t by prefix/fnmatch
    # and would attach to a different worktree whose name shares a prefix.
    if ! tmux has-session -t "=$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$worktree" || return 1
    fi

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "=$session_name"
    elif [[ -t 0 ]]; then
        tmux attach-session -t "=$session_name"
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
    local gwq_basedir
    if ! gwq_basedir=$(gwq-basedir); then
        echo "gwq: worktree.basedir is not configured" >&2
        return 1
    fi

    local worktree_relative=$(
        gwq-list-relative "$gwq_basedir" | \
            fzf --prompt="Worktree > " \
                --preview="git -C ${(q)gwq_basedir}/{} log --oneline -10 --color=always" \
                --preview-window=right:50%
    )

    [[ -z "$worktree_relative" ]] && return

    local worktree="${gwq_basedir}/${worktree_relative}"
    local session_name=$(gwq-session-name "$worktree")
    gwq-tmux-exec "$session_name" "$worktree"
}

# tmux session switcher (fzf + preview)
function tmux-session-fzf() {
    # Claude Code状態グリフ (⚙作業中 / 🔔入力待ち / ✓待機) を先頭列に付与
    local states="$("$HOME/.config/claude/bin/claude-status" sessions 2>/dev/null)"
    # awk -v performs backslash escape processing on the assigned value, which
    # would mangle session names containing "\". Pass the map on stdin instead.
    local session=$(
        {
            printf '%s\n' "$states"
            printf '\034\n'
            tmux list-sessions -F '#{session_name}'
        } | awk -F'\t' '
            /^\034$/ { in_sessions = 1; next }
            !in_sessions { if ($1 != "") glyph[$1] = $2; next }
            { printf "%s\t%s\n", ($0 in glyph ? glyph[$0] : " "), $0 }' | \
        fzf --prompt="Session > " \
            --delimiter='\t' \
            --preview="tmux list-windows -t '={2}' -F '  #{window_index}: #{window_name} [#{pane_current_command}] #{?window_active,(active),}'" \
            --preview-window=right:50% | cut -f2-
    )

    [[ -z "$session" ]] && return

    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "=$session"
    else
        tmux switch-client -t "=$session"
    fi
}
