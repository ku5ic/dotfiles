#!/bin/sh

casks=(
  1password
  authy
  beekeeper-studio
  chromedriver
  diffmerge
  docker
  firefox
  google-chrome
  iterm2
  onyx
  postman
  spotify
  the-unarchiver
  viscosity
  visual-studio-code
  font-fira-code-nerd-font
)

for cask in "${casks[@]}"
do
  brew install $cask
done
