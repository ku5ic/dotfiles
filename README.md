# My dotfiles

These are my dotfiles. Take anything you want, but at your own risk.

It targets OS X systems

## Install

On a sparkling fresh installation of OS X:

    sudo softwareupdate -i -a
    xcode-select --install

Install the dotfiles with either Git or curl:

### Clone with Git

    git clone git@github.com:kusic/dotfiles.git
    source dotfiles/install.sh

### Remotely install using curl

Alternatively, you can install this into `~/.dotfiles` from remote without Git using curl:

    sh -c "`curl -fsSL https://raw.github.com/kusic/dotfiles/master/remote-install.sh`"
