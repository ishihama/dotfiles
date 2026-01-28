#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Setup ==="
echo "Source: $DOTFILES_DIR"
echo ""

# ------------------------------
# Helper functions
# ------------------------------
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    echo "[skip] Already symlinked: $dest"
  elif [ -d "$dest" ]; then
    echo "[backup] Directory exists, backing up: $dest"
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    ln -s "$src" "$dest"
    echo "[link] Created: $dest -> $src"
  elif [ -e "$dest" ]; then
    echo "[backup] File exists, backing up: $dest"
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    ln -s "$src" "$dest"
    echo "[link] Created: $dest -> $src"
  else
    ln -s "$src" "$dest"
    echo "[link] Created: $dest -> $src"
  fi
}

# ------------------------------
# Symlink dotfiles
# ------------------------------
echo "--- Symlinking dotfiles ---"

# Hidden files (excluding .git*)
find "$DOTFILES_DIR" -maxdepth 1 -name ".*" -type f ! -name ".git*" -print0 | while IFS= read -r -d '' file; do
  filename=$(basename "$file")
  link_file "$file" "$HOME/$filename"
done

# .vim directory
link_file "$DOTFILES_DIR/.vim" "$HOME/.vim"

# .config directory
mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
if [ -d "$DOTFILES_DIR/.config/atuin" ]; then
  link_file "$DOTFILES_DIR/.config/atuin" "$HOME/.config/atuin"
fi
if [ -d "$DOTFILES_DIR/.config/ghostty" ]; then
  link_file "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
fi

# Claude Code settings
if [ -d "$DOTFILES_DIR/.config/claude" ]; then
  mkdir -p "$HOME/.claude"
  link_file "$DOTFILES_DIR/.config/claude/settings.json" "$HOME/.claude/settings.json"
fi

echo ""

# ------------------------------
# Homebrew
# ------------------------------
echo "--- Homebrew ---"

if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for this session
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed"
fi

echo "Running brew bundle..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo ""

# ------------------------------
# oh-my-zsh
# ------------------------------
echo "--- oh-my-zsh ---"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "oh-my-zsh already installed"
fi

# zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo ""

# ------------------------------
# Vim (dein)
# ------------------------------
echo "--- Vim (dein) ---"

if [ ! -d "$HOME/.cache/dein" ]; then
  echo "Installing dein..."
  curl -fsSL https://raw.githubusercontent.com/Shougo/dein-installer.vim/master/installer.sh | sh -s -- ~/.cache/dein
else
  echo "dein already installed"
fi

echo ""

# ------------------------------
# mise
# ------------------------------
echo "--- mise ---"

if command -v mise &> /dev/null; then
  echo "Setting up mise..."
  cd "$DOTFILES_DIR"
  mise trust --all
  mise install
  cd - > /dev/null
else
  echo "[warn] mise not found. Run 'brew bundle' first."
fi

echo ""

# ------------------------------
# Done
# ------------------------------
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Run 'mise install' in your project directories"
echo ""
