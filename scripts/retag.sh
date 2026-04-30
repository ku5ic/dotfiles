#!/usr/bin/env bash
set -euo pipefail

yes=0
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]]; then
  yes=1
  shift
fi

if [[ $# -ne 1 ]]; then
  printf '\033[31mPlease provide the tag name and try again.\033[0m\n\n\tUsage: retag [-y|--yes] <tag_name>\n' >&2
  exit 1
fi

tag="$1"

if [[ $yes -eq 0 ]]; then
  printf 'About to force-recreate tag %s and force-push it to origin. Proceed? [y/N] ' "$tag"
  read -r response
  case "$response" in
    y|Y|yes|YES) ;;
    *) printf 'aborted\n' >&2; exit 1 ;;
  esac
fi

git tag -f "$tag"
git push -f origin "$tag"
