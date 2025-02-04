#!/bin/sh

# Update Homebrew to the latest version
brew update

# Upgrade all installed packages to their latest versions
brew upgrade

# Declare an array of package names to be installed
brews=(
  asdf
  bat
  cmake
  composer
  coreutils
  ctags
  fastfetch
  fzf
  git
  gnu-sed
  grep
  httpd
  imagemagick
  jesseduffield/lazygit/lazygit
  lua
  luarocks
  ncurses
  neovim
  openjdk
  openssl
  php@8.1
  postgresql@14
  reattach-to-user-namespace
  redis
  ripgrep
  ssh-copy-id
  starship
  tig
  tmuxinator
  tpm
  tree
  wget
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

# Loop through the array and install each package
for brew in "${brews[@]}"
do
  brew install $brew
done

# Clean up any outdated versions of installed packages
brew cleanup
