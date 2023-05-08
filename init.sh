#!/bin/bash

# ln -s dotfiles to $HOME
for i in $(find . -name ".*" -not -name ".git" -not -name "." -maxdepth 1); do
  ln -s $(cd $(dirname $i) && pwd)/$i ~/$i
done

# oh-my-zsh
curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh

# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew bundle

# dein
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Shougo/dein-installer.vim/master/installer.sh)"


