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
ln -sfv "$DOTFILES_DIR/.keymappings.vim" ~
ln -sfv "$DOTFILES_DIR/.vimrc" ~
ln -sfv "$DOTFILES_DIR/.gvimrc" ~
ln -sfv "$DOTFILES_DIR/.plugins.vim" ~
rm -rf ~/Library/Application\ Support/Code/User
ln -sfv "$DOTFILES_DIR/Code/User" ~/Library/Application\ Support/Code
ln -sfv "$DOTFILES_DIR/coc-settings.json" ~/.vim/coc-settings.json

# Install vscode plugins
source "$DOTFILES_DIR/install/vscode.sh"

# Additional completion definitions for Zsh
autoload -U compinit && compinit

# install lts version of node
nvm install --lts

# install vim CoC plugins
vim -c 'CocInstall -sync coc-prettier coc-highlight coc-spell-checker coc-json coc-html coc-eslint coc-css coc-python coc-solargraph coc-tsserver coc-yaml|q'

# Globally install with npm
# npm install -g bower
# npm install -g grunt
# npm install -g gulp
# npm install -g http-server
# npm install -g nodemon
