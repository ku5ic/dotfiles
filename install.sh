#!/bin/sh

# Get current dir (so run this script from anywhere)

export DOTFILES_DIR="/Users/ku5ic/.dotfiles"

# Update dotfiles itself first

[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# Install Homebrew & brew-cask
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install brew-cask
brew tap homebrew/cask-fonts

# Install zsh
brew install zsh

grep "/usr/local/bin/zsh" /private/etc/shells &>/dev/null || sudo bash -c "echo /usr/local/bin/zsh >> /private/etc/shells"
chsh -s /usr/local/bin/zsh

# Install brew & brew-cask packages
source "$DOTFILES_DIR/install/brew.sh"
source "$DOTFILES_DIR/install/brew-cask.sh"
source "$DOTFILES_DIR/install/tmux-plugin-manager.sh"
source "$DOTFILES_DIR/install/plug.sh"

# Bunch of symlinks
ln -sfv "$DOTFILES_DIR/.zshrc" ~
ln -sfv "$DOTFILES_DIR/.zprofile" ~
ln -sfv "$DOTFILES_DIR/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.gitmessage" ~
ln -sfv "$DOTFILES_DIR/.gemrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~

mkdir -p ~/.config/nvim

ln -sfv "$DOTFILES_DIR/config/init.vimrc" '~/.config/nvim/init.vim'
ln -sfv "$DOTFILES_DIR/keymappings.vim" '~/.config/nvim/keymappings.vim'
ln -sfv "$DOTFILES_DIR/plugins.vim" '~/.config/nvim/plugins.vim'

# install lts version of node
nvm install --lts
