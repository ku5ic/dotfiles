#!/usr/bin/env bash
# Prints the base branch or ref for the current git checkout. Detection order:
#   1. Explicit base argument, if it resolves to a valid ref
#   2. Upstream tracking branch (@{upstream}), unless it's just this branch's own
#      push destination (e.g. `git push -u origin <same-branch-name>`) rather than
#      a distinct merge target - that case is skipped in favor of step 3/4, since
#      a feature branch pushed under its own name always diffs empty against itself.
#   3. Remote HEAD (origin/HEAD)
#   4. Common defaults: main, master, develop, trunk (first that exists)
#
#   git-base.sh [base]                  the base ref
#   git-base.sh --diff [base] [-flags]  git diff <base>...HEAD: three-dot, against
#                                       the merge-base, so commits that landed on
#                                       base after this branch forked don't show
#                                       up reversed - GitHub's PR diff semantics
#   git-base.sh --log [base] [-flags]   git log --oneline <base>..HEAD
# Flags are words starting with "-" (e.g. --no-merges) and pass through to git.
# The mode is a flag, not a word, so a branch named diff or log still works as
# the base.
#
# Exits non-zero if nothing resolves. Prints nothing to stderr on normal use.

set -euo pipefail

mode="base"
case "${1:-}" in
--diff)
  mode="diff"
  shift
  ;;
--log)
  mode="log"
  shift
  ;;
esac

explicit=""
extra=()
for arg in "$@"; do
  case "$arg" in
  -*) extra+=("$arg") ;;
  *) explicit="$arg" ;;
  esac
done

resolve_base() {
  if [ -n "$explicit" ] && git rev-parse --verify "$explicit" >/dev/null 2>&1; then
    echo "$explicit"
    return 0
  fi

  local upstream current_branch resolved b
  if upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"; then
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [ "${upstream#*/}" != "$current_branch" ]; then
      echo "$upstream"
      return 0
    fi
  fi

  if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
    resolved="$(git symbolic-ref --short refs/remotes/origin/HEAD)"
    if git rev-parse --verify "$resolved" >/dev/null 2>&1; then
      echo "$resolved"
      return 0
    fi
  fi

  for b in main master develop trunk; do
    if git rev-parse --verify "$b" >/dev/null 2>&1; then
      echo "$b"
      return 0
    fi
  done
  return 1
}

base="$(resolve_base)" || exit 1

case "$mode" in
base) echo "$base" ;;
diff) git diff "${extra[@]}" "${base}...HEAD" ;;
log) git log --oneline "${extra[@]}" "${base}..HEAD" ;;
esac
