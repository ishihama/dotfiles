# dotfiles

Personal dotfiles for macOS, Linux, and WSL.

## Setup

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/dotfiles.git ~/repos/personal/dotfiles
cd ~/repos/personal/dotfiles

# 2. Run init script (symlinks dotfiles, installs oh-my-zsh, Homebrew, packages, dein)
./init.sh

# 3. Install/update Homebrew packages
brew bundle

# 4. Install gh extensions
gh extension install benelan/gh-fzf

# 5. Reload shell
source ~/.zshrc
```

## Keybindings

| Key | Description |
|-----|-------------|
| `Ctrl+R` | fzf history search |
| `Ctrl+G` | ghq + fzf + tmux (repository selector) |

## ghq + fzf + tmux Workflow

`Ctrl+G` opens a repository selector that creates/attaches tmux sessions.

### First Time Setup

```bash
# Get a repository with ghq
ghq get https://github.com/cli/cli

# Press Ctrl+G, select the repo, and you're in a tmux session!
```

### Daily Usage

1. Press `Ctrl+G`
2. Select a repository with fzf
3. Automatically creates a tmux session named after the repo (or attaches if it exists)

### Behavior

| Context | Action |
|---------|--------|
| Outside tmux | Creates new session or attaches to existing |
| Inside tmux | Creates new session or switches to existing |
| Cancel fzf | Does nothing |

Session names are derived from the repository basename (`.` replaced with `-`).

## gh-fzf: GitHub CLI with Fuzzy Finder

Wraps `gh` commands with fzf for fast PR/Issue/Actions navigation.

```bash
gh fzf pr          # Browse PRs with fzf, checkout/merge/view
gh fzf issue       # Browse Issues with fzf
gh fzf run         # Browse GitHub Actions runs
gh fzf release     # Browse releases
```

## gwq: Git Worktree Manager

Manage multiple worktrees for parallel development (great for running multiple Claude Code instances).

```bash
gwq add -b feature/login   # Create worktree with new branch
gwq list                    # List all worktrees
gwq status                  # Check status of all worktrees
cd $(gwq get login)         # Jump to a worktree
gwq remove feature/old      # Remove a worktree
```

## Modern CLI Tools

Traditional commands are aliased to modern alternatives with better UX.

### File Operations

| Alias | Tool | Replaces | Features |
|-------|------|----------|----------|
| `ls` | eza | ls | Icons, colors, Git integration |
| `ll` | eza -la | ls -la | Long format with Git status |
| `la` | eza -a | ls -a | Show hidden files |
| `lt` | eza --tree | tree | Tree view with icons |
| `cat` | bat | cat | Syntax highlighting, line numbers |
| `find` | fd | find | Intuitive syntax, fast, respects .gitignore |
| `grep` | ripgrep (rg) | grep | Ultra fast, .gitignore aware |

```bash
# eza examples
ll                      # List with Git status (M=modified, N=new)
lt -L 2                 # Tree view, 2 levels deep

# bat examples
bat README.md           # Syntax highlighted view
bat -l json data.txt    # Force JSON highlighting
bat --diff file.txt     # Show git diff

# fd examples
fd pattern              # Find files matching pattern
fd -e js                # Find all .js files
fd -H pattern           # Include hidden files

# ripgrep examples
rg "TODO"               # Search for TODO in current dir
rg -i "error" -g "*.log"  # Case insensitive, only .log files
rg -C 3 "function"      # Show 3 lines of context
```

### System Monitoring

| Alias | Tool | Replaces | Features |
|-------|------|----------|----------|
| `ps` | procs | ps | Colorful, tree view, watch mode |
| `top` | btop | top/htop | Beautiful resource monitor |
| `du` | dust | du | Intuitive disk usage visualization |
| `df` | duf | df | Colorful disk free space |

```bash
# procs examples
ps                      # Process list with colors
procs --tree            # Process tree view
procs --watch           # Auto-refresh mode
procs zsh               # Filter by name

# dust examples
dust                    # Disk usage of current dir
dust -d 2               # Limit depth to 2
dust -r                 # Reverse order (largest last)

# duf examples
duf                     # All mounted filesystems
duf /home               # Specific path only
```

### Text Processing

| Alias | Tool | Replaces | Features |
|-------|------|----------|----------|
| `sed` | sd | sed | Intuitive syntax, no escaping hell |
| `http` | xh | curl/httpie | Colorful output, easy syntax |

```bash
# sd examples
sd 'before' 'after' file.txt       # Replace in file
sd -F 'exact.match' 'new' file     # Literal string (no regex)
echo "hello" | sd 'ell' 'ipp'      # Pipe usage

# xh examples
xh httpbin.org/get                 # GET request
xh POST api.example.com data=value # POST with JSON
xh -d https://example.com/file     # Download file
```

### Navigation & History

| Tool | Replaces | Features |
|------|----------|----------|
| zoxide | cd | Learns your habits, `z foo` jumps to ~/projects/foo |
| atuin | history | SQLite-backed, sync across machines, fuzzy search |
| fzf | - | Fuzzy finder for everything |

```bash
# zoxide examples
z dotfiles              # Jump to most frecent match for "dotfiles"
z foo bar               # Jump to path matching "foo" and "bar"
zi                      # Interactive selection with fzf

# atuin examples
# Ctrl+R triggers atuin search (configured via atuin init)
atuin search "git"      # Search history for "git"
atuin stats             # Show shell usage statistics

# fzf examples
vim $(fzf)              # Open file selected with fzf
kill -9 $(ps aux | fzf | awk '{print $2}')  # Kill process with fzf
```

### Git Tools

| Tool | Purpose | Features |
|------|---------|----------|
| lazygit | Git TUI | Stage, commit, rebase, merge with keyboard |
| delta | Git diff | Syntax highlighting, line numbers, side-by-side |
| gh | GitHub CLI | PR, Issue, Actions from terminal |
| gh-fzf | gh + fzf | Fuzzy find PRs, Issues, runs |
| ghq | Repo manager | Organize repos under ~/repos |
| gwq | Worktree manager | Parallel branch development |

```bash
# lazygit
lazygit                 # Open TUI in current repo

# delta (auto-used by git diff via .gitconfig)
git diff                # Beautiful diff with syntax highlighting

# gh examples
gh pr create            # Create PR
gh pr checkout 123      # Checkout PR #123
gh issue list           # List issues

# gh-fzf examples
gh fzf pr               # Fuzzy find and act on PRs
gh fzf issue            # Fuzzy find issues
gh fzf run              # Fuzzy find Actions runs

# ghq examples
ghq get cli/cli         # Clone github.com/cli/cli to ~/repos/github.com/cli/cli
ghq list                # List all repos
ghq root                # Show root directory

# gwq examples
gwq add -b feature/x    # Create worktree for new branch
gwq list                # List all worktrees
gwq status              # Git status of all worktrees
```

### Tips

**Combine tools for power workflows:**

```bash
# Find and edit files
vim $(fd -e ts | fzf)

# Search and open results
rg -l "TODO" | fzf | xargs vim

# Git log with fzf
git log --oneline | fzf --preview 'git show {1}'

# Kill process interactively
procs | fzf | awk '{print $1}' | xargs kill
```

## Structure

```
.zshrc          # Main shell config
.zshrc.osx      # macOS-specific (fzf, ghq-tmux, iTerm2)
.zshrc.linux    # Linux-specific
.zshrc.wsl      # WSL-specific
.vimrc          # Vim config
.tmux.conf      # tmux config (prefix: Ctrl+T)
.gitconfig      # Git config
Brewfile        # Homebrew packages
```
