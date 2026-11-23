#!/usr/bin/env bats
# Tests for the create_symlinks stage of ~/.dotfiles/install.sh.
#
# install.sh reads everything from $HOME, so each test points HOME at a temp
# dir holding a minimal fake ~/.dotfiles.
#
# Run with: bats tests/

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.dotfiles/config/app" "$HOME/.dotfiles/home"
  cp "$BATS_TEST_DIRNAME/../install.sh" "$HOME/.dotfiles/install.sh"
  touch "$HOME/.dotfiles/config/app/config.toml"
}

@test "a real directory an app created first is replaced by the link, not nested in it" {
  mkdir -p "$HOME/.config/app"
  touch "$HOME/.config/app/state.db"

  run bash "$HOME/.dotfiles/install.sh" create_symlinks

  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.config/app")" = "$HOME/.dotfiles/config/app" ]
  [ ! -e "$HOME/.dotfiles/config/app/app" ]
}

@test "the replaced directory is kept as a backup" {
  mkdir -p "$HOME/.config/app"
  touch "$HOME/.config/app/state.db"

  run bash "$HOME/.dotfiles/install.sh" create_symlinks

  backups=("$HOME"/.config/app.bak.*)
  [ -e "${backups[0]}/state.db" ]
}

@test "an existing link is replaced without a backup" {
  mkdir -p "$HOME/.config"
  ln -s "$HOME/elsewhere" "$HOME/.config/app"

  run bash "$HOME/.dotfiles/install.sh" create_symlinks

  [ "$(readlink "$HOME/.config/app")" = "$HOME/.dotfiles/config/app" ]
  ! compgen -G "$HOME/.config/app.bak.*"
}
