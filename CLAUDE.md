# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary), with Linux and WSL support. Manages shell, editor, terminal multiplexer, and development tool configurations.

## Setup Commands

```bash
# Initial installation - symlinks dotfiles, installs oh-my-zsh, Homebrew, packages, and dein
./init.sh

# Install/update Homebrew packages
brew bundle
```

## Architecture

**Shell Configuration (Zsh)**
- `.zshrc` - Main config with oh-my-zsh, paths for Go/Node/Rust/Flutter/Android, asdf, SDKMAN
- `.zshrc.osx` - macOS-specific (FZF, iTerm2 integration)
- `.zshrc.linux` - Linux-specific (Linuxbrew, xdg-open aliases)
- `.zshrc.wsl` - WSL-specific (Windows clipboard, X Server display)

**Vim Configuration**
- `.vimrc` - Main config, sources LSP and plugin configs
- `.vim/config/dein.vim` - Dein plugin manager setup
- `.vim/config/lsp.vim` - Language Server Protocol settings
- `.vim/rc/dein.toml` - Plugin specifications (100+ plugins)

**Other Configs**
- `.tmux.conf` - Prefix is `C-t`, vim-style navigation, mouse enabled
- `.gitconfig` - User settings, commit template, rebase-on-pull
- `.gitmessage` - Commit message template with emoji conventions
- `.tool-versions` - asdf versions (Node.js, Terraform)

**Package Management**
- `Brewfile` - Homebrew packages, casks, VSCode extensions, Mac App Store apps

## Git Commit Conventions

From `.gitmessage`, use emoji prefixes:
- `:tada:` Initial commit
- `:bookmark:` Version tag
- `:sparkles:` New feature
- `:bug:` Bug fix
- `:recycle:` Refactoring
- `:memo:` Documentation
- `:art:` Design/UI
- `:shirt:` Lint fix
- `:rocket:` Performance
- `:white_check_mark:` Tests
- `:construction:` WIP
