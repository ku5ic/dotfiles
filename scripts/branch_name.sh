#!/usr/bin/env bash

# git_branch_name
#
# Purpose:
#   Produce a normalized git branch name from user input, with an optional
#   direct checkout mode.
#
# Intent and design notes:
#   - Keeps branch naming consistent across team workflows.
#   - Supports two naming shapes:
#       <type>/<slug>
#       <type>/<ISSUE-ID>/<slug>
#   - Treats the first post-type token as issue id only when 2+ tokens remain.
#     This allows multi-word titles without forcing an issue id.
#   - Uses conservative sanitization so output is git-friendly and predictable.
#
# Parameters:
#   Positional:
#     <type>       Required. Must be one of:
#                  feat, fix, refactor, perf, test, docs, build, ci, chore, style, release
#     <issue_id>   Optional. Normalized to uppercase and restricted to [A-Z0-9_-].
#     <title...>   Required. Remaining args are joined with spaces and slugified.
#   Flags:
#     --checkout   Create and checkout the branch via `git checkout -b` instead of printing.
#     -h, --help   Print usage.
#
# Return / output behavior:
#   - Success without --checkout: prints branch name to stdout and exits 0.
#   - Success with --checkout: runs git command and exits with git's status.
#   - Validation or sanitization failures: prints error to stderr and exits non-zero.
#
# Side effects:
#   - With --checkout, mutates repository state by creating a new local branch and
#     switching HEAD to it.
#
# Constraints and edge cases:
#   - Title is mandatory; if sanitization removes all characters, execution fails.
#   - Issue id is optional and omitted from output when not supplied.
#   - Unknown branch types are rejected early.
#   - Intended for execution inside a git repository when using --checkout.
#   - Uses Bash + sed/tr with POSIX character classes; behavior assumes typical GNU/BSD userland.
die() {
  echo "Error: $*" >&2
  exit 1
}

sanitize_issue_id() {
  printf '%s' "$1" \
    | tr '[:lower:]' '[:upper:]' \
    | sed -E 's/[^A-Z0-9_-]+/-/g' \
    | sed -E 's/^-+//; s/-+$//'
}

sanitize_title() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[[:space:]]+/_/g' \
    | sed -E 's/[^a-z0-9_]+/_/g' \
    | sed -E 's/_+/_/g' \
    | sed -E 's/^_+//; s/_+$//'
}

is_valid_type() {
  case "$1" in
    feat|fix|refactor|perf|test|docs|build|ci|chore|style|release)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

checkout=false

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--checkout" ]]; then
  checkout=true
  shift
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

branch_type="$1"
shift

is_valid_type "$branch_type" || die "Invalid branch type '$branch_type'. Allowed: feat, fix, refactor, perf, test, docs, build, ci, chore, style, release"

issue_id=""
title=""

if [[ $# -eq 1 ]]; then
  title="$1"
else
  issue_id="$(sanitize_issue_id "$1")"
  shift
  title="$*"
fi

[[ -n "$title" ]] || die "Title is required"

slug="$(sanitize_title "$title")"
[[ -n "$slug" ]] || die "Title produced an empty branch slug after sanitization"

if [[ -n "$issue_id" ]]; then
  branch_name="${branch_type}/${issue_id}/${slug}"
else
  branch_name="${branch_type}/${slug}"
fi

if [[ "$checkout" == true ]]; then
  git checkout -b "$branch_name"
else
  printf '%s\n' "$branch_name"
fi
