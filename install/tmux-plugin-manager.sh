#!/bin/sh

# Install/update Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd -

tmux source-file ~/.tmux.conf
