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

install_packages() {
  brew bundle --file="$DOTFILES_DIR/Brewfile"
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
  ln -sfv "$DOTFILES_DIR/.pylintrc" ~
  ln -sfv "$DOTFILES_DIR/.default-python-packages" ~
  ln -sfv "$DOTFILES_DIR/.default-npm-packages" ~
  ln -sfv "$DOTFILES_DIR/.default-gems" ~
  ln -sfv "$DOTFILES_DIR/.tool-versions" ~
  ln -sfv "$DOTFILES_DIR/tmux/resurrect" ~/.tmux/
  ln -sfv "$DOTFILES_DIR/.tmuxinator" ~

  mkdir -p ~/.config
  ln -sfv "$DOTFILES_DIR/config/nvim" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/wezterm" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/starship.toml" ~/.config/
}

setup_asdf() {
  local tool_versions="$DOTFILES_DIR/.tool-versions"

  if [ ! -f "$tool_versions" ]; then
    echo "Missing .tool-versions at $tool_versions"
    exit 1
  fi

  # Register plugins, tolerating already-added state
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git || true
  asdf plugin add python || true

  # Update all plugins
  asdf plugin update --all

  # Install each version declared in .tool-versions
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip blank lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue

    local plugin version
    plugin=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    echo "Installing $plugin $version"
    asdf install "$plugin" "$version"
  done < "$tool_versions"
}

main() {
  update_dotfiles
  install_homebrew
  install_shells
  install_packages
  create_symlinks
  setup_asdf
}

main "$@"
