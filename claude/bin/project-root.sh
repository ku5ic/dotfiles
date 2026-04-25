#!/usr/bin/env bash
# Resolves the project root absolute path. Single source of truth for the
# walk-up logic shared by project-name.sh, detect-stack.sh, and any hook
# that needs a project root.
#
# Resolution order:
#   1. Git working tree:    `git rev-parse --show-toplevel` (walks up itself)
#   2. Project anchor walk: nearest ancestor (up to 3 levels) with
#                           package.json, pyproject.toml, Gemfile,
#                           Cargo.toml, or go.mod
#   3. Current directory:   $PWD
#
# Always prints an absolute path. Consumers decide how to handle special
# cases like $HOME or /.

set -euo pipefail

if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "$root"
  exit 0
fi

dir="$PWD"
depth=0
while [[ "$dir" != "/" && $depth -lt 3 ]]; do
  for f in package.json pyproject.toml Gemfile Cargo.toml go.mod; do
    if [[ -f "$dir/$f" ]]; then
      echo "$dir"
      exit 0
    fi
  done
  dir="$(dirname "$dir")"
  depth=$((depth + 1))
done

echo "$PWD"
