#!/usr/bin/env bash
# Prints commits in <base>..HEAD where <base> is resolved by git-base.sh.
# Accepts an optional explicit base via $1.
# Accepts optional extra git log flags via $2 (e.g. "--no-merges").
set -euo pipefail
base="$(git-base.sh "${1:-}")"
extra="${2:-}"
# shellcheck disable=SC2086
git log --oneline ${extra} "${base}..HEAD"
