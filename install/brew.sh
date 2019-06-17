#!/bin/sh

brew update
brew upgrade

brews=(
  git
  coreutils
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
  'yarn --without-node'
  python
  tmux
  reattach-to-user-namespace
  vim
  cmake
  ctags
  libidn
  pyenv
  pipenv
)

for brew in "${brews[@]}"
do
  brew install $brew
done

brew cleanup
