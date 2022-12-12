#!/bin/sh

brew update
brew upgrade

brews=(
  ansible
  bat # for fzf
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
  neovim
  node
  nvm
  openjdk
  openssl@3
  php
  pipenv
  postgresql@14
  pyenv
  rbenv
  reattach-to-user-namespace
  redis
  ripgrep #for fzf
  ssh-copy-id
  tig
  tmuxinator
  tree
  wget
  yarn
  zplug
  zsh
  zsh-completions
)

for brew in "${brews[@]}"
do
  brew install $brew
done

brew cleanup
