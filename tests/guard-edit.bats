#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/hooks/guard-edit.sh.
#
# Each test feeds a synthetic Edit/Write/MultiEdit payload to the hook on
# stdin and asserts the exit code: 0 = allow, 2 = block.
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-edit.sh"
}

# Builds an Edit/Write/MultiEdit payload from a path string and pipes it to
# the hook. Uses jq -R so the path can contain any character.
run_guard_edit() {
  printf '%s' "$1" | jq -R '{tool_input: {file_path: .}}' | "$HOOK"
}

# positive cases (must allow)

@test "allow: ts source file" {
  run run_guard_edit '/tmp/test.ts'
  [ "$status" -eq 0 ]
}

@test "allow: py source file" {
  run run_guard_edit '/tmp/test.py'
  [ "$status" -eq 0 ]
}

@test "allow: markdown doc" {
  run run_guard_edit '/tmp/foo.md'
  [ "$status" -eq 0 ]
}

@test "allow: nested project file" {
  run run_guard_edit '/tmp/some/nested/dir/file.tsx'
  [ "$status" -eq 0 ]
}

@test "allow: package.json (not a lockfile)" {
  run run_guard_edit '/tmp/package.json'
  [ "$status" -eq 0 ]
}

# negative cases (must block)

# Lockfiles
@test "block: package-lock.json" {
  run run_guard_edit '/tmp/package-lock.json'
  [ "$status" -eq 2 ]
}

@test "block: pnpm-lock.yaml" {
  run run_guard_edit '/tmp/pnpm-lock.yaml'
  [ "$status" -eq 2 ]
}

@test "block: yarn.lock" {
  run run_guard_edit '/tmp/yarn.lock'
  [ "$status" -eq 2 ]
}

@test "block: Gemfile.lock" {
  run run_guard_edit '/tmp/Gemfile.lock'
  [ "$status" -eq 2 ]
}

@test "block: Cargo.lock" {
  run run_guard_edit '/tmp/Cargo.lock'
  [ "$status" -eq 2 ]
}

@test "block: poetry.lock" {
  run run_guard_edit '/tmp/poetry.lock'
  [ "$status" -eq 2 ]
}

@test "block: uv.lock" {
  run run_guard_edit '/tmp/uv.lock'
  [ "$status" -eq 2 ]
}

# .git/ paths
@test "block: edit inside .git/" {
  run run_guard_edit '/tmp/repo/.git/HEAD'
  [ "$status" -eq 2 ]
}

@test "block: edit nested inside .git/" {
  run run_guard_edit '/tmp/repo/.git/refs/heads/main'
  [ "$status" -eq 2 ]
}

# Shell rc files
@test "block: ~/.zshrc" {
  run run_guard_edit "$HOME/.zshrc"
  [ "$status" -eq 2 ]
}

@test "block: ~/.zprofile" {
  run run_guard_edit "$HOME/.zprofile"
  [ "$status" -eq 2 ]
}

@test "block: ~/.bashrc" {
  run run_guard_edit "$HOME/.bashrc"
  [ "$status" -eq 2 ]
}

# Credential basenames
@test "block: .env" {
  run run_guard_edit '/tmp/.env'
  [ "$status" -eq 2 ]
}

@test "block: .env.production" {
  run run_guard_edit '/tmp/.env.production'
  [ "$status" -eq 2 ]
}

@test "block: .pem cert" {
  run run_guard_edit '/tmp/server.pem'
  [ "$status" -eq 2 ]
}

@test "block: .key file" {
  run run_guard_edit '/tmp/private.key'
  [ "$status" -eq 2 ]
}

@test "block: .pfx file" {
  run run_guard_edit '/tmp/cert.pfx'
  [ "$status" -eq 2 ]
}

@test "block: .p12 file" {
  run run_guard_edit '/tmp/cert.p12'
  [ "$status" -eq 2 ]
}

@test "block: id_rsa" {
  run run_guard_edit '/tmp/id_rsa'
  [ "$status" -eq 2 ]
}

@test "block: id_ed25519" {
  run run_guard_edit '/tmp/id_ed25519'
  [ "$status" -eq 2 ]
}

@test "block: id_ecdsa" {
  run run_guard_edit '/tmp/id_ecdsa'
  [ "$status" -eq 2 ]
}

# Per-path absolute matches
@test "block: ~/.ssh/config" {
  run run_guard_edit "$HOME/.ssh/config"
  [ "$status" -eq 2 ]
}

@test "block: ~/.gnupg/gpg.conf" {
  run run_guard_edit "$HOME/.gnupg/gpg.conf"
  [ "$status" -eq 2 ]
}

@test "block: ~/.aws/credentials" {
  run run_guard_edit "$HOME/.aws/credentials"
  [ "$status" -eq 2 ]
}

@test "block: ~/.aws/config" {
  run run_guard_edit "$HOME/.aws/config"
  [ "$status" -eq 2 ]
}

@test "block: ~/.docker/config.json" {
  run run_guard_edit "$HOME/.docker/config.json"
  [ "$status" -eq 2 ]
}

@test "block: ~/.config/gh/hosts.yml" {
  run run_guard_edit "$HOME/.config/gh/hosts.yml"
  [ "$status" -eq 2 ]
}

@test "block: ~/.netrc" {
  run run_guard_edit "$HOME/.netrc"
  [ "$status" -eq 2 ]
}

@test "block: ~/.pgpass" {
  run run_guard_edit "$HOME/.pgpass"
  [ "$status" -eq 2 ]
}

@test "block: ~/.npmrc" {
  run run_guard_edit "$HOME/.npmrc"
  [ "$status" -eq 2 ]
}

@test "block: macOS Keychain entry" {
  run run_guard_edit "$HOME/Library/Keychains/login.keychain-db"
  [ "$status" -eq 2 ]
}
