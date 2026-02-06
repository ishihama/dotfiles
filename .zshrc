export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# カスタム補完ディレクトリ (oh-my-zshのcompinit前に設定)
fpath=(~/.zsh/completions $fpath)

# oh-my-zsh
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="lukerandall"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# aliases
alias vi=nvim
alias vim=nvim
alias cat='bat --paging=never'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias lt='eza --tree --icons'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias du='dust'
alias df='duf'
alias sed='sd'
alias top='btop'
alias http='xh'

# Editor (Claude Code の Ctrl+G などで使用)
export EDITOR=nvim
export VISUAL=nvim

# less
export LESSCHARSET=utf-8

# ls color
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'

# 補完候補もカラー
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Golang
export PATH="$HOME/go/bin:$PATH"

# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# mise (asdf alternative)
eval "$(mise activate zsh)"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export ANDROID_AVD_HOME="$HOME/.android/avd"
export PATH="${ANDROID_SDK_ROOT}/tools:$PATH"
export PATH="${ANDROID_SDK_ROOT}/platform-tools:$PATH"


# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# direnv
eval "$(direnv hook zsh)"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# atuin (shell history)
eval "$(atuin init zsh)"

# starship prompt
eval "$(starship init zsh)"

# lazygit alias
alias lg='lazygit'

# fzf history search
function select-history() {
    BUFFER=$(\history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
    CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

# ghq + fzf + tmux: リポジトリ選択してtmuxセッションを開く (プレビュー付き)
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

# gwq + fzf + tmux: worktree選択してtmuxセッションを開く
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
        local dir_name=$(basename "$worktree")
        local parent_name=$(basename "$(dirname "$worktree")")
        local session_name=$(echo "${parent_name}-${dir_name}" | tr './@' '---')
        BUFFER="gwq-tmux-exec '$session_name' '$worktree'"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N gwq-tmux-widget
bindkey '^W' gwq-tmux-widget

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
    # ディレクトリ名から owner/repo@branch または owner/repo 形式を取得
    local dir_name=$(basename "$worktree")
    local parent_name=$(basename "$(dirname "$worktree")")
    local session_name=$(echo "${parent_name}-${dir_name}" | tr './@' '---')
    gwq-tmux-exec "$session_name" "$worktree"
}

# gwq wrapper: add -i でorigin/プレフィックスを自動除去 + add後に自動cd
function gwq() {
    if [[ "$1" == "add" && "$2" == "-i" ]]; then
        # カスタム interactive モード
        local branch=$(git branch -a --sort=-committerdate 2>/dev/null | \
            command sed 's/^[* ]*//' | \
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
        # 作成したworktreeに移動
        local wt_path=$(command gwq get "$target_branch" 2>/dev/null)
        [[ -n "$wt_path" ]] && cd "$wt_path"
    elif [[ "$1" == "add" ]]; then
        command gwq "$@" || return
        # 引数からブランチ名を推定してworktreeパスを取得
        local -a args=("$@")
        local target_branch=""
        for ((i=1; i<${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "-b" && $((i+1)) -lt ${#args[@]} ]]; then
                target_branch="${args[$((i+1))]}"
                break
            fi
        done
        [[ -z "$target_branch" ]] && target_branch="${args[-1]}"
        local wt_path=$(command gwq get "$target_branch" 2>/dev/null)
        [[ -n "$wt_path" ]] && cd "$wt_path"
    else
        command gwq "$@"
    fi
}

# git branch切り替え (fzf + preview)
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

# ファイル検索してnvimで開く (fd + fzf)
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

# プロセスkill (procs + fzf)
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

# memo: シンプルなメモ管理 (~/memos/)
MEMO_DIR=~/memos

function memo() {
    mkdir -p "$MEMO_DIR"

    if [[ -n "$1" ]]; then
        nvim "$MEMO_DIR/$1.md"
    else
        local selected=$(
            { echo "[+ 新規作成]"; fd -e md . "$MEMO_DIR" 2>/dev/null | xargs -I{} basename {} .md; } | \
            fzf --prompt="Memo > " \
                --preview='[[ {} == "[+ 新規作成]" ]] && echo "新しいメモを作成" || bat --color=always --style=plain '"$MEMO_DIR"'/{}.md 2>/dev/null' \
                --preview-window=right:60%
        )

        [[ -z "$selected" ]] && return

        if [[ "$selected" == "[+ 新規作成]" ]]; then
            echo -n "ファイル名 (拡張子不要): "
            read filename
            [[ -z "$filename" ]] && return
            nvim "$MEMO_DIR/$filename.md"
        else
            nvim "$MEMO_DIR/$selected.md"
        fi
    fi
}

function memo-search() {
    mkdir -p "$MEMO_DIR"

    local match=$(
        rg --color=always --line-number --no-heading . "$MEMO_DIR" 2>/dev/null | \
        fzf --ansi --prompt="Search > " \
            --preview='bat --color=always --highlight-line={2} {1}' \
            --preview-window='+{2}-10' \
            --delimiter=':'
    )

    if [[ -n "$match" ]]; then
        local file=$(echo "$match" | cut -d':' -f1)
        local line=$(echo "$match" | cut -d':' -f2)
        nvim "+$line" "$file"
    fi
}

# Load shell modules
[[ -f ~/.config/shell/cheat.sh ]] && source ~/.config/shell/cheat.sh

# OS Type
if [ "$(uname)" = 'Darwin' ]; then
    #mac
    source ${HOME}/.zshrc.osx
elif [ "$(uname)" = 'Linux' ]; then
    #linux
    source ${HOME}/.zshrc.linux
else
    echo "Unknown OS Type....."
fi

autoload -U +X bashcompinit && bashcompinit

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# SDKMAN (via Homebrew)
# findエイリアスを一時解除 (SDKMAN init scriptがfind -typeを使うため)
unalias find 2>/dev/null
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
alias find='fd'  # 復元

# 補完ファイル生成 (初回 or 更新時に実行)
function setup-completions() {
    local comp_dir=~/.zsh/completions
    mkdir -p "$comp_dir"

    echo "Generating completions..."

    # GitHub CLI
    command -v gh &>/dev/null && gh completion -s zsh > "$comp_dir/_gh"

    # mise
    command -v mise &>/dev/null && mise completion zsh > "$comp_dir/_mise"

    # Docker
    command -v docker &>/dev/null && docker completion zsh > "$comp_dir/_docker"

    # Rustup & Cargo
    command -v rustup &>/dev/null && rustup completions zsh > "$comp_dir/_rustup"
    command -v rustup &>/dev/null && rustup completions zsh cargo > "$comp_dir/_cargo"

    # pnpm
    command -v pnpm &>/dev/null && pnpm completion zsh > "$comp_dir/_pnpm"

    # kubectl
    command -v kubectl &>/dev/null && kubectl completion zsh > "$comp_dir/_kubectl"

    # helm
    command -v helm &>/dev/null && helm completion zsh > "$comp_dir/_helm"

    # lazygit
    # lazygitは補完なし

    # fzf
    [[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && cp /opt/homebrew/opt/fzf/shell/completion.zsh "$comp_dir/_fzf"

    echo "Done! Restart shell or run: source ~/.zshrc"
}

# 補完ディレクトリがなければ初回セットアップを促す
[[ ! -d ~/.zsh/completions ]] && echo "Run 'setup-completions' to enable CLI completions"

# ローカル設定 (APIキーなど、gitignore対象)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Pokemon (ターミナル起動時にランダム表示)
if command -v pokemon-go-colorscripts &> /dev/null; then
    pokemon-go-colorscripts -r -s
fi
