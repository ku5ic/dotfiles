#!/bin/sh

brew update
brew upgrade

brews=(
  ansible
  bat
  cmake
  composer
  coreutils
  ctags
  dnsmasq
  fzf
  git
  grep
  httpd
  imagemagick
  mercurial
  ncurses
  neovim
  nvm
  openjdk
  openssl
  php@8.1
  pipenv
  postgresql@14
  pyenv
  python@3.11
  rbenv
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
