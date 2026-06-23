#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"

# Stage tracking so a mid-run failure tells you exactly where it died,
# instead of leaving you to reverse-engineer it from a wall of output.
CURRENT_STAGE="startup"
on_error() {
  local exit_code=$?
  echo "" >&2
  echo "install.sh: FAILED during stage '${CURRENT_STAGE}' (exit ${exit_code})" >&2
  echo "install.sh: stages after this one did not run." >&2
  exit "$exit_code"
}
trap on_error ERR

update_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin main
  fi
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # The Homebrew installer writes the shellenv line to ~/.zprofile, but that
  # file is not sourced mid-script, so /opt/homebrew/bin is not on PATH yet.
  # Evaluate it here so every later stage can call brew, asdf, mas, etc.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo "install.sh: brew is still not on PATH after install; cannot continue." >&2
    return 1
  fi
}

install_shells() {
  brew install zsh bash

  local brew_prefix
  brew_prefix="$(brew --prefix)"

  # Append to /etc/shells only if not already present, to keep re-runs clean.
  grep -qxF "$brew_prefix/bin/zsh" /private/etc/shells ||
    echo "$brew_prefix/bin/zsh" | sudo tee -a /private/etc/shells >/dev/null
  grep -qxF "$brew_prefix/bin/bash" /private/etc/shells ||
    echo "$brew_prefix/bin/bash" | sudo tee -a /private/etc/shells >/dev/null

  chsh -s "$brew_prefix/bin/zsh"
}

install_packages() {
  # mas (App Store) entries can fail when the signed-in Apple ID does not own
  # the app, or when an ADAM ID has been pulled from the store. Those failures
  # must NOT abort the bootstrap and leave dotfiles unlinked, so brew bundle is
  # explicitly non-fatal here. Formula/cask failures are surfaced but also do
  # not halt the run; inspect the output if something core is missing.
  if ! brew bundle --file="$DOTFILES_DIR/Brewfile"; then
    echo "install.sh: WARN: brew bundle reported failures." >&2
    echo "install.sh: WARN: this is usually mas/App Store apps not owned by the" >&2
    echo "install.sh: WARN: current Apple ID, or a pulled ADAM ID. Continuing so" >&2
    echo "install.sh: WARN: symlinks and the rest of bootstrap still run." >&2
  fi
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
  ln -sfv "$DOTFILES_DIR/.default-npm-packages" ~
  ln -sfv "$DOTFILES_DIR/.default-gems" ~
  ln -sfv "$DOTFILES_DIR/.tool-versions" ~
  ln -sfv "$DOTFILES_DIR/.tmuxinator" ~
  ln -sfv "$DOTFILES_DIR/.editorconfig" ~

  bash "$DOTFILES_DIR/claude/bin/bootstrap.sh" --non-interactive

  mkdir -p ~/.config
  ln -sfv "$DOTFILES_DIR/config/nvim" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/wezterm" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/starship.toml" ~/.config/
  ln -sfv "$DOTFILES_DIR/config/git" ~/.config/

  mkdir -p "$HOME/Library/Application Support/upterm"
  ln -sfv "$DOTFILES_DIR/config/upterm/config.yaml" "$HOME/Library/Application Support/upterm/config.yaml"
}

install_launchd_agents() {
  mkdir -p "$HOME/Library/LaunchAgents"
  local brew_bash
  brew_bash="$(brew --prefix)/bin/bash"
  for template in "$DOTFILES_DIR/launchd/"*.plist; do
    [ -f "$template" ] || continue
    local dest
    dest="$HOME/Library/LaunchAgents/$(basename "$template")"
    sed -e "s|__HOME__|$HOME|g" -e "s|__BREW_BASH__|$brew_bash|g" "$template" >"$dest"
    echo "launchd: wrote $dest"
    echo "launchd: to load: launchctl load $dest"
  done
}

fix_permissions() {
  find "$DOTFILES_DIR/scripts" \
    "$DOTFILES_DIR/completions/" \
    "$DOTFILES_DIR/claude/bin" \
    "$DOTFILES_DIR/claude/hooks" \
    "$DOTFILES_DIR/macos" \
    -type f -name '*.sh' -exec chmod +x {} +
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
  done <"$tool_versions"
}

main() {
  CURRENT_STAGE="update_dotfiles"
  update_dotfiles
  CURRENT_STAGE="install_homebrew"
  install_homebrew
  CURRENT_STAGE="install_shells"
  install_shells
  CURRENT_STAGE="install_packages"
  install_packages
  CURRENT_STAGE="fix_permissions"
  fix_permissions
  CURRENT_STAGE="create_symlinks"
  create_symlinks
  CURRENT_STAGE="install_launchd_agents"
  install_launchd_agents
  CURRENT_STAGE="setup_asdf"
  setup_asdf

  echo ""
  echo "install.sh: completed."
}

main "$@"
