# platform.sh - OS detection, platform-specific config, SDKMAN

# OS Type
case "$(uname)" in
    Darwin) [[ -f "${HOME}/.zshrc.osx" ]] && source "${HOME}/.zshrc.osx" ;;
    Linux)  [[ -f "${HOME}/.zshrc.linux" ]] && source "${HOME}/.zshrc.linux" ;;
    *)      print -u2 "platform.sh: unknown OS type $(uname)" ;;
esac

autoload -U +X bashcompinit && bashcompinit

# SDKMAN (via Homebrew)
if command -v brew >/dev/null 2>&1; then
    export SDKMAN_DIR="$(brew --prefix sdkman-cli 2>/dev/null)/libexec"
    if [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
        # The SDKMAN init script calls `find -type`, which breaks against the
        # find->fd alias, so drop it for the duration and restore afterwards.
        # aliases.sh only defines it in interactive shells, so only restore it
        # there - otherwise this would reintroduce the alias that non-interactive
        # shells (Claude Code's Bash tool, CI scripts) rely on not existing.
        unalias find 2>/dev/null
        source "${SDKMAN_DIR}/bin/sdkman-init.sh"
        [[ -o interactive ]] && alias find='fd'
    fi
fi
