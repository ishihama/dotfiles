# env.sh - Environment variables, PATH, and tool initialization

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"

# Editor (Claude Code's Ctrl+G etc.)
export EDITOR=nvim
export VISUAL=nvim

# less
export LESSCHARSET=utf-8

# ls color
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'

# Completion colors
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Golang
export PATH="$HOME/go/bin:$PATH"

# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export ANDROID_AVD_HOME="$HOME/.android/avd"
export PATH="${ANDROID_SDK_ROOT}/tools:$PATH"
export PATH="${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# mise (asdf alternative)
eval "$(mise activate zsh)"

# direnv
eval "$(direnv hook zsh)"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# atuin (shell history)
eval "$(atuin init zsh)"

# starship prompt
eval "$(starship init zsh)"
