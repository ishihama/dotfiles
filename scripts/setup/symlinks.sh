#!/bin/bash
# symlinks.sh - Symlink dotfiles and config directories (XDG-compliant)

# Explicit list of root dotfiles to symlink to $HOME
ROOT_DOTFILES=(
    .zshrc
    .zshrc.osx
    .zshrc.linux
    .zshrc.wsl
    .editorconfig
)

# .config directories to symlink as whole directories
CONFIG_DIRS=(
    atuin
    ghostty
    git
    gitmux
    gwq
    lazygit
    mise
    nvim
    shell
    tmux
)

# .config files to symlink individually
CONFIG_FILES=(
    starship.toml
)

# Old symlinks to clean up (from pre-XDG layout)
OLD_SYMLINKS=(
    "$HOME/.gitconfig"
    "$HOME/.gitmessage"
    "$HOME/.gitmux.conf"
    "$HOME/.tmux.conf"
    "$HOME/.mise.toml"
)

setup_symlinks() {
    log_info "Symlinking dotfiles from $DOTFILES_DIR"

    # Root dotfiles → $HOME
    for file in "${ROOT_DOTFILES[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            safe_symlink "$DOTFILES_DIR/$file" "$HOME/$file"
        fi
    done

    # .config directories → $HOME/.config/
    mkdir -p "$HOME/.config"
    for dir in "${CONFIG_DIRS[@]}"; do
        if [ -d "$DOTFILES_DIR/.config/$dir" ]; then
            safe_symlink "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
        fi
    done

    # .config files → $HOME/.config/
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$DOTFILES_DIR/.config/$file" ]; then
            safe_symlink "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
        fi
    done

    # Claude Code settings
    if [ -d "$DOTFILES_DIR/.config/claude" ]; then
        mkdir -p "$HOME/.claude"
        safe_symlink "$DOTFILES_DIR/.config/claude/settings.json" "$HOME/.claude/settings.json"
    fi

    # Clean up old symlinks from pre-XDG layout
    cleanup_old_symlinks
}

cleanup_old_symlinks() {
    for old_link in "${OLD_SYMLINKS[@]}"; do
        if [ -L "$old_link" ]; then
            local target=$(readlink "$old_link")
            # Only remove if it points to our dotfiles repo
            if [[ "$target" == *"dotfiles"* ]]; then
                rm "$old_link"
                log_info "Cleaned up old symlink: $old_link"
            fi
        fi
    done
}
