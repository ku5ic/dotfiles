#!/bin/sh

casks=(
  abstract
  diffmerge
  iterm2
  onyx
  transmission
  battery-guardian
  etcher
  java
  postman
  upwork
  firefox
  kindle
  send-to-kindle
  virtualbox
  chromedriver
  font-meslo-nerd-font
  macs-fan-control
  sketch
  visual-studio-code
  coconutbattery
  font-open-sans
  macvim
  slack
  vlc
  db-browser-for-sqlite
  google-chrome
  ngrok
  timemachineeditor
)

for cask in "${casks[@]}"
do
  brew cask install $cask
done
