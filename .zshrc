export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Custom completion directory (set before oh-my-zsh compinit)
fpath=(~/.zsh/completions $fpath)

# oh-my-zsh
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="lukerandall"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Shell modules
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
source "$SHELL_CONFIG/env.sh"
source "$SHELL_CONFIG/aliases.sh"
source "$SHELL_CONFIG/ghq-tmux.sh"
source "$SHELL_CONFIG/gwq-tmux.sh"
source "$SHELL_CONFIG/gwq-wrapper.sh"
source "$SHELL_CONFIG/gh-wrapper.sh"
source "$SHELL_CONFIG/fzf-widgets.sh"
source "$SHELL_CONFIG/memo.sh"
source "$SHELL_CONFIG/completions.sh"
source "$SHELL_CONFIG/cheat.sh"
source "$SHELL_CONFIG/platform.sh"

# AsyncAPI CLI autocomplete (installer appends an absolute-path version; kept portable here)
ASYNCAPI_AC_ZSH_SETUP_PATH="$HOME/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup"
[[ -f "$ASYNCAPI_AC_ZSH_SETUP_PATH" ]] && source "$ASYNCAPI_AC_ZSH_SETUP_PATH"

# NOTE: Rancher Desktop PATH is handled in env.sh ($HOME/.rd/bin) - do not duplicate here

# Local settings (API keys etc., gitignored)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
