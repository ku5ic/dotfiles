#!/bin/sh

casks=(
  1password
  battery-guardian
  chromedriver
  firefox
  font-open-sans
  java
  ngrok
  postman
  spotify
  timemachineeditor
  vagrant
  abstract
  beekeeper-studio
  coconutbattery
  font-hack-nerd-font
  google-chrome
  macs-fan-control
  onyx
  sketch
  sublime-text
  transmission
  virtualbox
  authy
  caffeine
  diffmerge
  font-input
  iterm2
  macvim
  phantomjs
  slack
  the-unarchiver
  upwork
  vlc
)

for cask in "${casks[@]}"
do
  brew install $cask
done
