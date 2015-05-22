#!/bin/sh

TMUX_PLUGIN_DIR=~/.tmux/plugins

# Install/update Tmux Plugin Manager
mkdir -p "$TMUX_PLUGIN_DIR" && (git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm" || (cd "$TMUX_PLUGIN_DIR/tmp" && git pull origin master))

cd -

tmux source-file ~/.tmux.conf
