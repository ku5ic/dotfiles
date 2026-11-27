#!/usr/bin/env bats
# Tests for the create_symlinks, setup_claude, and setup_gh stages of ~/.dotfiles/install.sh.
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

@test "setup_claude links the skills folder" {
  mkdir -p "$HOME/.dotfiles/claude/skills/memory-sync"

  # A bare PATH hides the claude CLI, so the stage stops after linking.
  PATH=/usr/bin:/bin run bash "$HOME/.dotfiles/install.sh" setup_claude

  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.claude/skills")" = "$HOME/.dotfiles/claude/skills" ]
}

# A fake gh logs its arguments, and `gh extension list` prints
# $HOME/extensions, one tab-separated row per installed extension.
fake_gh() {
  mkdir -p "$HOME/bin"
  touch "$HOME/extensions"
  cat >"$HOME/bin/gh" <<'SH'
#!/bin/bash
echo "$*" >>"$HOME/gh.log"
[[ "$1 $2" != "extension list" ]] || cat "$HOME/extensions"
SH
  chmod +x "$HOME/bin/gh"
}

installed_extension() {
  printf 'gh %s\t%s\tv1.0.0\n' "${1##*/gh-}" "$1" >>"$HOME/extensions"
}

GH_EXTENSIONS=(github/gh-stack github/gh-aw github/gh-combine cli/gh-webhook github/gh-codeql)

@test "setup_gh installs every extension and the gh-stack skill when none are present" {
  fake_gh

  PATH="$HOME/bin:/usr/bin:/bin" run bash "$HOME/.dotfiles/install.sh" setup_gh

  [ "$status" -eq 0 ]
  for ext in "${GH_EXTENSIONS[@]}"; do
    grep -qxF "extension install $ext" "$HOME/gh.log"
  done
  grep -qxF "skill install github/gh-stack gh-stack --agent claude-code --scope user" "$HOME/gh.log"
}

@test "setup_gh installs only the extensions that are missing" {
  fake_gh
  installed_extension github/gh-stack
  installed_extension github/gh-aw-mcpg

  PATH="$HOME/bin:/usr/bin:/bin" run bash "$HOME/.dotfiles/install.sh" setup_gh

  [ "$status" -eq 0 ]
  ! grep -qxF "extension install github/gh-stack" "$HOME/gh.log"
  grep -qxF "extension install github/gh-aw" "$HOME/gh.log"
}

@test "setup_gh installs nothing when every extension and the skill are present" {
  fake_gh
  for ext in "${GH_EXTENSIONS[@]}"; do
    installed_extension "$ext"
  done
  mkdir -p "$HOME/.claude/skills/gh-stack"

  PATH="$HOME/bin:/usr/bin:/bin" run bash "$HOME/.dotfiles/install.sh" setup_gh

  [ "$status" -eq 0 ]
  ! grep -q "install" "$HOME/gh.log"
}
