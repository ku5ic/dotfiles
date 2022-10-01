#!/bin/sh

casks=(
  1password
  authy
  beekeeper-studio
  chromedriver
  diffmerge
  firefox
  font-hack-nerd-font
  font-input
  font-open-sans
  google-chrome
  iterm2
  java
  macs-fan-control
  ngrok
  onyx
  postman
  slack
  spotify
  the-unarchiver
  transmission
  visual-studio-code
)

for cask in "${casks[@]}"
do
  brew install $cask
done
