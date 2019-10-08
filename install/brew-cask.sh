#!/bin/sh

casks=(
  1password
  deezer
  firefox
  google-chrome
  kindle
  ngrok
  react-native-debugger
  slack
  upwork
  visual-studio-code
  abstract
  chromedriver
  diffmerge
  font-meslo-nerd-font
  iterm2
  macs-fan-control
  onyx
  send-to-kindle
  timemachineeditor
  vagrant
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
)

for cask in "${casks[@]}"
do
  brew cask install $cask
done
