#!/bin/sh

casks=(
  1password
  deezer
  firefox
  google-chrome
  ngrok
  slack
  upwork
  abstract
  chromedriver
  diffmerge
  font-input
  iterm2
  macs-fan-control
  onyx
  timemachineeditor
  battery-guardian
  coconutbattery
  etcher
  font-open-sans
  java
  macvim
  sketch
  transmission
  virtualbox
  beekeeper-studio
)

for cask in "${casks[@]}"
do
  brew install $cask
done
