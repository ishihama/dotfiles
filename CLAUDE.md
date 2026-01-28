# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary), with Linux and WSL support. Manages shell, editor, terminal multiplexer, and development tool configurations with a focus on modern CLI tools and fzf-based workflows.

## Setup Commands

```bash
# Initial installation - symlinks dotfiles, installs oh-my-zsh, Homebrew, packages, gh-fzf, and mise
./init.sh

# Reload shell
source ~/.zshrc

# Start Neovim (plugins auto-install on first launch)
nvim
```

## Architecture

**Shell Configuration (Zsh)**
- `.zshrc` - Main config with oh-my-zsh, modern CLI tool aliases, fzf widgets (ghq-tmux, gwq-tmux, git-branch, file-search, process-kill), cheat function, memo function, path setup (Go/Rust/Flutter/Android), mise, SDKMAN, zoxide, atuin, starship prompt
- `.zshrc.osx` - macOS-specific settings (currently minimal)
- `.zshrc.linux` - Linux-specific (Linuxbrew, xdg-open aliases)
- `.zshrc.wsl` - WSL-specific (Windows clipboard, X Server display)

**Neovim Configuration**
- `.config/nvim/init.lua` - Entry point, loads config modules
- `.config/nvim/lua/config/options.lua` - Basic settings (encoding, undofile, display, tabs, search)
- `.config/nvim/lua/config/keymaps.lua` - Key bindings (Space as leader, telescope, LSP, window navigation)
- `.config/nvim/lua/config/autocmds.lua` - Auto commands (memo auto-save, yank highlight, etc.)
- `.config/nvim/lua/plugins/init.lua` - lazy.nvim setup
- `.config/nvim/lua/plugins/ui.lua` - catppuccin, lualine, bufferline, gitsigns
- `.config/nvim/lua/plugins/editor.lua` - nvim-tree, telescope, treesitter, which-key
- `.config/nvim/lua/plugins/lsp.lua` - mason, lspconfig, nvim-cmp (TypeScript, Go, Python, Rust, Java, Bash)
- `.config/nvim/lua/plugins/coding.lua` - autopairs, comment, surround

**Other Configs**
- `.tmux.conf` - Prefix is `C-t` (not default `C-b`), vim-style pane navigation (h/j/k/l), vim-style pane resize (H/J/K/L), `|` for vertical split, `-` for horizontal split, mouse enabled, clipboard integration via pbcopy, popup bindings: prefix+g (ghq-tmux), prefix+w (gwq-tmux)
- `.gitconfig` - User settings (in .gitconfig.local), commit template (`~/.gitmessage`), rebase on pull, delta pager, ghq root (`~/repos`)
- `.gitmessage` - Commit message template with emoji conventions
- `.mise.toml` - mise version manager config (replacement for asdf)
- `starship.toml` - Starship prompt configuration
- `lefthook.yml` - Git hooks configuration
- `.config/atuin/` - Atuin shell history sync config
- `.config/ghostty/` - Ghostty terminal emulator config (catppuccin theme)

**Package Management**
- `Brewfile` - Homebrew packages (modern CLI tools: bat, eza, fd, ripgrep, procs, dust, duf, sd, btop, xh, zoxide, atuin, fzf, lazygit, delta, gh, ghq, gwq, mise, neovim, etc.), casks, Mac App Store apps

## Key Workflows

**ghq + fzf + tmux (`Ctrl+G` or tmux prefix+g)**
- Selects repository from ghq list with fzf preview (README.md or git log)
- Creates/attaches tmux session named `{owner}-{repo}` (dots replaced with dashes)
- Behavior differs inside/outside tmux (switch-client vs attach-session)
- Defined in `.zshrc`

**gwq + fzf + tmux (`Ctrl+W` or tmux prefix+w)**
- Selects worktree from gwq list with fzf preview (git log)
- Creates/attaches tmux session named `{repo}-{branch}` (dots and slashes replaced with dashes)
- Enables parallel development across branches with separate Claude Code instances
- Defined in `.zshrc`

**Modern CLI Tool Aliases**
- All defined in `.zshrc` - traditional commands aliased to modern alternatives (cat→bat, ls→eza, grep→rg, find→fd, ps→procs, du→dust, df→duf, sed→sd, top→btop, http→xh, vi/vim→nvim)
- Important: SDKMAN init temporarily unaliases `find` to avoid conflicts, then restores it

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
- `init.sh` contains `link_file()` helper that backs up existing files with timestamp before symlinking
- Symlinks all dotfiles from repo to `$HOME`, plus `.config/` subdirectories (nvim, atuin, ghostty, claude)

**Platform Detection**
- `.zshrc` detects OS via `uname` and sources platform-specific config
- macOS is the primary platform; common functions are in `.zshrc` (not `.zshrc.osx`)

**Neovim Key Bindings**
- `Space` - Leader key
- `Space+e` - Toggle file tree (nvim-tree)
- `Space+ff` - Find files (telescope)
- `Space+fg` - Grep search (telescope)
- `gd` - Go to definition
- `gr` - References
- `K` - Hover info
- `Space+ca` - Code action
- `Space+rn` - Rename
- `gcc` - Toggle line comment
- `Tab/Shift+Tab` - Window navigation
