#!/bin/sh

# This line clones the Tmux Plugin Manager repository from GitHub into the ~/.tmux/plugins/tpm directory on your local machine.
# If the directory already exists, git clone will fail and no action will be taken.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# This line changes the current directory back to the directory you were in before you ran the script.
cd -

# This line sources the Tmux configuration file. This means it loads the configuration file into the current shell session.
# This is done to apply any new changes that the installation or update of the Tmux Plugin Manager might have made to the configuration file.
tmux source-file ~/.tmux.conf
