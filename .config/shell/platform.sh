# platform.sh - OS detection, platform-specific config, SDKMAN

# OS Type
if [ "$(uname)" = 'Darwin' ]; then
    source ${HOME}/.zshrc.osx
elif [ "$(uname)" = 'Linux' ]; then
    source ${HOME}/.zshrc.linux
else
    echo "Unknown OS Type....."
fi

autoload -U +X bashcompinit && bashcompinit

# SDKMAN (via Homebrew)
# Temporarily unalias find (SDKMAN init script uses find -type)
unalias find 2>/dev/null
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
alias find='fd'  # Restore
