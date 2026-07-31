# completions.sh - CLI completion file generation

# Generate completion files (run on first setup or when updating)
COMPLETION_DIR=~/.zsh/completions

# Generate one completion file atomically.
#
# `cmd > "$dir/_gh"` truncates the destination *before* the generator runs, so
# any failure leaves a zero-byte file on fpath and breaks compinit in every
# later shell. Write to a temp file and only move it into place on success.
function _gen-completion() {
    local name=$1
    shift
    local cmd=$1

    command -v "$cmd" &>/dev/null || return 0

    local tmp
    tmp=$(mktemp) || return 1

    if "$@" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
        mv "$tmp" "$COMPLETION_DIR/$name"
        print "  ✓ $name"
    else
        rm -f "$tmp"
        print -u2 "  ✗ $name (generator failed)"
    fi
}

function setup-completions() {
    mkdir -p "$COMPLETION_DIR" || return 1

    print "Generating completions..."

    _gen-completion _gh      gh      gh completion -s zsh
    _gen-completion _mise    mise    mise completion zsh
    _gen-completion _docker  docker  docker completion zsh
    _gen-completion _rustup  rustup  rustup completions zsh
    _gen-completion _cargo   rustup  rustup completions zsh cargo
    _gen-completion _pnpm    pnpm    pnpm completion zsh
    _gen-completion _kubectl kubectl kubectl completion zsh
    _gen-completion _helm    helm    helm completion zsh

    # fzf ships its completion file rather than generating it
    local fzf_completion
    for fzf_completion in \
        /opt/homebrew/opt/fzf/shell/completion.zsh \
        /usr/local/opt/fzf/shell/completion.zsh \
        /home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh
    do
        if [[ -f "$fzf_completion" ]]; then
            cp "$fzf_completion" "$COMPLETION_DIR/_fzf" && print "  ✓ _fzf"
            break
        fi
    done

    print "Done! Restart shell or run: source ~/.zshrc"
}

# Nudge on first run. This must go to stderr and only in an interactive shell:
# writing to stdout from a startup file corrupts scp/rsync/sftp sessions.
if [[ -o interactive ]] && [[ ! -d "$COMPLETION_DIR" ]]; then
    print -u2 "Run 'setup-completions' to enable CLI completions"
fi
return 0
