# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary), with Linux and WSL support. Manages shell, editor, terminal multiplexer, and development tool configurations with a focus on modern CLI tools and fzf-based workflows. Follows XDG Base Directory specification where possible.

## Setup Commands

```bash
# Initial installation - modular setup with interactive Git configuration
./init.sh

# Dry run (preview changes without applying)
./init.sh --dry-run

# Validate setup
./scripts/validate.sh

# Reload shell
source ~/.zshrc

# Start Neovim (plugins auto-install on first launch)
nvim
```

**Git Configuration**: The setup script will interactively configure Git accounts if `.gitconfig.local` doesn't exist. It automatically generates:
- `~/.gitconfig.local` - includeIf directives for directory-based account switching
- `~/.gitconfig.personal` - Personal account settings (name, email, SSH key)
- `~/.gitconfig.work` - Work account settings (optional)

Repository clones via `gh repo clone` will automatically use the correct Git identity based on directory path.

## Architecture

**Setup Scripts** (Modular Architecture)
- `init.sh` - Main orchestrator (thin wrapper that coordinates setup modules, supports `--dry-run`)
- `scripts/lib/core.sh` - Core utilities (logging, error handling, symlink management, DRY_RUN support)
- `scripts/lib/platform.sh` - Platform detection (macOS/Linux/WSL)
- `scripts/setup/symlinks.sh` - Dotfile symlink management (explicit file lists, XDG-compliant, old symlink cleanup)
- `scripts/setup/homebrew.sh` - Homebrew and package installation
- `scripts/setup/shell.sh` - oh-my-zsh and plugins
- `scripts/setup/git.sh` - **Interactive Git configuration with auto-generation**
- `scripts/setup/tools.sh` - Additional tools (delta, pokemon, TPM, mise)
- `scripts/validate.sh` - Post-setup validation (XDG paths, shell modules, old symlink detection)

**Shell Configuration (Zsh)**
- `.zshrc` - Thin loader (~26 lines) that sources oh-my-zsh and shell modules from `.config/shell/`
- `.config/shell/env.sh` - Environment variables, PATH (Homebrew/Go/Flutter/Android/Rust/Rancher), tool initialization (mise, direnv, zoxide, atuin, starship)
- `.config/shell/aliases.sh` - Modern CLI tool aliases (cat->bat, ls->eza, grep->rg, find->fd, etc.) + lazygit
- `.config/shell/ghq-tmux.sh` - ghq+fzf+tmux integration (Ctrl+G or tmux prefix+g)
- `.config/shell/gwq-tmux.sh` - gwq+fzf+tmux integration (Ctrl+W or tmux prefix+w) + tmux-session-fzf
- `.config/shell/gwq-wrapper.sh` - gwq wrapper function (add -i interactive, auto-cd after add)
- `.config/shell/fzf-widgets.sh` - fzf widgets: history(Ctrl+R), git-branch(Ctrl+B), file-search(Ctrl+F), process-kill(Ctrl+K)
- `.config/shell/memo.sh` - memo/memo-search functions
- `.config/shell/completions.sh` - setup-completions function for CLI completion generation
- `.config/shell/platform.sh` - OS detection, platform-specific config loading, SDKMAN initialization
- `.config/shell/cheat.sh` - Cheatsheet function (fzf-based keybinding reference)
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

**Other Configs (XDG-compliant)**
- `.config/tmux/tmux.conf` - Prefix is `C-t` (not default `C-b`), vim-style pane navigation (h/j/k/l), vim-style pane resize (H/J/K/L), `|` for vertical split, `-` for horizontal split, mouse enabled, clipboard integration via pbcopy, popup bindings: prefix+g (ghq-tmux), prefix+w (gwq-tmux), status bar shows CPU (C:) and RAM (M:) usage, Pokemon displayed on new session
- `.config/git/config` - Common settings, default user (INVALID/invalid@example.com for accident prevention), includes `.gitconfig.local`, commit template, delta pager, ghq root (`~/repos`)
- `.config/git/message` - Commit message template with emoji conventions
- `.config/git/ignore` - Global gitignore (.DS_Store, .idea/, .vscode/, etc.)
- `.gitconfig.local` - includeIf directives for multi-account support (NOT git-managed, created per environment)
- `.gitconfig.personal.example` / `.gitconfig.work.example` - Templates for account-specific configs (git-managed templates, actual files are NOT git-managed)
- `.config/mise/config.toml` - mise version manager config (replacement for asdf)
- `.config/starship.toml` - Starship prompt configuration
- `.config/gitmux/config.yml` - gitmux configuration (git status in tmux status bar)
- `.config/atuin/` - Atuin shell history sync config
- `.config/ghostty/` - Ghostty terminal emulator config (catppuccin theme, tmux integration keybindings: Cmd+T=prefix, Cmd+N=new window, Cmd+W=close pane, Cmd+1-9=window switch, Cmd+H/J/K/L=pane nav, Cmd+\=vsplit, Cmd+-=hsplit)
- `.config/gwq/config.toml` - gwq configuration (basedir: `~/repos`)
- `.config/lazygit/config.yml` - lazygit custom commands (gh PR integration: list, view, checkout, create, diff)

**Package Management**
- `Brewfile` - Homebrew packages organized by category (Modern CLI tools, Shell & Terminal, Git & GitHub, Languages, Cloud, etc.), casks, Mac App Store apps, VS Code extensions

## Directory Structure

```
dotfiles/
├── .zshrc                       # Thin loader (~26 lines, sources .config/shell/)
├── .zshrc.{osx,linux,wsl}      # Platform-specific configs
├── .editorconfig                # Editor config ($HOME required, XDG non-compliant)
│
├── .config/
│   ├── shell/                   # Shell modules (sourced by .zshrc)
│   │   ├── env.sh              # Environment variables + PATH + tool init
│   │   ├── aliases.sh          # Modern CLI tool aliases
│   │   ├── ghq-tmux.sh         # ghq+fzf+tmux integration
│   │   ├── gwq-tmux.sh         # gwq+fzf+tmux integration + session-fzf
│   │   ├── gwq-wrapper.sh      # gwq wrapper function
│   │   ├── fzf-widgets.sh      # fzf widgets (history/branch/file/kill)
│   │   ├── memo.sh             # memo functions
│   │   ├── completions.sh      # CLI completion generation
│   │   ├── platform.sh         # OS detection + SDKMAN
│   │   └── cheat.sh            # Cheatsheet function
│   ├── git/                     # Git configuration (XDG native)
│   │   ├── config              # Main git config
│   │   ├── message             # Commit message template
│   │   └── ignore              # Global gitignore
│   ├── tmux/                    # tmux configuration (XDG native since 3.2+)
│   │   └── tmux.conf
│   ├── mise/                    # mise version manager (XDG native)
│   │   └── config.toml
│   ├── gitmux/                  # gitmux (git status in tmux)
│   │   └── config.yml
│   ├── starship.toml            # Starship prompt (XDG native)
│   ├── nvim/                    # Neovim (already modular)
│   ├── atuin/                   # Atuin shell history
│   ├── ghostty/                 # Ghostty terminal
│   ├── gwq/                     # gwq worktree manager
│   ├── lazygit/                 # lazygit configuration
│   │   └── config.yml
│   └── claude/                  # Claude Code settings
│
├── Brewfile                     # Homebrew packages (categorized)
├── init.sh                      # Setup orchestrator (--dry-run support)
├── .gitconfig.personal.example  # Git account template
├── .gitconfig.work.example      # Git account template
├── CLAUDE.md
├── README.md
├── .gitignore
│
└── scripts/
    ├── lib/
    │   ├── core.sh              # Logging, error handling, DRY_RUN support
    │   └── platform.sh          # Platform detection
    ├── setup/
    │   ├── symlinks.sh          # Explicit file list + XDG dirs + old symlink cleanup
    │   ├── homebrew.sh
    │   ├── shell.sh
    │   ├── git.sh
    │   └── tools.sh
    └── validate.sh              # XDG paths + shell modules + old symlink detection
```

**Note**: Files created during setup (NOT in git):
- `~/.gitconfig.local` - Generated by `scripts/setup/git.sh`
- `~/.gitconfig.personal` - Generated by `scripts/setup/git.sh`
- `~/.gitconfig.work` - Generated by `scripts/setup/git.sh` (optional)

## Key Workflows

**ghq + fzf + tmux (`Ctrl+G` or tmux prefix+g)**
- Selects repository from ghq list with fzf preview (README.md or git log)
- Creates/attaches tmux session named `{owner}-{repo}` (dots replaced with dashes)
- Behavior differs inside/outside tmux (switch-client vs attach-session)
- Defined in `.config/shell/ghq-tmux.sh`

**gwq + fzf + tmux (`Ctrl+W` or tmux prefix+w)**
- Selects worktree from gwq list with fzf preview (git log)
- Creates/attaches tmux session named `{repo}-{branch}` (dots and slashes replaced with dashes)
- Enables parallel development across branches with separate Claude Code instances
- Defined in `.config/shell/gwq-tmux.sh`

**Modern CLI Tool Aliases**
- All defined in `.config/shell/aliases.sh` - traditional commands aliased to modern alternatives (cat->bat, ls->eza, grep->rg, find->fd, ps->procs, du->dust, df->duf, sed->sd, top->btop, http->xh, vi/vim->nvim)
- Important: SDKMAN init in `.config/shell/platform.sh` temporarily unaliases `find` to avoid conflicts, then restores it

## Git Commit Conventions

From `.config/git/message`, use emoji prefixes:
- `:tada:` - Initial commit
- `:bookmark:` - Version tag
- `:sparkles:` - New feature
- `:bug:` - Bug fix
- `:recycle:` - Refactoring
- `:books:` - Documentation (use `:memo:` for README changes)
- `:art:` - Design/UI/UX
- `:horse:` - Performance
- `:wrench:` - Tooling
- `:rotating_light:` - Tests
- `:hankey:` - Deprecation
- `:wastebasket:` - Removal
- `:construction:` - WIP

Note: The existing commit history uses `:memo:` for documentation, not `:books:`.

## Development Notes

**XDG Base Directory Compliance**
- Git, tmux (3.2+), mise, starship, gitmux all read from `$XDG_CONFIG_HOME` natively
- No symlinks needed to `$HOME` for these tools - they find config in `~/.config/` automatically
- `.editorconfig` remains in `$HOME` (XDG not supported)
- Shell modules are sourced via explicit paths in `.zshrc`

**Modular Setup Architecture**
- `init.sh` is a thin orchestrator that loads libraries and executes setup modules
- Each setup module (`scripts/setup/*.sh`) is idempotent and can be run independently
- Core utilities (`scripts/lib/core.sh`) provide logging, error handling, symlink management, and DRY_RUN support
- Platform detection (`scripts/lib/platform.sh`) handles macOS/Linux/WSL differences
- Validation script (`scripts/validate.sh`) checks setup completeness including XDG paths and shell modules
- `init.sh --dry-run` previews all changes without modifying the filesystem

**Symlink Management**
- `scripts/lib/core.sh` contains `safe_symlink()` function that backs up existing files with timestamp
- `scripts/setup/symlinks.sh` uses explicit file lists (not glob/find) for safety
- Symlinks root dotfiles to `$HOME` and `.config/` subdirectories to `$HOME/.config/`
- Automatically cleans up old pre-XDG symlinks (`~/.gitconfig`, `~/.tmux.conf`, etc.)

**Platform Detection**
- `scripts/lib/platform.sh` detects OS via `uname` and provides helper functions
- `.config/shell/platform.sh` sources platform-specific config based on OS type
- macOS is the primary platform; common functions are in shell modules (not `.zshrc.osx`)

**Shell Module Organization**
- All shell functionality extracted from `.zshrc` into `.config/shell/` modules
- `.zshrc` is a ~26-line loader that sources oh-my-zsh and all shell modules
- Each module is self-contained with its own functions and keybindings
- Module load order matters: `env.sh` first (PATH/tools), `platform.sh` last (SDKMAN needs aliases)

**Git Multi-Account Configuration**
- **Auto-generation**: `scripts/setup/git.sh` interactively creates Git configs on first run
- Uses `includeIf` to automatically switch user info and SSH keys based on directory path
- `.config/git/config` - Common settings + default INVALID user (accident prevention) + includes `.gitconfig.local`
- `.gitconfig.local` - Contains `includeIf` directives (NOT git-managed, auto-generated by setup script)
- `.gitconfig.personal` / `.gitconfig.work` - Account-specific configs (NOT git-managed, auto-generated by setup script)
- `.gitconfig.personal.example` / `.gitconfig.work.example` - Templates provided in repo (git-managed, for reference only)
- Directory structure: `~/repos/github.com/{username}/` uses personal config, `~/repos/github.com/{org}/` uses work config
- All repository remote URLs should use `git@github.com:` (not `git@github-personal:` or `git@github-work:`)
- SSH key switching happens via `core.sshCommand` in the includeIf configs
- Setup script checks for SSH keys and provides generation commands if missing
- **IMPORTANT**: Never commit personal information (names, emails, org names) to the dotfiles repo - only use templates with placeholders

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
