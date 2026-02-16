#!/bin/zsh
# cheat.sh - Cheatsheet function for displaying keybindings and aliases
# Extracted from .zshrc for better organization

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
[lazygit] V (大文字)       PR: 一覧表示 (global)
[lazygit] v               PR: ブラウザで表示
[lazygit] C (大文字)       PR: checkout
[lazygit] P (大文字)       PR: 作成 (Web)
[lazygit] D (大文字)       PR: diff表示
[ghq] ghq get <repo>              clone (github.com/user/repo or user/repo)
[ghq] ghq get -p <repo>           clone with SSH
[ghq] ghq list                    一覧表示
[ghq] ghq list -p                 フルパスで一覧
[ghq] ghq root                    ルートディレクトリ表示
[ghq] ghq create <repo>           新規リポジトリ作成
[gwq] gwq add <branch>            既存branchからworktree作成 (自動cd)
[gwq] gwq add -b <branch>         新規branch + worktree作成 (自動cd)
[gwq] gwq add -i                  fzfでbranch選択して作成 (自動cd)
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
