#!/usr/bin/env bash
# Report structural problems in the Claude memory directory, one per line.
# Exits 0 when there are none, 1 when there are, 2 when the directory is missing.
set -euo pipefail
shopt -s nullglob

# Claude Code loads no more of MEMORY.md than this.
readonly MAX_LINES=200
readonly MAX_BYTES=25000

memory_dir="${1:-$HOME/claude-memory}"
cd "$memory_dir" 2>/dev/null || {
  printf 'claude_memory_check: no directory %s\n' "$memory_dir" >&2
  exit 2
}

problems=0
problem() {
  printf '%s\n' "$1"
  problems=$((problems + 1))
}

index_links() {
  grep -oE '\]\([^)]+\.md\)' MEMORY.md | sed -E 's/^\]\((.*)\)$/\1/' || true
}

check_index() {
  local lines bytes link
  lines=$(wc -l <MEMORY.md | tr -d ' ')
  bytes=$(wc -c <MEMORY.md | tr -d ' ')
  if ((lines > MAX_LINES)); then problem "MEMORY.md: $lines lines, over $MAX_LINES"; fi
  if ((bytes > MAX_BYTES)); then problem "MEMORY.md: $bytes bytes, over $MAX_BYTES"; fi
  if grep -qE '^(<<<<<<<|>>>>>>>) ' MEMORY.md; then problem "MEMORY.md: conflict markers"; fi

  while IFS= read -r link; do
    [[ -z "$link" || -e "$link" ]] || problem "MEMORY.md: $link does not exist"
  done <<<"$(index_links | sort -u)"
}

check_memory() {
  local file=$1 slug count
  slug=$(basename "$file" .md)

  if grep -qE '^(<<<<<<<|>>>>>>>) ' "$file"; then problem "$file: conflict markers"; fi
  grep -qxF "name: $slug" "$file" || problem "$file: name is not '$slug'"

  count=$(index_links | grep -cxF "$file" || true)
  case "$count" in
  0) problem "$file: not in MEMORY.md" ;;
  1) ;;
  *) problem "$file: $count lines in MEMORY.md" ;;
  esac
}

check_slugs() {
  local slug
  while IFS= read -r slug; do
    [[ -z "$slug" ]] || problem "$slug: in more than one folder"
  done <<<"$(printf '%s\n' */*.md | sed 's#.*/##' | sort | uniq -d)"
}

check_root() {
  local file
  for file in *.md; do
    case "$file" in
    MEMORY.md | README.md) ;;
    *) problem "$file: not in a folder" ;;
    esac
  done
}

check_index
check_root
for file in */*.md; do check_memory "$file"; done
check_slugs

((problems == 0))
