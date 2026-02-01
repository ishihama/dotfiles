export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

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

# gwq wrapper: add -i でorigin/プレフィックスを自動除去
function gwq() {
    if [[ "$1" == "add" && "$2" == "-i" ]]; then
        # カスタム interactive モード
        local branch=$(git branch -a --sort=-committerdate 2>/dev/null | \
            command sed 's/^[* ]*//' | \
            command sed 's/remotes\///' | \
            fzf --prompt="Branch > " \
                --preview='git log --oneline --graph -10 {}')

        [[ -z "$branch" ]] && return

        if [[ "$branch" == origin/* ]]; then
            local local_branch="${branch#origin/}"
            command gwq add -b "$local_branch" "$branch"
        else
            command gwq add "$branch"
        fi
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

# チートシート: キーバインド・エイリアス一覧 (fzf検索)
function cheat() {
    local selected=$(cat <<'EOF' | fzf --prompt="Cheatsheet > " --header="Enter: コマンドラインに貼付 | Ctrl+/: toggle preview" --preview='echo {}' --preview-window=hidden
[tmux] Ctrl+T           prefix
[tmux] prefix h/j/k/l   pane移動 (vim風)
[tmux] prefix H/J/K/L   paneリサイズ
[tmux] prefix |         縦分割
[tmux] prefix -         横分割
[tmux] prefix g         ghq-tmux popup
[tmux] prefix w         gwq-tmux popup
[tmux] prefix c         新規window
[tmux] prefix n/p       次/前のwindow
[tmux] prefix 1-9       window切替
[tmux] prefix d         detach
[tmux] prefix [         コピーモード (vi)
[tmux] prefix x         pane閉じる
[shell] Ctrl+G          ghq-tmux (リポジトリ選択)
[shell] Ctrl+W          gwq-tmux (worktree選択)
[shell] Ctrl+R          履歴検索 (atuin/fzf)
[shell] Ctrl+B          git branch切り替え
[shell] Ctrl+F          ファイル検索→nvim
[shell] Ctrl+K          プロセスkill
[ghostty] Cmd+T         tmux prefix (Ctrl+T)
[ghostty] Cmd+N         新規window (tmux)
[ghostty] Cmd+W         pane閉じる (tmux)
[ghostty] Cmd+1-9       window切替 (tmux)
[ghostty] Cmd+H/J/K/L   pane移動 (tmux)
[ghostty] Cmd+\         縦分割 (tmux)
[ghostty] Cmd+-         横分割 (tmux)
[nvim] Space            Leader
[nvim] Space+e          ファイルツリー toggle
[nvim] Space+ff         ファイル検索
[nvim] Space+fg         grep検索
[nvim] Space+fb         バッファ一覧
[nvim] gd               定義へジャンプ
[nvim] gr               参照一覧
[nvim] K                ホバー情報
[nvim] Space+ca         コードアクション
[nvim] Space+rn         リネーム
[nvim] gcc              行コメント toggle
[nvim] Tab              次のウィンドウ
[nvim] Shift+Tab        前のウィンドウ
[alias] cat             bat --paging=never
[alias] ls              eza --icons
[alias] ll              eza -la --icons --git
[alias] la              eza -a --icons
[alias] lt              eza --tree --icons
[alias] grep            rg (ripgrep)
[alias] find            fd
[alias] ps              procs
[alias] du              dust
[alias] df              duf
[alias] sed             sd
[alias] top             btop
[alias] http            xh
[alias] vi/vim          nvim
[alias] lg              lazygit
[ghq] ghq get <repo>              clone (github.com/user/repo or user/repo)
[ghq] ghq get -p <repo>           clone with SSH
[ghq] ghq list                    一覧表示
[ghq] ghq list -p                 フルパスで一覧
[ghq] ghq root                    ルートディレクトリ表示
[ghq] ghq create <repo>           新規リポジトリ作成
[gwq] gwq add <branch>            既存branchからworktree作成
[gwq] gwq add -b <branch>         新規branch + worktree作成
[gwq] gwq add -i                  fzfでbranch選択して作成
[gwq] gwq add -s <branch>         作成後そのディレクトリに留まる
[gwq] gwq list                    現在リポジトリのworktree一覧
[gwq] gwq list -g                 全worktree一覧
[gwq] gwq list -v                 詳細表示
[gwq] gwq remove <path>           worktree削除
[gwq] gwq status                  全worktreeの状態表示
[git] git switch -c <branch>      新規branch作成+切替
[git] git switch <branch>         branch切替
[git] git restore <file>          変更を破棄
[git] git restore --staged <file> ステージング解除
[git] git stash -u                untracked含めてstash
[git] git stash pop               stash適用+削除
[git] git log --oneline -n 10     簡潔なログ表示
[git] git diff --cached           ステージング済みの差分
[git] git rebase -i HEAD~3        直近3コミットを編集
[bat] bat <file>                  シンタックスハイライト表示
[bat] bat -l <lang> <file>        言語指定
[bat] bat -p <file>               装飾なし (plain)
[bat] bat -A <file>               非表示文字も表示
[eza] eza -l                      詳細表示
[eza] eza -la                     隠しファイル含む詳細
[eza] eza --tree -L 2             ツリー表示 (深さ2)
[eza] eza --git                   git status表示
[eza] eza -s modified             更新日時順
[fd] fd <pattern>                 ファイル名検索
[fd] fd -e <ext>                  拡張子で絞込 (-e ts)
[fd] fd -t f                      ファイルのみ
[fd] fd -t d                      ディレクトリのみ
[fd] fd -H                        隠しファイル含む
[fd] fd -x <cmd> {}               見つけたファイルにコマンド実行
[rg] rg <pattern>                 ファイル内容検索
[rg] rg -i <pattern>              大文字小文字無視
[rg] rg -t <type> <pattern>       ファイルタイプ指定 (-t py)
[rg] rg -g '*.ts' <pattern>       glob指定
[rg] rg -C 3 <pattern>            前後3行表示
[rg] rg -l <pattern>              マッチしたファイル名のみ
[fzf] fzf --preview 'bat {}'      プレビュー付き
[fzf] fzf -m                      複数選択可
[fzf] fzf -q <query>              初期クエリ指定
[fzf] cmd | fzf                   パイプで入力
[zoxide] z <dir>                  スマートcd
[zoxide] zi                       fzfで選択
[zoxide] zoxide query <dir>       パス検索
[memo] memo                       メモ一覧 (fzf選択/新規作成)
[memo] memo <name>                指定メモを直接開く
[memo] memo-search                全文検索→該当行へジャンプ
[claude] claude                   対話モード (履歴保持)
[claude] claude --no-resume       一時的な対話 (履歴なし)
[claude] claude -c                前回の会話を継続
[claude] claude -r                過去の会話をfzf選択して再開
[claude] claude -p "prompt"       単発クエリ (非対話)
[claude] claude -p "prompt" --add-file <file>   ファイル含めて質問
[jq] jq '.'                       JSON整形
[jq] jq '.key'                    キー抽出
[jq] jq '.[] | .name'             配列から特定キー抽出
[jq] jq -r '.key'                 raw出力 (引用符なし)
[yq] yq '.'                       YAML整形
[yq] yq '.key'                    キー抽出
[yq] yq -o json                   YAML→JSON変換
[gh] gh pr create                 PR作成
[gh] gh pr view                   PR表示
[gh] gh pr checkout <number>      PRをcheckout
[gh] gh issue list                issue一覧
[gh] gh repo clone <repo>         リポジトリclone
[gh] gh browse                    ブラウザでリポジトリ開く
[glow] glow <file.md>             Markdownプレビュー
[glow] glow -p <file.md>          ページャー付きプレビュー
[tldr] tldr <command>             コマンドの簡易説明
[hyperfine] hyperfine '<cmd>'     コマンドのベンチマーク
[hyperfine] hyperfine '<cmd1>' '<cmd2>'   比較ベンチマーク
[tokei] tokei                     コード行数統計
[tokei] tokei -e node_modules     除外指定
[gibo] gibo dump Node             gitignoreテンプレート出力
[gibo] gibo list                  テンプレート一覧
[direnv] direnv allow             .envrc有効化
[direnv] direnv deny              .envrc無効化
[yazi] yazi                       ファイルマネージャ起動
[yazi] y                          yazi + cd連携 (終了時にcd)
EOF
)
    if [[ -n "$selected" ]]; then
        local key=$(echo "$selected" | /usr/bin/sed 's/^\[[^]]*\] *\([^ ]*\).*/\1/')
        print -z "$key "
    fi
}

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

# ローカル設定 (APIキーなど、gitignore対象)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Pokemon (ターミナル起動時にランダム表示)
if command -v pokemon-go-colorscripts &> /dev/null; then
    pokemon-go-colorscripts -r -s
fi
