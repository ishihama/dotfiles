# fzf-widgets.sh - fzf-based zle widgets (branch, file, process)
#
# History search (Ctrl+R) is intentionally NOT defined here: env.sh runs
# `atuin init zsh`, and binding ^R here would silently override it.
#
# These widgets live under the ^X prefix so that the standard zsh emacs
# keymap keeps ^W (backward-kill-word), ^B/^F (char motion) and ^K (kill-line).

# ZLE widgets and keybindings only make sense in an interactive shell
[[ -o interactive ]] || return 0

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
        # ${(q)} quoting: git refnames may contain quotes and $(...), and a
        # fetched remote branch is attacker-controlled input.
        BUFFER="git checkout ${(q)branch}"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N git-branch-fzf-widget
bindkey '^Xb' git-branch-fzf-widget

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
        # Filenames routinely contain quotes (don't-delete.md)
        BUFFER="nvim ${(q)file}"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N find-file-nvim-widget
bindkey '^Xf' find-file-nvim-widget

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
        local pid=$(printf '%s' "$selected" | awk '{print $1}')
        # Refuse anything that is not a bare PID rather than handing a stray
        # word (or several) to kill -9
        if [[ "$pid" == <-> ]]; then
            BUFFER="kill -9 $pid"
            zle accept-line
        else
            zle -M "Could not parse a PID from: $selected"
        fi
    fi
    zle reset-prompt
}
zle -N kill-process-fzf-widget
bindkey '^Xk' kill-process-fzf-widget
