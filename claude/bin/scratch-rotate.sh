#!/usr/bin/env bash
# Prunes ~/.claude/scratch/ artifacts older than 30 days, plus every
# project-scoped scratch/ dir registered in scratch-registry.txt (see
# scratch-dir.sh - this run has no project cwd of its own, only $HOME, so
# the registry is the only way it finds those directories).
# Also trims ~/.claude/logs/skills.jsonl to the last N lines (default 10000).
# Run manually or wire to launchd. Safe to run repeatedly; idempotent.
#
# Override the retention window with the first argument (number of days):
#   scratch-rotate.sh        # 30 days (default)
#   scratch-rotate.sh 14     # 14 days
#
# Override the skills.jsonl line cap with the second argument:
#   scratch-rotate.sh 30 5000

set -euo pipefail

scratch_dir="$HOME/.claude/scratch"
skills_log="$HOME/.claude/logs/skills.jsonl"
registry="$HOME/.claude/logs/scratch-registry.txt"
days="${1:-30}"
max_lines="${2:-10000}"

if [[ -d "$scratch_dir" ]]; then
  # Prune .md artifacts (configurable retention) and stale .injected-*
  # session markers (fixed 1-day retention - they're only needed to dedupe
  # injection within a session's lifetime, far shorter than artifact
  # retention).
  removed="$(find "$scratch_dir" -type f -name '*.md' -mtime +"$days" -print -delete | wc -l | tr -d ' ')"
  markers_removed="$(find "$scratch_dir" -maxdepth 1 -type f -name '.injected-*' -mtime +1 -print -delete | wc -l | tr -d ' ')"

  echo "scratch-rotate: pruned $removed artifact(s) older than ${days}d from $scratch_dir"
  echo "scratch-rotate: pruned $markers_removed session marker(s) older than 1d from $scratch_dir"
fi

if [[ -f "$registry" ]]; then
  # Project scratch/ dirs hold test artifacts and POC files of any
  # extension, not just reports, so prune by age alone - no name filter.
  tmp_registry="$(mktemp)"
  while IFS= read -r proj_dir; do
    [[ -z "$proj_dir" ]] && continue
    if [[ -d "$proj_dir" ]]; then
      proj_removed="$(find "$proj_dir" -type f -mtime +"$days" -print -delete | wc -l | tr -d ' ')"
      echo "scratch-rotate: pruned $proj_removed artifact(s) older than ${days}d from $proj_dir"
      echo "$proj_dir" >>"$tmp_registry"
    else
      echo "scratch-rotate: dropping stale registry entry $proj_dir (directory no longer exists)"
    fi
  done <"$registry"
  mv "$tmp_registry" "$registry"
fi

if [[ -f "$skills_log" ]]; then
  total="$(wc -l <"$skills_log" | tr -d ' ')"
  if ((total > max_lines)); then
    tmp="$(mktemp)"
    tail -n "$max_lines" "$skills_log" >"$tmp"
    mv "$tmp" "$skills_log"
    echo "scratch-rotate: trimmed skills.jsonl from $total to $max_lines lines"
  else
    echo "scratch-rotate: skills.jsonl has $total lines, no trim needed"
  fi
fi
