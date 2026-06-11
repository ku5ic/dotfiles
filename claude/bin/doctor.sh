#!/usr/bin/env bash
# Verifies the Claude config: symlink layout AND cross-file consistency.
# Used by .github/workflows/lint.yml and runnable locally.
#
# Checks:
#   1. Symlinks: each top-level claude/ entry is symlinked to the dotfiles
#      source. Verifies link existence and target path.
#   2. Credential pattern parity: settings.json deny rules and guard-edit.sh
#      both list every credential pattern. Both layers exist as defense in
#      depth (a misconfigured permission file should not be the only thing
#      standing between an injection and a clobbered key).
#
# Adding a credential pattern: add it to the `patterns` array below AND to
# hooks/guard-edit.sh's "Sensitive credential and key files" case block AND
# settings.json's deny array.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ROOT="$HOME/.claude"

ENTRIES=(settings.json CLAUDE.md commands hooks skills bin)

exit_code=0

if [[ -d "$TARGET_ROOT" ]]; then
  echo "== symlinks =="
  for entry in "${ENTRIES[@]}"; do
    src="$SOURCE_ROOT/$entry"
    dst="$TARGET_ROOT/$entry"

    if [[ ! -L "$dst" ]]; then
      if [[ -e "$dst" ]]; then
        echo "not-a-symlink  $dst"
      else
        echo "missing        $dst"
      fi
      exit_code=1
      continue
    fi

    actual="$(readlink "$dst")"
    if [[ "${actual%/}" != "$src" ]]; then
      echo "wrong-target   $dst -> $actual (expected $src)"
      exit_code=1
      continue
    fi

    echo "ok             $dst"
  done
else
  echo "== symlinks == (skipped: $TARGET_ROOT does not exist; running outside an installed-dotfiles environment, e.g. CI)"
fi

echo
echo "== credential pattern parity =="

GUARD_EDIT="$SOURCE_ROOT/hooks/guard-edit.sh"
GUARD_BASH="$SOURCE_ROOT/hooks/guard-bash.sh"
SETTINGS="$SOURCE_ROOT/settings.json"

# Canonical credential patterns. Each must appear verbatim in all three files.
# Path-tail forms are used so settings.json's `~/...` and the guard hooks'
# `$HOME/...` both contain the substring.
# Adding a pattern: add it here AND to guard-edit.sh, guard-bash.sh (_is_sensitive_arg),
# and settings.json deny rules.
patterns=(
  "*.pem"
  "*.key"
  "*.pfx"
  "*.p12"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
  ".env"
  ".env.*"
  ".ssh/"
  ".gnupg/"
  ".aws/credentials"
  ".aws/config"
  ".docker/config.json"
  ".config/gh/hosts.yml"
  ".netrc"
  ".pgpass"
  ".npmrc"
  "Library/Keychains/"
  ".pypirc"
  ".cargo/credentials"
  ".gem/credentials"
)

parity_failed=0
for pat in "${patterns[@]}"; do
  if ! grep -qF "$pat" "$GUARD_EDIT"; then
    echo "missing-pattern  guard-edit.sh: '$pat'"
    parity_failed=1
  fi
  if ! grep -qF "$pat" "$GUARD_BASH"; then
    echo "missing-pattern  guard-bash.sh: '$pat'"
    parity_failed=1
  fi
  if ! grep -qF "$pat" "$SETTINGS"; then
    echo "missing-pattern  settings.json: '$pat'"
    parity_failed=1
  fi
done

if ((parity_failed)); then
  exit_code=1
else
  echo "ok             ${#patterns[@]} patterns mirrored across guard-edit.sh, guard-bash.sh, and settings.json"
fi

exit "$exit_code"
