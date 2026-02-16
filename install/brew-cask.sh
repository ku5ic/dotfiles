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
  neovide-app
  onyx
  postman
  slack
  spotify
  the-unarchiver
  transmission
  visual-studio-code
  vlc
  wezterm
  zoom
)

# Loop over the array of applications
for cask in "${casks[@]}"
do
  # Use Homebrew to install each application
  brew install $cask
done
