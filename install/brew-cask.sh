#!/bin/sh

casks=(
  1password
  1password-cli
  authy
  chromedriver
  dbeaver-community
  diffmerge
  docker
  firefox
  font-fira-code-nerd-font
  google-chrome
  onyx
  postman
  spotify
  the-unarchiver
  viscosity
  visual-studio-code
)

for cask in "${casks[@]}"
do
  brew install $cask
done
