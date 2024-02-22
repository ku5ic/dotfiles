!/bin/sh

# Get current dir (so run this script from anywhere)

export DOTFILES_DIR="$HOME/.dotfiles"

# Update dotfiles itself first

[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# Install Homebrew & brew-cask
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap homebrew/cask-fonts

# Install zsh
brew install zsh

chsh -s /opt/homebrew/bin/zsh

# Install brew & brew-cask packages
source "$DOTFILES_DIR/install/brew.sh"
source "$DOTFILES_DIR/install/brew-cask.sh"
source "$DOTFILES_DIR/install/tmux-plugin-manager.sh"

# Bunch of symlinks
ln -sfv "$DOTFILES_DIR/.zshrc" ~
ln -sfv "$DOTFILES_DIR/.zprofile" ~
ln -sfv "$DOTFILES_DIR/.aliases.zsh" ~
ln -sfv "$DOTFILES_DIR/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.gitmessage" ~
ln -sfv "$DOTFILES_DIR/.gemrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
ln -sfv "$DOTFILES_DIR/.default-python-packages" ~

mkdir ~/.config

ln -sfv ~/.dotfiles/config/nvim ~/.config/
ln -sfv ~/.dotfiles/config/wezterm ~/.config/
ln -sfv ~/.dotfiles/config/starship.toml ~/.config/

# setup node
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf nodejs update-nodebuild
asdf install nodejs latest:18
asdf global nodejs latest:18

# setup ruby
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-update ruby
asdf install ruby latest:3
asdf global ruby latest:3

# setup python
asdf plugin add python
asdf plugin-update python
asdf install python latest:3
asdf global python latest:3
