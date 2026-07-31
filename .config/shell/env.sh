# env.sh - Environment variables, PATH, and tool initialization

# XDG Base Directory. Respect an already-set value: .zshrc and the popup
# scripts under bin/ all read ${XDG_CONFIG_HOME:-$HOME/.config}, so clobbering
# it here would leave them pointing at different roots.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

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

# Claude Code helpers (claude-status etc.)
export PATH="$HOME/.config/claude/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Tool initialization. Guarded so that a single missing tool does not print
# "command not found" on every shell start.
#   mise     - version manager (asdf alternative)
#   direnv   - per-directory env
#   zoxide   - smarter cd
#   atuin    - shell history (owns Ctrl+R; see fzf-widgets.sh)
#   starship - prompt
command -v mise     >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v direnv   >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v atuin    >/dev/null 2>&1 && eval "$(atuin init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# The chain above leaves $? set by the last `command -v`; don't let that leak
# into the caller as an apparent failure.
true
