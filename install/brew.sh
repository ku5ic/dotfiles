#!/bin/sh

brew update
brew upgrade

brews=(
  asdf
  bat
  cmake
  composer
  coreutils
  ctags
  fzf
  git
  gnu-sed
  grep
  httpd
  imagemagick
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
  tree
  wget
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

for brew in "${brews[@]}"
do
  brew install $brew
done

brew cleanup
