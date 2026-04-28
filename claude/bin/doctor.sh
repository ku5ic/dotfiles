#!/usr/bin/env bash
# Verifies the Claude config symlink layout. Symlink verification only:
# does NOT check executable bits, script correctness, detect-stack output,
# or anything else. Broader audits belong in a separate command.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ROOT="$HOME/.claude"

ENTRIES=(settings.json CLAUDE.md commands hooks skills bin)

exit_code=0

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

exit "$exit_code"
