# dotfiles

macOS、Linux、WSL用の個人dotfiles。

## セットアップ

```bash
# 1. リポジトリをクローン
ghq get https://github.com/YOUR_USERNAME/dotfiles
cd ~/repos/github.com/personal/dotfiles

# 2. init.shを実行 (シンボリックリンク、oh-my-zsh、Homebrew、パッケージ、gh拡張をインストール)
./init.sh

# 3. Git設定（複数GitHubアカウント対応）
# 3-1. .gitconfig.localを作成
cat > ~/.gitconfig.local << 'EOF'
# Directory-specific configurations
[includeIf "gitdir:/Users/YOUR_USERNAME/repos/github.com/personal/**"]
	path = ~/.gitconfig.personal
[includeIf "gitdir:/Users/YOUR_USERNAME/repos/github.com/work/**"]
	path = ~/.gitconfig.work
EOF

# 3-2. 個人用Git設定をテンプレートからコピー
cp .gitconfig.personal.example ~/.gitconfig.personal

# 3-3. ~/.gitconfig.personalを編集（名前・メール・SSH鍵を設定）
nvim ~/.gitconfig.personal
# [user]
#   name = Your Name
#   email = your.email@example.com
# [core]
#   sshCommand = ssh -i ~/.ssh/id_ed25519_personal

# 3-4. 仕事用も同様に設定（必要な場合）
cp .gitconfig.work.example ~/.gitconfig.work
nvim ~/.gitconfig.work

# 4. シェルを再読み込み
source ~/.zshrc

# 5. Neovimを起動（初回はプラグイン自動インストール）
nvim
```

### Git設定の詳細

このdotfilesは複数GitHubアカウントに対応しています。ディレクトリパスに応じて自動的にユーザー情報とSSH鍵を切り替えます。

**ファイル構成:**
- `.gitconfig` - 共通設定（git管理対象）
- `.gitconfig.local` - `includeIf`設定（git管理**外**、環境ごとに作成）
- `.gitconfig.personal` / `.gitconfig.work` - 個人情報（git管理**外**）
- `.gitconfig.personal.example` / `.gitconfig.work.example` - テンプレート（git管理対象）

**ディレクトリ構造の推奨:**
```
~/repos/github.com/
  ├── personal/     # 個人用リポジトリ（.gitconfig.personalが適用される）
  │   └── dotfiles/
  └── work/         # 仕事用リポジトリ（.gitconfig.workが適用される）
      └── project/
```

**動作確認:**
```bash
# personalディレクトリで
cd ~/repos/github.com/personal/dotfiles
git config user.email  # → 個人用メールアドレスが表示される

# workディレクトリで
cd ~/repos/github.com/work/project
git config user.email  # → 仕事用メールアドレスが表示される
```

## キーバインド

### シェル

| キー | 説明 |
|------|------|
| `Ctrl+R` | fzf履歴検索 |
| `Ctrl+G` | ghq + fzf + tmux (リポジトリ選択) |
| `Ctrl+W` | gwq + fzf + tmux (worktree選択) |
| `Ctrl+B` | git branch切り替え (fzf + preview) |
| `Ctrl+F` | ファイル検索→nvimで開く (fd + fzf) |
| `Ctrl+K` | プロセスkill (procs + fzf) |
| `lg` | lazygit起動 |
| `cheat` | チートシート表示 (コマンドラインに貼付) |

### Neovim

| キー | 説明 |
|------|------|
| `Space` | Leader キー |
| `Space+e` | ファイルツリー toggle |
| `Space+ff` | ファイル検索 (telescope) |
| `Space+fg` | grep検索 (telescope) |
| `Space+fb` | バッファ一覧 |
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバー情報 |
| `Space+ca` | コードアクション |
| `Space+rn` | リネーム |
| `gcc` | 行コメント toggle |
| `Tab` | 次のウィンドウ |
| `Shift+Tab` | 前のウィンドウ |

## ghq + fzf + tmux ワークフロー

`Ctrl+G`でリポジトリ選択してtmuxセッションを作成/アタッチ。

### 初回セットアップ

```bash
# ghqでリポジトリを取得（例: Anthropicのclaude-codeリポジトリ）
ghq get https://github.com/anthropics/claude-code

# Ctrl+Gを押して、リポジトリを選択 → tmuxセッションに入る！
```

### 日常の使い方

1. `Ctrl+G`を押す
2. fzfでリポジトリを選択
3. リポジトリ名のtmuxセッションが自動作成される（既存なら切り替え）

### 動作

| 状況 | 動作 |
|------|------|
| tmux外 | 新規セッション作成 or 既存にアタッチ |
| tmux内 | 新規セッション作成 or 既存に切り替え |
| fzfキャンセル | 何もしない |

セッション名はリポジトリのbasename（`.`は`-`に置換）。

## gwq + fzf + tmux ワークフロー

`Ctrl+W`でworktree選択して並行開発用のtmuxセッションを作成/切り替え。

gwqは`./init.sh`実行時に`brew bundle`でインストールされる。

### 使い方

1. `Ctrl+W`を押す
2. fzfでworktreeを選択（プレビューで最近のコミット表示）
3. `{リポジトリ}-{ブランチ}`名のtmuxセッションが自動作成される（既存なら切り替え）

### なぜWorktree？

- **並行開発**: stashなしで複数ブランチを同時に作業
- **複数Claude Code**: 異なるブランチで同時にClaude Codeを実行
- **素早いコンテキスト切り替え**: 各worktreeは完全な作業コピー

### 典型的なワークフロー

```bash
# 新機能を開始
gwq add -b feature/login

# 別の機能も並行して開始
gwq add -b feature/signup

# Ctrl+Wで切り替え
# それぞれ独自のtmuxセッションでフルコンテキスト維持

# 完了したらクリーンアップ
gwq remove feature/login
```

### 動作

| 状況 | 動作 |
|------|------|
| tmux外 | 新規セッション作成 or 既存にアタッチ |
| tmux内 | 新規セッション作成 or 既存に切り替え |
| fzfキャンセル | 何もしない |

セッション名は`{リポジトリ}-{ブランチ}`（`.`と`/`は`-`に置換）。

## 便利キーバインド

日常の開発を効率化するfzf連携キーバインド。

### Ctrl+B: git branch切り替え

ローカルブランチをfzfで選択してcheckout。プレビューでコミット履歴を確認できる。

```bash
# Ctrl+Bを押す → ブランチ一覧が表示
# 選択するとそのブランチにcheckout
# プレビューで各ブランチの最新コミットを確認
```

### Ctrl+F: ファイル検索→nvimで開く

fd + fzf + batでファイルを検索。プレビューでシンタックスハイライト付きの内容を確認してnvimで開く。

```bash
# Ctrl+Fを押す → ファイル一覧が表示
# 選択するとnvimで開く
# プレビューでファイル内容を確認（bat使用）
```

### Ctrl+K: プロセスkill

procsでプロセス一覧を表示、fzfで選択してkill。

```bash
# Ctrl+Kを押す → プロセス一覧が表示
# 選択するとkill -9で終了
# プレビューでプロセスツリーを確認
```

### lg: lazygit

lazygitをすぐ起動できるエイリアス。

```bash
lg    # lazygit起動
```

## gh-fzf: GitHub CLI + Fuzzy Finder

`gh`コマンドをfzfでラップしてPR/Issue/Actionsを高速ナビゲーション。

```bash
gh fzf pr          # PRをfzfで閲覧、checkout/merge/view
gh fzf issue       # Issueをfzfで閲覧
gh fzf run         # GitHub Actionsの実行を閲覧
gh fzf release     # リリースを閲覧
```

## gwq: Git Worktree Manager

並行開発用のworktree管理（複数Claude Codeインスタンスに最適）。

```bash
gwq add -b feature/login   # 新ブランチでworktree作成
gwq list                    # 全worktree一覧
gwq status                  # 全worktreeのstatus確認
cd $(gwq get login)         # worktreeにジャンプ
gwq remove feature/old      # worktree削除
```

## モダンCLIツール

従来のコマンドをUXの良いモダンな代替ツールにエイリアス。

### ファイル操作

| エイリアス | ツール | 置換対象 | 特徴 |
|------------|--------|----------|------|
| `ls` | eza | ls | アイコン、カラー、Git連携 |
| `ll` | eza -la | ls -la | Git status付きロングフォーマット |
| `la` | eza -a | ls -a | 隠しファイル表示 |
| `lt` | eza --tree | tree | アイコン付きツリー表示 |
| `cat` | bat | cat | シンタックスハイライト、行番号 |
| `find` | fd | find | 直感的な構文、高速、.gitignore対応 |
| `grep` | ripgrep (rg) | grep | 超高速、.gitignore対応 |

```bash
# eza例
ll                      # Git status付きリスト (M=modified, N=new)
lt -L 2                 # ツリー表示、深さ2

# bat例
bat README.md           # シンタックスハイライト表示
bat -l json data.txt    # JSON強制ハイライト
bat --diff file.txt     # git diff表示

# fd例
fd pattern              # パターンにマッチするファイル検索
fd -e js                # 全.jsファイル検索
fd -H pattern           # 隠しファイルも含む

# ripgrep例
rg "TODO"               # カレントディレクトリでTODO検索
rg -i "error" -g "*.log"  # 大文字小文字無視、.logファイルのみ
rg -C 3 "function"      # 前後3行のコンテキスト表示
```

### システム監視

| エイリアス | ツール | 置換対象 | 特徴 |
|------------|--------|----------|------|
| `ps` | procs | ps | カラフル、ツリー表示、watchモード |
| `top` | btop | top/htop | 美しいリソースモニター |
| `du` | dust | du | 直感的なディスク使用量表示 |
| `df` | duf | df | カラフルな空き容量表示 |

```bash
# procs例
ps                      # カラー付きプロセスリスト
procs --tree            # プロセスツリー表示
procs --watch           # 自動更新モード
procs zsh               # 名前でフィルタ

# dust例
dust                    # カレントディレクトリのディスク使用量
dust -d 2               # 深さ2まで
dust -r                 # 逆順（最大が最後）

# duf例
duf                     # 全マウントファイルシステム
duf /home               # 特定パスのみ
```

### テキスト処理

| エイリアス | ツール | 置換対象 | 特徴 |
|------------|--------|----------|------|
| `sed` | sd | sed | 直感的な構文、エスケープ地獄なし |
| `http` | xh | curl/httpie | カラフル出力、簡単な構文 |

```bash
# sd例
sd 'before' 'after' file.txt       # ファイル内置換
sd -F 'exact.match' 'new' file     # リテラル文字列（正規表現なし）
echo "hello" | sd 'ell' 'ipp'      # パイプ使用

# xh例
xh httpbin.org/get                 # GETリクエスト
xh POST api.example.com data=value # JSONでPOST
xh -d https://example.com/file     # ファイルダウンロード
```

### ナビゲーション & 履歴

| ツール | 置換対象 | 特徴 |
|--------|----------|------|
| zoxide | cd | 習慣を学習、`z foo`で~/projects/fooにジャンプ |
| atuin | history | SQLiteバックエンド、マシン間同期、ファジー検索 |
| fzf | - | 何でもファジーファインダー |

```bash
# zoxide例
z dotfiles              # "dotfiles"に最も頻繁にマッチするパスにジャンプ
z foo bar               # "foo"と"bar"にマッチするパスにジャンプ
zi                      # fzfでインタラクティブ選択

# atuin例
# Ctrl+Rでatuin検索（atuin initで設定済み）
atuin search "git"      # 履歴から"git"を検索
atuin stats             # シェル使用統計を表示

# fzf例
nvim $(fzf)              # fzfで選択したファイルを開く
kill -9 $(ps aux | fzf | awk '{print $2}')  # fzfでプロセスをkill
```

### Gitツール

| ツール | 用途 | 特徴 |
|--------|------|------|
| lazygit | Git TUI | キーボードでstage、commit、rebase、merge |
| delta | Git diff | シンタックスハイライト、行番号、サイドバイサイド |
| gh | GitHub CLI | ターミナルからPR、Issue、Actions |
| gh-fzf | gh + fzf | PRやIssue、runをファジー検索 |
| ghq | リポジトリ管理 | ~/repos配下にリポジトリを整理 |
| gwq | Worktree管理 | 並行ブランチ開発 |

```bash
# lazygit
lazygit                 # 現在のリポジトリでTUIを開く

# delta (.gitconfigでgit diffが自動使用)
git diff                # シンタックスハイライト付きの美しいdiff

# gh例
gh pr create            # PR作成
gh pr checkout 123      # PR #123をチェックアウト
gh issue list           # Issue一覧

# gh-fzf例
gh fzf pr               # PRをファジー検索して操作
gh fzf issue            # Issueをファジー検索
gh fzf run              # Actions runをファジー検索

# ghq例
ghq get anthropics/claude-code  # 例: ~/repos/github.com/anthropics/claude-codeにクローン
ghq list                # 全リポジトリ一覧
ghq root                # ルートディレクトリを表示

# gwq例
gwq add -b feature/x    # 新ブランチ用worktree作成
gwq list                # 全worktree一覧
gwq status              # 全worktreeのgit status
```

### Tips

**ツールを組み合わせたパワーワークフロー:**

```bash
# ファイルを検索して編集
nvim $(fd -e ts | fzf)

# 検索結果を開く
rg -l "TODO" | fzf | xargs nvim

# fzfでgit log
git log --oneline | fzf --preview 'git show {1}'

# インタラクティブにプロセスをkill
procs | fzf | awk '{print $1}' | xargs kill
```

## Claude Code設定

`~/.claude/settings.json`を管理。APIキーは含まれていないので、別途設定が必要。

### 設定内容

- **model**: デフォルトモデル (opus)
- **language**: 応答言語 (日本語)
- **permissions**: 自動許可/拒否するコマンド
- **statusLine**: ccusageでトークン使用量表示
- **hooks**: 完了時にサウンド再生

### APIキーの設定

`~/.zshrc.local`に記載（gitignore対象）:

```bash
# ~/.zshrc.local
export ANTHROPIC_API_KEY="sk-ant-..."
```

## 構成

```
.zshrc                         # メインシェル設定 (共通関数含む)
.zshrc.local                   # ローカル設定 (gitignore、APIキーなど)
.zshrc.osx                     # macOS固有設定
.zshrc.linux                   # Linux用
.zshrc.wsl                     # WSL用
.tmux.conf                     # tmux設定 (prefix: Ctrl+T)
.gitconfig                     # Git共通設定 (git管理対象)
.gitconfig.local               # Git includeIf設定 (git管理外)
.gitconfig.personal.example    # 個人用Gitテンプレート
.gitconfig.work.example        # 仕事用Gitテンプレート
Brewfile                       # Homebrewパッケージ
.config/nvim/                  # Neovim設定 (lazy.nvim, catppuccin, LSP)
.config/claude/                # Claude Code設定
.config/ghostty/               # Ghostty設定
.config/atuin/                 # Atuin設定
.config/gwq/                   # gwq設定 (worktree管理)
```
