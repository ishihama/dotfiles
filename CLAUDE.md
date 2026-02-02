# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary), with Linux and WSL support. Manages shell, editor, terminal multiplexer, and development tool configurations with a focus on modern CLI tools and fzf-based workflows.

## Setup Commands

```bash
# Initial installation - modular setup with interactive Git configuration
./init.sh

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
- `init.sh` - Main orchestrator (thin wrapper that coordinates setup modules)
- `scripts/lib/core.sh` - Core utilities (logging, error handling, symlink management)
- `scripts/lib/platform.sh` - Platform detection (macOS/Linux/WSL)
- `scripts/setup/symlinks.sh` - Dotfile symlink management
- `scripts/setup/homebrew.sh` - Homebrew and package installation
- `scripts/setup/shell.sh` - oh-my-zsh and plugins
- `scripts/setup/git.sh` - **Interactive Git configuration with auto-generation**
- `scripts/setup/tools.sh` - Additional tools (delta, pokemon, TPM, mise)
- `scripts/validate.sh` - Post-setup validation

**Shell Configuration (Zsh)**
- `.zshrc` - Main config with oh-my-zsh, modern CLI tool aliases, fzf widgets (ghq-tmux, gwq-tmux, git-branch, file-search, process-kill), memo function, path setup (Go/Rust/Flutter/Android), mise, SDKMAN, zoxide, atuin, starship prompt
- `.config/shell/cheat.sh` - Cheatsheet function (fzf-based keybinding reference, extracted from .zshrc)
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
- `.tmux.conf` - Prefix is `C-t` (not default `C-b`), vim-style pane navigation (h/j/k/l), vim-style pane resize (H/J/K/L), `|` for vertical split, `-` for horizontal split, mouse enabled, clipboard integration via pbcopy, popup bindings: prefix+g (ghq-tmux), prefix+w (gwq-tmux), status bar shows CPU (C:) and RAM (M:) usage, Pokemon displayed on new session (pokemon-go-colorscripts -r -s, installed via `go install`)
- `.gitconfig` - Common settings, default user (INVALID/invalid@example.com for accident prevention), includes `.gitconfig.local`, commit template, delta pager, ghq root (`~/repos`)
- `.gitconfig.local` - includeIf directives for multi-account support (NOT git-managed, created per environment)
- `.gitconfig.personal.example` / `.gitconfig.work.example` - Templates for account-specific configs (git-managed templates, actual files are NOT git-managed)
- `.gitmessage` - Commit message template with emoji conventions
- `.mise.toml` - mise version manager config (replacement for asdf)
- `starship.toml` - Starship prompt configuration
- `.config/atuin/` - Atuin shell history sync config
- `.config/ghostty/` - Ghostty terminal emulator config (catppuccin theme, tmux integration keybindings: Cmd+T=prefix, Cmd+N=new window, Cmd+W=close pane, Cmd+1-9=window switch, Cmd+H/J/K/L=pane nav, Cmd+\=vsplit, Cmd+-=hsplit)
- `.config/gwq/config.toml` - gwq configuration (basedir: `~/repos`)

**Package Management**
- `Brewfile` - Homebrew packages (modern CLI tools: bat, eza, fd, ripgrep, procs, dust, duf, sd, btop, xh, zoxide, atuin, fzf, lazygit, delta, gh, ghq, gwq, mise, neovim, etc.), casks, Mac App Store apps

## Directory Structure

```
dotfiles/
├── init.sh                      # Main setup orchestrator
├── scripts/
│   ├── lib/
│   │   ├── core.sh             # Logging, error handling, utilities
│   │   └── platform.sh         # Platform detection
│   ├── setup/
│   │   ├── symlinks.sh         # Symlink management
│   │   ├── homebrew.sh         # Homebrew installation
│   │   ├── shell.sh            # Shell environment setup
│   │   ├── git.sh              # Git configuration (interactive)
│   │   └── tools.sh            # Additional tools
│   └── validate.sh             # Setup validation
├── .config/
│   ├── nvim/                   # Neovim configuration
│   ├── atuin/                  # Atuin shell history
│   ├── ghostty/                # Ghostty terminal
│   ├── gwq/                    # gwq worktree manager
│   ├── claude/                 # Claude Code settings
│   └── shell/
│       └── cheat.sh            # Cheatsheet function
├── .zshrc                      # Main zsh config (sources .config/shell/cheat.sh)
├── .zshrc.{osx,linux,wsl}     # Platform-specific configs
├── .tmux.conf                  # tmux configuration
├── .gitconfig                  # Git common settings
├── .gitconfig.{personal,work}.example  # Git account templates
├── .gitmessage                 # Git commit template
├── .mise.toml                  # mise version manager
├── starship.toml               # Starship prompt
└── Brewfile                    # Homebrew packages
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

**Modular Setup Architecture**
- `init.sh` is a thin orchestrator that loads libraries and executes setup modules
- Each setup module (`scripts/setup/*.sh`) is idempotent and can be run independently
- Core utilities (`scripts/lib/core.sh`) provide logging, error handling, and symlink management
- Platform detection (`scripts/lib/platform.sh`) handles macOS/Linux/WSL differences
- Validation script (`scripts/validate.sh`) checks setup completeness

**Symlink Management**
- `scripts/lib/core.sh` contains `safe_symlink()` function that backs up existing files with timestamp
- `scripts/setup/symlinks.sh` handles all dotfile symlinking
- Symlinks all dotfiles from repo to `$HOME`, plus `.config/` subdirectories (nvim, atuin, ghostty, claude, shell)

**Platform Detection**
- `scripts/lib/platform.sh` detects OS via `uname` and provides helper functions
- `.zshrc` sources platform-specific config based on OS type
- macOS is the primary platform; common functions are in `.zshrc` (not `.zshrc.osx`)

**Shell Function Modularity**
- Large shell functions are extracted to `.config/shell/` for better organization
- `cheat.sh` contains the fzf-based cheatsheet function (150+ lines)
- Functions are sourced in `.zshrc` to keep the main config lean

**Git Multi-Account Configuration**
- **Auto-generation**: `scripts/setup/git.sh` interactively creates Git configs on first run
- Uses `includeIf` to automatically switch user info and SSH keys based on directory path
- `.gitconfig` - Common settings + default INVALID user (accident prevention) + includes `.gitconfig.local`
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
