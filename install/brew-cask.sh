#!/bin/sh

# An array of applications to be installed
casks=(
  1password
  1password-cli
  authy
  boop
  cleanshot
  dbeaver-community
  docker
  firefox
  font-fira-code-nerd-font
  google-chrome
  onyx
  postman
  spotify
  the-unarchiver
  visual-studio-code
)

# Loop over the array of applications
for cask in "${casks[@]}"
do
  # Use Homebrew to install each application
  brew install $cask
done
