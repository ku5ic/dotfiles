#!/bin/sh

casks=(
  1password
  chromedriver
  firefox
  google-chrome
  postman
  vimr
  authy
  diffmerge
  font-hack-nerd-font
  iterm2
  spotify
  viscosity
  beekeeper-studio
  docker
  font-input
  onyx
  the-unarchiver
  visual-studio-code
)

for cask in "${casks[@]}"
do
  brew install $cask
done
