#!/bin/sh

set -e

DOTFILES_DIR="$HOME/.dotfiles"

update_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master
  fi
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_shells() {
  brew install zsh bash

  echo "$(brew --prefix)/bin/zsh" | sudo tee -a /private/etc/shells
  echo "$(brew --prefix)/bin/bash" | sudo tee -a /private/etc/shells

  chsh -s "$(brew --prefix)/bin/zsh"
}

source_scripts() {
  source "$DOTFILES_DIR/install/brew.sh"
  source "$DOTFILES_DIR/install/brew-cask.sh"
}

create_symlinks() {
  ln -sfv "$DOTFILES_DIR/.zshrc" ~
  ln -sfv "$DOTFILES_DIR/.zprofile" ~
  ln -sfv "$DOTFILES_DIR/.aliases.zsh" ~
  ln -sfv "$DOTFILES_DIR/.gitconfig" ~
  ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
  ln -sfv "$DOTFILES_DIR/.gitmessage" ~
  ln -sfv "$DOTFILES_DIR/.gemrc" ~
  ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
  ln -sfv "$DOTFILES_DIR/.default-python-packages" ~
  ln -sfv "$DOTFILES_DIR/tmux/resurrect" ~/.tmux/

  mkdir -p ~/.config
  ln -sfv "$DOTFILES_DIR/config/nvim" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/wezterm" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/starship.toml" ~/.config/
}

setup_asdf() {
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
  asdf nodejs update-nodebuild
  asdf install nodejs latest:18
  asdf global nodejs latest:18

  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git || true
  asdf plugin-update ruby
  asdf install ruby latest:3
  asdf global ruby latest:3

  asdf plugin add python || true
  asdf plugin-update python
  asdf install python latest:3
  asdf global python latest:3
}

main() {
  update_dotfiles
  install_homebrew
  install_shells
  source_scripts
  create_symlinks
  setup_asdf
}

main "$@"
