export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# oh-my-zsh
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="lukerandall"
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# aliases
alias vi=vim
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
export PATH="/Users/REDACTED/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# SDKMAN (via Homebrew)
# findエイリアスを一時解除 (SDKMAN init scriptがfind -typeを使うため)
unalias find 2>/dev/null
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
alias find='fd'  # 復元

