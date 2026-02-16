# completions.sh - CLI completion file generation

# Generate completion files (run on first setup or when updating)
function setup-completions() {
    local comp_dir=~/.zsh/completions
    mkdir -p "$comp_dir"

    echo "Generating completions..."

    # GitHub CLI
    command -v gh &>/dev/null && gh completion -s zsh > "$comp_dir/_gh"

    # mise
    command -v mise &>/dev/null && mise completion zsh > "$comp_dir/_mise"

    # Docker
    command -v docker &>/dev/null && docker completion zsh > "$comp_dir/_docker"

    # Rustup & Cargo
    command -v rustup &>/dev/null && rustup completions zsh > "$comp_dir/_rustup"
    command -v rustup &>/dev/null && rustup completions zsh cargo > "$comp_dir/_cargo"

    # pnpm
    command -v pnpm &>/dev/null && pnpm completion zsh > "$comp_dir/_pnpm"

    # kubectl
    command -v kubectl &>/dev/null && kubectl completion zsh > "$comp_dir/_kubectl"

    # helm
    command -v helm &>/dev/null && helm completion zsh > "$comp_dir/_helm"

    # fzf
    [[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && cp /opt/homebrew/opt/fzf/shell/completion.zsh "$comp_dir/_fzf"

    echo "Done! Restart shell or run: source ~/.zshrc"
}

# Prompt initial setup if completion directory doesn't exist
[[ ! -d ~/.zsh/completions ]] && echo "Run 'setup-completions' to enable CLI completions"
