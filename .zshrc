export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Custom completion directory (set before oh-my-zsh compinit)
fpath=(~/.zsh/completions $fpath)

# oh-my-zsh
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="lukerandall"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Shell modules.
# Load order matters: env.sh first (PATH and tool init), platform.sh last
# (SDKMAN needs the aliases to already exist). Each is guarded so that one
# broken symlink cannot stop the rest of the file from loading.
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
for _mod in \
    env.sh \
    aliases.sh \
    ghq-tmux.sh \
    gwq-tmux.sh \
    gwq-wrapper.sh \
    gh-wrapper.sh \
    fzf-widgets.sh \
    memo.sh \
    completions.sh \
    cheat.sh \
    platform.sh
do
    if [[ -r "$SHELL_CONFIG/$_mod" ]]; then
        source "$SHELL_CONFIG/$_mod"
    else
        print -u2 "zshrc: missing shell module: $SHELL_CONFIG/$_mod"
    fi
done
unset _mod

# AsyncAPI CLI autocomplete (installer appends an absolute-path version; kept portable here)
ASYNCAPI_AC_ZSH_SETUP_PATH="$HOME/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup"
[[ -f "$ASYNCAPI_AC_ZSH_SETUP_PATH" ]] && source "$ASYNCAPI_AC_ZSH_SETUP_PATH"

# NOTE: Rancher Desktop PATH is handled in env.sh ($HOME/.rd/bin) - do not duplicate here

# Local settings (API keys etc., gitignored)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# NOTE: Rancher Desktop's installer appends a block here that hardcodes an
# absolute /Users/<name>/.rd/bin path. env.sh already puts $HOME/.rd/bin on
# PATH portably, so delete that block if it reappears.
