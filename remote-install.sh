#!/bin/sh

if [ ! -d "$HOME/.dotfiles" ]; then
  echo "Installing dotfiles"
  mkdir -p "$HOME/.dotfiles" && \
    curl -#L https://github.com/kusic/dotfiles/archive/master.zip | tar -xzv --directory ~/.dotfiles --strip-components=1
  source "$HOME/.dotfiles/install.sh"
else
  echo "The dotfiles are already installed."
fi
