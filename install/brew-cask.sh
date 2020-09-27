#!/bin/sh

casks=(
  1password
  deezer
  firefox
  google-chrome
  ngrok
  slack
  upwork
  visual-studio-code
  abstract
  chromedriver
  diffmerge
  font-input
  iterm2
  macs-fan-control
  onyx
  timemachineeditor
  vlc
  battery-guardian
  coconutbattery
  etcher
  font-open-sans
  java
  macvim
  postman
  sketch
  transmission
  virtualbox
  beekeeper-studio
)

for cask in "${casks[@]}"
do
  brew cask install $cask
done
