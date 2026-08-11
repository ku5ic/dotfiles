#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit: blocks writes to risky paths
# regardless of permission rules. Callable standalone or sourced by
# guard-dispatch.sh, which reads the payload once for all three checks.
HOOK_NAME="guard-edit.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

run_guard_edit() {
  # Shadows the file-scope HOOK_NAME via bash's dynamic scoping - without
  # this, sourcing all three guard files into one dispatcher process leaves
  # HOOK_NAME set to whichever file was sourced last, misattributing every
  # block() entry.
  local HOOK_NAME="guard-edit.sh"
  path="$(extract_path)"
  [[ -z "$path" ]] && return 0

  block() {
    echo "Blocked by ${HOOK_NAME}: $1" >&2
    echo "Path: $path" >&2
    exit 2
  }

  case "$(basename "$path")" in
  package-lock.json | pnpm-lock.yaml | yarn.lock | bun.lockb | Gemfile.lock | Cargo.lock | composer.lock | poetry.lock | uv.lock | pdm.lock | requirements.txt.lock)
    block "lockfile edit. Use the package manager." "lockfile-edit"
    ;;
  esac

  [[ "$path" =~ /\.git/ ]] && block "edit inside .git/" "git-dir-edit"

  case "$path" in
  "$HOME/.zshrc" | "$HOME/.zprofile" | "$HOME/.bashrc" | "$HOME/.bash_profile" | "$HOME/.profile")
    block "direct edit to a shell rc file. Use the dotfiles repo." "rc-edit"
    ;;
  esac

  # Defense in depth: settings.json deny rules cover the same ground, but a
  # misconfigured permission file shouldn't be the only thing standing
  # between an injection and a clobbered key. Patterns must mirror
  # settings.json; bin/doctor.sh enforces parity.
  case "$(basename "$path")" in
  *.pem | *.key | *.pfx | *.p12)
    block "credential or key file" "cred-file"
    ;;
  id_rsa | id_ed25519 | id_ecdsa)
    block "SSH private key" "ssh-key"
    ;;
  .env | .env.*)
    block ".env file" "env-file"
    ;;
  esac

  case "$path" in
  "$HOME/.ssh/"*)
    block "edit inside ~/.ssh/" "ssh-dir"
    ;;
  "$HOME/.gnupg/"*)
    block "edit inside ~/.gnupg/" "gnupg-dir"
    ;;
  "$HOME/.aws/credentials" | "$HOME/.aws/config")
    block "AWS credentials or config" "aws-creds"
    ;;
  "$HOME/.docker/config.json")
    block "docker auth config" "docker-config"
    ;;
  "$HOME/.config/gh/hosts.yml")
    block "gh CLI auth" "gh-auth"
    ;;
  "$HOME/.netrc" | "$HOME/.pgpass" | "$HOME/.npmrc")
    block "credential file" "dotfile-cred"
    ;;
  "$HOME/.pypirc")
    block "PyPI credentials" "pypi-creds"
    ;;
  "$HOME/.cargo/credentials")
    block "cargo registry credentials" "cargo-creds"
    ;;
  "$HOME/.gem/credentials")
    block "RubyGems credentials" "gem-creds"
    ;;
  "$HOME/Library/Keychains/"*)
    block "macOS keychain" "keychain"
    ;;
  esac

  if [[ "$path" =~ \.github/workflows/.*\.ya?ml$ ]]; then
    echo "guard-edit: editing CI workflow $path" >&2
  fi

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  read_payload
  require_jq
  run_guard_edit
fi
