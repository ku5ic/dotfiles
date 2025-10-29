#!/bin/sh

# An array of applications to be installed
casks=(
  1password
  1password-cli
  adguard
  boop
  chatgpt
  claude
  cleanshot
  dbeaver-community
  figma
  firefox
  fliqlo
  font-fira-code-nerd-font
  google-chrome
  onyx
  postman
  slack
  spotify
  stremio
  the-unarchiver
  transmission
  vimr
  visual-studio-code
  vlc
  webstorm
  wezterm
  zoom
)

# Loop over the array of applications
for cask in "${casks[@]}"
do
  # Use Homebrew to install each application
  brew install $cask
done
