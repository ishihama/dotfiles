# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary), with Linux and WSL support. Manages shell, editor, terminal multiplexer, and development tool configurations with a focus on modern CLI tools and fzf-based workflows.

## Setup Commands

```bash
# Initial installation - symlinks dotfiles, installs oh-my-zsh, Homebrew, packages, dein, and mise
./init.sh

# Install/update Homebrew packages (includes gwq, gh, and other tools)
brew bundle

# Install gh-fzf extension
gh extension install benelan/gh-fzf

# Reload shell
source ~/.zshrc
```

## Architecture

**Shell Configuration (Zsh)**
- `.zshrc` - Main config with oh-my-zsh, modern CLI tool aliases, path setup (Go/Rust/Flutter/Android), mise (asdf replacement), SDKMAN, zoxide, atuin, starship prompt
- `.zshrc.osx` - macOS-specific with key bindings: `Ctrl+G` (ghq-tmux), `Ctrl+W` (gwq-tmux), `Ctrl+B` (git branch fzf), `Ctrl+F` (file search+vim), `Ctrl+K` (procs kill), `cheat` function, iTerm2 integration
- `.zshrc.linux` - Linux-specific (Linuxbrew, xdg-open aliases)
- `.zshrc.wsl` - WSL-specific (Windows clipboard, X Server display)

**Important:** The `.zshrc.osx` file contains critical fzf-based workflow functions that integrate ghq, gwq, and tmux for repository/worktree management.

**Vim Configuration**
- `.vimrc` - Main config with encoding, undofile (persistent undo in `~/.vim/undo`), display settings, sources `.vim/config/dein.vim` and `.vim/config/lsp.vim`
- `.vim/config/dein.vim` - Dein plugin manager setup, loads `.vim/rc/dein.toml` and `.vim/rc/dein_lazy.toml`
- `.vim/config/lsp.vim` - Language Server Protocol settings
- `.vim/rc/dein.toml` - Plugin specifications
- `.vim/rc/dein_lazy.toml` - Lazy-loaded plugins

**Other Configs**
- `.tmux.conf` - Prefix is `C-t` (not default `C-b`), vim-style pane navigation (h/j/k/l), vim-style pane resize (H/J/K/L), `|` for vertical split, `-` for horizontal split, mouse enabled, clipboard integration via pbcopy, popup bindings: prefix+g (ghq-tmux), prefix+w (gwq-tmux)
- `.gitconfig` - User settings, commit template (`~/.gitmessage`), rebase on pull, delta pager, ghq root (`~/repos`)
- `.gitmessage` - Commit message template with emoji conventions
- `.mise.toml` - mise version manager config (replacement for asdf)
- `starship.toml` - Starship prompt configuration
- `lefthook.yml` - Git hooks configuration
- `.config/atuin/` - Atuin shell history sync config
- `.config/ghostty/` - Ghostty terminal emulator config

**Package Management**
- `Brewfile` - Homebrew packages (modern CLI tools: bat, eza, fd, ripgrep, procs, dust, duf, sd, btop, xh, zoxide, atuin, fzf, lazygit, delta, gh, ghq, gwq, mise, etc.), casks, Mac App Store apps

## Key Workflows

**ghq + fzf + tmux (`Ctrl+G` or tmux prefix+g)**
- Selects repository from ghq list with fzf preview (README.md or git log)
- Creates/attaches tmux session named `{owner}-{repo}` (dots replaced with dashes)
- Behavior differs inside/outside tmux (switch-client vs attach-session)
- Widget: `.zshrc.osx:10-34`, exec: `.zshrc.osx:37-56`

**gwq + fzf + tmux (`Ctrl+W` or tmux prefix+w)**
- Selects worktree from gwq list with fzf preview (git log)
- Creates/attaches tmux session named `{repo}-{branch}` (dots and slashes replaced with dashes)
- Enables parallel development across branches with separate Claude Code instances
- Widget: `.zshrc.osx:76-96`, exec: `.zshrc.osx:98-117`

**Modern CLI Tool Aliases**
- All defined in `.zshrc:10-23` - traditional commands aliased to modern alternatives (cat→bat, ls→eza, grep→rg, find→fd, ps→procs, du→dust, df→duf, sed→sd, top→btop, http→xh)
- Important: SDKMAN init temporarily unaliases `find` at `.zshrc:88-93` to avoid conflicts, then restores it

## Git Commit Conventions

From `.gitmessage`, use emoji prefixes:
- `:tada:` (🎉) - Initial commit
- `:bookmark:` (🔖) - Version tag
- `:sparkles:` (✨) - New feature
- `:bug:` (🐛) - Bug fix
- `:recycle:` (♻️) - Refactoring
- `:books:` (📚) - Documentation (use `:memo:` for README changes)
- `:art:` (🎨) - Design/UI/UX
- `:horse:` (🐎) - Performance
- `:wrench:` (🔧) - Tooling
- `:rotating_light:` (🚨) - Tests
- `:hankey:` (💩) - Deprecation
- `:wastebasket:` (🗑️) - Removal
- `:construction:` (🚧) - WIP

Note: The existing commit history uses `:memo:` for documentation, not `:books:`.

## Development Notes

**Symlink Management**
- `init.sh:13-33` contains `link_file()` helper that backs up existing files with timestamp before symlinking
- Symlinks all dotfiles from repo to `$HOME`, plus `.vim` directory and `.config/` subdirectories

**Platform Detection**
- `.zshrc:71-80` detects OS via `uname` and sources platform-specific config
- macOS is the primary platform with the most features in `.zshrc.osx`

**Persistent Undo**
- Vim undofile enabled at `.vimrc:19-23`, stores in `~/.vim/undo/` (created automatically if missing)
