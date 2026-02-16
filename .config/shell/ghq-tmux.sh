# ghq-tmux.sh - ghq + fzf + tmux integration

# Interactive-only: ZLE widget + keybinding
if [[ -o interactive ]]; then
    function ghq-tmux-widget() {
        zle -I
        local ghq_root=$(ghq root)

        local repo=$(
            exec < /dev/tty
            ghq list | grep -v '@' | fzf \
                --prompt="Repository > " \
                --preview="bat --color=always --style=plain '$ghq_root'/{}/README.md 2>/dev/null || git -C '$ghq_root'/{} log --oneline -10 --color=always" \
                --preview-window=right:50% \
                --bind='ctrl-/:toggle-preview'
        )

        if [[ -n "$repo" ]]; then
            local repo_path="${ghq_root}/${repo}"
            local session_name
            session_name=$(echo "$repo" | awk -F'/' '{print $(NF-1)"-"$NF}' | tr '.' '-')
            BUFFER="ghq-tmux-exec '$session_name' '$repo_path'"
            zle accept-line
        fi
        zle reset-prompt
    }
    zle -N ghq-tmux-widget
    bindkey '^G' ghq-tmux-widget
fi

function ghq-tmux-exec() {
    local session_name="$1"
    local repo_path="$2"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$repo_path"
    fi

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    elif [[ -t 0 ]]; then
        tmux attach-session -t "$session_name"
    else
        echo "Session '$session_name' created. Run: tmux attach -t '$session_name'"
    fi
}

function ghq-tmux() {
    local ghq_root=$(ghq root)
    local repo=$(ghq list | grep -v '@' | fzf \
        --prompt="Repository > " \
        --preview="bat --color=always --style=plain '$ghq_root'/{}/README.md 2>/dev/null || git -C '$ghq_root'/{} log --oneline -10 --color=always" \
        --preview-window=right:50%)

    [[ -z "$repo" ]] && return

    local repo_path="${ghq_root}/${repo}"
    local session_name=$(echo "$repo" | awk -F'/' '{print $(NF-1)"-"$NF}' | tr '.' '-')
    ghq-tmux-exec "$session_name" "$repo_path"
}
