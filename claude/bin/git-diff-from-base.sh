#!/usr/bin/env bash
# Prints `git diff <base>..HEAD` where <base> is resolved by git-base.sh.
# Accepts an optional explicit base via $1.
set -euo pipefail
base="$(git-base.sh "${1:-}")"
git diff "${base}..HEAD"
