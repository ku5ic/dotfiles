#!/bin/sh

casks=(
  1password
  authy
  beekeeper-studio
  chromedriver
  diffmerge
  docker
  firefox
  font-hack-nerd-font
  font-input
  google-chrome
  iterm2
  neovide
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
