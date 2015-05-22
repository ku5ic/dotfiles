#!/bin/sh

brew update
brew upgrade --all

brew install coreutils
brew install ssh-copy-id
brew install wget
brew install imagemagick

brew install git
brew install imagemagick

# mysql
brew install mysql
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

brew install ngrok
brew install node
brew install phantomjs
brew install phpmyadmin

# postgresql
brew install postgresql92
initdb /usr/local/var/postgres -E utf8    # create a database
ln -sfv /usr/local/opt/postgresql92/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql92.plist

# rbenv
brew install rbenv
brew install rbenv-gemset
brew install ruby-build
brew install tmux
brew install tree
brew install vim
