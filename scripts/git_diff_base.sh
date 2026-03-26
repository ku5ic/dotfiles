#!/usr/bin/env bash

base="${1:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
  exit 1
fi

if [ -z "$base" ]; then
  if git show-ref --verify --quiet refs/heads/main; then
    base="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    base="master"
  elif git show-ref --verify --quiet refs/remotes/origin/main; then
    base="origin/main"
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
    base="origin/master"
  else
    echo "No base branch provided, and neither main nor master was found" >&2
    exit 1
  fi
fi

if ! git rev-parse --verify "$base" >/dev/null 2>&1; then
  echo "Base branch '$base' does not exist" >&2
  exit 1
fi

current_branch="$(git branch --show-current)"

if [ -z "$current_branch" ]; then
  echo "Could not determine current branch" >&2
  exit 1
fi

git diff "$base...$current_branch"
