# ===========================================
# Taps
# ===========================================
tap "d-kuro/tap"
tap "sdkman/tap"

# ===========================================
# Core CLI Utilities
# ===========================================
# GNU coreutils/findutils/gawk/gnu-sed/grep は入れない:
# gnubin へのPATHを通していないため g接頭辞コマンドしか使えず、
# かつ aliases.sh が grep->rg, sed->sd, find->fd を割り当てているので出番がない。
brew "tree"
brew "jq"
brew "yq"

# ===========================================
# Modern Replacements
# ===========================================
brew "bat"           # cat replacement
brew "btop"          # top replacement
brew "duf"           # df replacement
brew "dust"          # du replacement
brew "eza"           # ls replacement
brew "fd"            # find replacement
brew "procs"         # ps replacement
brew "ripgrep"       # grep replacement
brew "sd"            # sed replacement
brew "tokei"         # cloc replacement
brew "xh"            # curl replacement

# ===========================================
# Shell & Terminal
# ===========================================
brew "atuin"         # shell history
brew "direnv"        # directory-based env vars
brew "fzf"           # fuzzy finder
brew "starship"      # prompt
brew "tmux"          # terminal multiplexer
brew "yazi"          # file manager
brew "zoxide"        # smarter cd
brew "zsh"           # shell

# ===========================================
# Git & GitHub
# ===========================================
brew "gh"            # GitHub CLI
brew "ghq"           # repository manager
brew "git"           # version control
brew "git-delta"     # better diff
brew "git-secrets"   # secret detection
brew "gitmux"        # git status in tmux
brew "lazygit"       # git TUI
brew "lefthook"      # git hooks manager
brew "d-kuro/tap/gwq" # git worktree manager

# ===========================================
# Editor
# ===========================================
brew "neovim"

# ===========================================
# Languages & Runtimes
# ===========================================
brew "mise"          # version manager (asdf alternative)
brew "sdkman/tap/sdkman-cli" # JVM version manager
# node / go / deno / python は mise (config.toml) で管理

# ===========================================
# Cloud & Infrastructure
# ===========================================
# terraform / tflint は mise (config.toml) で管理

# ===========================================
# Containers & Orchestration
# ===========================================
# kubectl, helm etc. via mise or manual install

# ===========================================
# Media & Processing
# ===========================================
brew "ffmpeg"
brew "imagemagick"

# ===========================================
# Mobile Development
# ===========================================
brew "cocoapods"
brew "libimobiledevice"
brew "ideviceinstaller"
brew "ios-deploy"

# ===========================================
# Build & Compile
# ===========================================
brew "maven"

# ===========================================
# Data & Databases
# ===========================================
# PostgreSQL / Redis はローカルインストールせず Rancher (cask) でコンテナ起動

# ===========================================
# Documentation & Presentation
# ===========================================
brew "gibo"          # .gitignore generator
brew "glow"          # markdown renderer
brew "hyperfine"     # benchmarking
brew "tldr"          # simplified man pages

# ===========================================
# Casks (GUI Applications)
# ===========================================
# android-platform-tools はcask管理しない:
# Googleが同一URLでファイルを差し替えるたびにchecksum不一致でbrew bundle全体が
# 失敗するため。adb等はAndroid StudioのSDK Manager (Settings > Languages &
# Frameworks > Android SDK > SDK Tools > Android SDK Platform-Tools) で管理する。
# PATHは env.sh が ~/Library/Android/sdk/platform-tools を通している。
cask "android-studio"
cask "gcloud-cli"
cask "ghostty"
cask "google-chrome"
cask "hammerspoon"   # Space越しウィンドウフォーカス (claude-status jump)
cask "intellij-idea-ce"
cask "microsoft-word"
cask "rancher"
cask "slack"
cask "slack-cli"
cask "zoom"

# ===========================================
# Mac App Store
# ===========================================
# Apple純正 (Keynote/Numbers/Pages) はOSプリインストール済みのため除外
mas "Microsoft Excel", id: 462058435
mas "Microsoft PowerPoint", id: 462062816
