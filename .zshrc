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

# Local settings (API keys etc., gitignored)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
