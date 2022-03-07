#!/bin/sh

brew update
brew upgrade

brews=(
  ansible
  bat
  cmake
  ctags
  fzf
  git
  grep
  imagemagick
  libidn
  mysql
  nvm
  openssl
  pipenv
  postgresql
  puma/puma/puma-dev
  pyenv
  python
  rbenv
  rbenv-gemset
  reattach-to-user-namespace
  redis
  ripgrep
  ruby
  ruby-build
  sqlite
  ssh-copy-id
  tmux
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
