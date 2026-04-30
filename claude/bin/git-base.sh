#!/usr/bin/env bash
# ~/.dotfiles/claude/bin/git-base.sh
#
# Prints the base branch or ref for the current git checkout. Detection order:
#   1. Explicit argument ($1), if it resolves to a valid ref
#   2. Upstream tracking branch (@{upstream})
#   3. Remote HEAD (origin/HEAD)
#   4. Common defaults: main, master, develop, trunk (first that exists)
#
# Exits non-zero if nothing resolves. Prints nothing to stderr on normal use.

set -euo pipefail

explicit="${1:-}"

if [ -n "$explicit" ]; then
  if git rev-parse --verify "$explicit" >/dev/null 2>&1; then
    echo "$explicit"
    exit 0
  fi
fi

if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  git rev-parse --abbrev-ref '@{upstream}'
  exit 0
fi

if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
  git symbolic-ref --short refs/remotes/origin/HEAD
  exit 0
fi

for b in main master develop trunk; do
  if git rev-parse --verify "$b" >/dev/null 2>&1; then
    echo "$b"
    exit 0
  fi
done

exit 1
