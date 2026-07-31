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
    claude
    ghostty
    git
    gitmux
    gwq
    hammerspoon
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
    local file
    for file in "${ROOT_DOTFILES[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            safe_symlink "$DOTFILES_DIR/$file" "$HOME/$file"
        fi
    done

    # .config directories → $HOME/.config/
    run_cmd mkdir -p "$HOME/.config"
    local dir
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

    # Claude Code reads its config from ~/.claude/settings.json (not ~/.config/claude/),
    # so we additionally symlink settings.json there. The rest of .config/claude/
    # (hooks/, bin/) is symlinked via CONFIG_DIRS above.
    if [ -f "$DOTFILES_DIR/.config/claude/settings.json" ]; then
        run_cmd mkdir -p "$HOME/.claude"
        safe_symlink "$DOTFILES_DIR/.config/claude/settings.json" "$HOME/.claude/settings.json"
    fi

    # Hammerspoon reads ~/.hammerspoon/init.lua (XDG非対応バージョンがあるため
    # ~/.config/hammerspoon に加えて ~/.hammerspoon もリンクする)
    if [ -d "$DOTFILES_DIR/.config/hammerspoon" ]; then
        safe_symlink "$DOTFILES_DIR/.config/hammerspoon" "$HOME/.hammerspoon"
    fi

    # SSH config (personal + Include ~/.ssh/config.local for per-machine/work entries)
    if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
        run_cmd mkdir -p "$HOME/.ssh"
        run_cmd chmod 700 "$HOME/.ssh"
        safe_symlink "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    fi

    # Clean up old symlinks from pre-XDG layout
    cleanup_old_symlinks
}

cleanup_old_symlinks() {
    local old_link target
    for old_link in "${OLD_SYMLINKS[@]}"; do
        [ -L "$old_link" ] || continue
        target=$(readlink "$old_link")

        # Only remove links into *this* checkout. Matching on the substring
        # "dotfiles" would also eat an unrelated ~/src/work-dotfiles link.
        if [ "$target" = "$DOTFILES_DIR" ] || [ "${target#"$DOTFILES_DIR"/}" != "$target" ]; then
            run_cmd rm "$old_link"
            is_dry_run || log_info "Cleaned up old symlink: $old_link"
        else
            log_skip "Leaving foreign symlink alone: $old_link -> $target"
        fi
    done
}
