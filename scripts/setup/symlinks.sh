#!/bin/bash
# symlinks.sh - Symlink dotfiles and config directories
# Extracted from init.sh lines 36-67

setup_symlinks() {
    log_info "Symlinking dotfiles from $DOTFILES_DIR"

    # Hidden files (excluding .gitignore)
    find "$DOTFILES_DIR" -maxdepth 1 -name ".*" -type f ! -name ".gitignore" -print0 | while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        safe_symlink "$file" "$HOME/$filename"
    done

    # .config directory
    mkdir -p "$HOME/.config"
    safe_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

    # .config subdirectories
    for config_dir in atuin ghostty nvim gwq; do
        if [ -d "$DOTFILES_DIR/.config/$config_dir" ]; then
            safe_symlink "$DOTFILES_DIR/.config/$config_dir" "$HOME/.config/$config_dir"
        fi
    done

    # .config/shell directory for cheat.sh (Phase 5)
    if [ -f "$DOTFILES_DIR/.config/shell/cheat.sh" ]; then
        mkdir -p "$HOME/.config/shell"
        safe_symlink "$DOTFILES_DIR/.config/shell/cheat.sh" "$HOME/.config/shell/cheat.sh"
    fi

    # Claude Code settings
    if [ -d "$DOTFILES_DIR/.config/claude" ]; then
        mkdir -p "$HOME/.claude"
        safe_symlink "$DOTFILES_DIR/.config/claude/settings.json" "$HOME/.claude/settings.json"
    fi
}
