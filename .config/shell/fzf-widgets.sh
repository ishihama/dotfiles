# fzf-widgets.sh - fzf-based zle widgets (history, branch, file, process)

# fzf history search
function select-history() {
    BUFFER=$(\history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
    CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

# git branch switcher (fzf + preview)
function git-branch-fzf-widget() {
    zle -I

    local branch=$(
        exec < /dev/tty
        git branch --sort=-committerdate | \
            /usr/bin/sed 's/^[* ]*//' | \
            fzf --prompt="Branch > " \
                --preview='git log --oneline --graph -20 --color=always {}' \
                --preview-window=right:50%
    )

    if [[ -n "$branch" ]]; then
        BUFFER="git checkout '$branch'"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N git-branch-fzf-widget
bindkey '^B' git-branch-fzf-widget

# File search and open in nvim (fd + fzf)
function find-file-nvim-widget() {
    zle -I

    local file=$(
        exec < /dev/tty
        fd --type f --hidden --exclude .git | \
            fzf --prompt="File > " \
                --preview='bat --color=always --style=numbers --line-range=:100 {}' \
                --preview-window=right:60%
    )

    if [[ -n "$file" ]]; then
        BUFFER="nvim '$file'"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N find-file-nvim-widget
bindkey '^F' find-file-nvim-widget

# Process kill (procs + fzf)
function kill-process-fzf-widget() {
    zle -I

    local selected=$(
        exec < /dev/tty
        procs --no-header | \
            fzf --prompt="Kill > " \
                --header="Select process to kill" \
                --preview='procs --tree {1}' \
                --preview-window=right:40%
    )

    if [[ -n "$selected" ]]; then
        local pid=$(echo "$selected" | awk '{print $1}')
        BUFFER="kill -9 $pid"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N kill-process-fzf-widget
bindkey '^K' kill-process-fzf-widget
