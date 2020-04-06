#!/bin/sh

brew update
brew upgrade

brews=(
  git
  openssl
  ssh-copy-id
  wget
  tree
  imagemagick
  postgresql
  mysql
  redis
  sqlite
  puma/puma/puma-dev
  rbenv
  ruby
  rbenv-gemset
  ruby-build
  nvm
  yarn
  python
  tmux
  reattach-to-user-namespace
  vim
  cmake
  ctags
  libidn
  pyenv
  pipenv
  zplug
  zsh
  zsh-completions
  ansible
  timuxinator
)

for brew in "${brews[@]}"
do
  brew install $brew
done

brew cleanup
