#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit.
# Blocks writes to risky paths regardless of permission rules.
HOOK_NAME="guard-edit.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"
[[ -z "$path" ]] && exit 0

# Override _lib.sh block() to also show the offending path for context.
block() {
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  echo "Path: $path" >&2
  exit 2
}

case "$(basename "$path")" in
  package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb|Gemfile.lock|Cargo.lock|composer.lock|poetry.lock|uv.lock|requirements.txt.lock)
    block "lockfile edit. Use the package manager."
    ;;
esac

[[ "$path" =~ /\.git/ ]] && block "edit inside .git/"

case "$path" in
  $HOME/.zshrc|$HOME/.zprofile|$HOME/.bashrc|$HOME/.bash_profile|$HOME/.profile)
    block "direct edit to a shell rc file. Use the dotfiles repo."
    ;;
esac

# Sensitive credential and key files. Defense in depth: settings.json deny
# rules cover the same ground, but a misconfigured permission file should
# not be the only thing standing between an injection and a clobbered key.
case "$(basename "$path")" in
  *.pem|*.key|*.pfx|*.p12)
    block "credential or key file"
    ;;
  id_rsa|id_ed25519|id_ecdsa)
    block "SSH private key"
    ;;
  .env|.env.*)
    block ".env file"
    ;;
esac

case "$path" in
  $HOME/.ssh/*)
    block "edit inside ~/.ssh/"
    ;;
  $HOME/.gnupg/*)
    block "edit inside ~/.gnupg/"
    ;;
  $HOME/.aws/credentials|$HOME/.aws/config)
    block "AWS credentials or config"
    ;;
  $HOME/.docker/config.json)
    block "docker auth config"
    ;;
  $HOME/.config/gh/hosts.yml)
    block "gh CLI auth"
    ;;
  $HOME/.netrc|$HOME/.pgpass|$HOME/.npmrc)
    block "credential file"
    ;;
  $HOME/Library/Keychains/*)
    block "macOS keychain"
    ;;
esac

if [[ "$path" =~ \.github/workflows/.*\.ya?ml$ ]]; then
  echo "guard-edit: editing CI workflow $path" >&2
fi

exit 0
