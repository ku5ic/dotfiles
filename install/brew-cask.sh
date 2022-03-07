#!/bin/sh

casks=(
  1password
  abstract
  authy
  battery-guardian
  beekeeper-studio
  chromedriver
  coconutbattery
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
  phantomjs
  postman
  sketch
  slack
  spotify
  the-unarchiver
  timemachineeditor
  transmission
  upwork
  vagrant
  virtualbox
  vlc
)

for cask in "${casks[@]}"
do
  brew install $cask
done
