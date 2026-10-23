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

  [[ "$SHELL" == "$brew_prefix/bin/zsh" ]] || chsh -s "$brew_prefix/bin/zsh"
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
  # home/ holds files without the leading dot so editors show them: home/zshrc -> ~/.zshrc
  local src
  for src in "$DOTFILES_DIR"/home/*; do
    ln -sfnv "$src" "$HOME/.${src##*/}"
  done

  mkdir -p ~/.config
  for src in "$DOTFILES_DIR"/config/*; do
    # upterm reads its config from Application Support, linked below.
    [[ ${src##*/} == upterm ]] && continue
    ln -sfnv "$src" ~/.config/"${src##*/}"
  done

  mkdir -p "$HOME/Library/Application Support/upterm"
  ln -sfv "$DOTFILES_DIR/config/upterm/config.yaml" "$HOME/Library/Application Support/upterm/config.yaml"
}

# Personal Claude config is linked from claude/; claude-kit itself is a plugin
# from ku5ic/claude-kit, whose marketplace clone also supplies the rules and
# the bin/ scripts on PATH.
setup_claude() {
  mkdir -p ~/.claude
  local entry
  for entry in settings.json CLAUDE.md rules skills claude-kit.local.yml; do
    ln -sfnv "$DOTFILES_DIR/claude/$entry" ~/.claude/"$entry"
  done

  if ! command -v claude >/dev/null 2>&1; then
    echo "install.sh: WARN: claude CLI not found; re-run install.sh after installing Claude Code" >&2
    return
  fi
  [[ -d ~/.claude/plugins/marketplaces/ku5ic ]] || claude plugin marketplace add ku5ic/claude-kit
  claude plugin details kit >/dev/null 2>&1 || claude plugin install kit@ku5ic
  ~/.claude/plugins/marketplaces/ku5ic/install-rules.sh

  claude mcp get context7 >/dev/null 2>&1 || claude mcp add -s user context7 -- npx -y @upstash/context7-mcp
  claude mcp get foxhole >/dev/null 2>&1 || claude mcp add -s user foxhole -- foxhole mcp
  claude mcp get playwright >/dev/null 2>&1 || claude mcp add -s user playwright -- npx @playwright/mcp@latest
}

install_launchd_agents() {
  mkdir -p "$HOME/Library/LaunchAgents"
  local brew_bash
  brew_bash="$(brew --prefix)/bin/bash"
  for template in "$DOTFILES_DIR/macos/launchd/"*.plist; do
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
    "$DOTFILES_DIR/macos" \
    -type f -name '*.sh' -exec chmod +x {} +
}

setup_asdf() {
  local tool_versions="$DOTFILES_DIR/home/tool-versions"

  if [ ! -f "$tool_versions" ]; then
    echo "Missing .tool-versions at $tool_versions"
    exit 1
  fi

  # Register plugins, tolerating already-added state
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git || true
  asdf plugin add python || true
  asdf plugin add golang https://github.com/asdf-community/asdf-golang.git || true
  # Project .tool-versions pin it; installed per project with `asdf install`
  asdf plugin add golangci-lint https://github.com/hypnoglow/asdf-golangci-lint.git || true

  # Update all plugins
  asdf plugin update --all

  # Install each version declared in .tool-versions
  while IFS=' ' read -r plugin version || [ -n "$plugin" ]; do
    # Skip blank lines and comments
    [[ -z "$plugin" || "$plugin" == \#* ]] && continue

    echo "Installing $plugin $version"
    asdf install "$plugin" "$version"
  done <"$tool_versions"
}

STAGES=(
  update_dotfiles
  install_homebrew
  install_shells
  install_packages
  fix_permissions
  create_symlinks
  setup_claude
  install_launchd_agents
  setup_asdf
)

# No arguments runs every stage; otherwise only the named ones, in the order given.
main() {
  local stages=("$@") stage
  ((${#stages[@]})) || stages=("${STAGES[@]}")

  for stage in "${stages[@]}"; do
    if [[ " ${STAGES[*]} " != *" $stage "* ]]; then
      echo "install.sh: unknown stage '$stage'. Stages: ${STAGES[*]}" >&2
      exit 2
    fi
  done

  for stage in "${stages[@]}"; do
    CURRENT_STAGE="$stage"
    "$stage"
  done

  echo ""
  echo "install.sh: completed."
}

main "$@"
