# This script is run in the shell environment
!/bin/sh

# The script sets the DOTFILES_DIR environment variable to the .dotfiles directory in the home directory
export DOTFILES_DIR="$HOME/.dotfiles"

# If the .dotfiles directory is a git repository, it pulls the latest changes from the master branch
[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# The script installs Homebrew, a package manager for macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# The script installs zsh, a shell, using Homebrew and sets it as the default shell
brew install zsh
chsh -s /opt/homebrew/bin/zsh

# The script sources (runs) other scripts to install additional Homebrew and brew-cask packages and tmux plugins
source "$DOTFILES_DIR/install/brew.sh"
source "$DOTFILES_DIR/install/brew-cask.sh"
source "$DOTFILES_DIR/install/tmux-plugin-manager.sh"

# The script creates symbolic links from various configuration files in the .dotfiles directory to the home directory
ln -sfv "$DOTFILES_DIR/.zshrc" ~
ln -sfv "$DOTFILES_DIR/.zprofile" ~
ln -sfv "$DOTFILES_DIR/.aliases.zsh" ~
ln -sfv "$DOTFILES_DIR/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.gitmessage" ~
ln -sfv "$DOTFILES_DIR/.gemrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
ln -sfv "$DOTFILES_DIR/.default-python-packages" ~
ln -sfv "$DOTFILES_DIR/tmux/resurrect" ~/.tmux/

# The script creates a .config directory in the home directory and creates symbolic links from various configuration files in the .dotfiles directory to the .config directory
mkdir ~/.config
ln -sfv ~/.dotfiles/config/nvim ~/.config/
ln -sfv ~/.dotfiles/config/wezterm ~/.config/
ln -sfv ~/.dotfiles/config/starship.toml ~/.config/

# The script sets up Node.js, Ruby, and Python using asdf, a version manager. It adds the necessary plugins, updates them, installs the latest versions of the languages, and sets those versions as the global versions
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
