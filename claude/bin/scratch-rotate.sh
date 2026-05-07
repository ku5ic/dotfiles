#!/usr/bin/env bash
# Prunes ~/.claude/scratch/ artifacts older than 30 days.
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
days="${1:-30}"
max_lines="${2:-10000}"

[[ -d "$scratch_dir" ]] || exit 0

# Only prune .md artifacts. Hidden marker files (.injected-*) are session
# scoped and small; leave them alone.
removed="$(find "$scratch_dir" -type f -name '*.md' -mtime +"$days" -print -delete | wc -l | tr -d ' ')"

echo "scratch-rotate: pruned $removed artifact(s) older than ${days}d from $scratch_dir"

if [[ -f "$skills_log" ]]; then
  total="$(wc -l < "$skills_log" | tr -d ' ')"
  if (( total > max_lines )); then
    tmp="$(mktemp)"
    tail -n "$max_lines" "$skills_log" > "$tmp"
    mv "$tmp" "$skills_log"
    echo "scratch-rotate: trimmed skills.jsonl from $total to $max_lines lines"
  else
    echo "scratch-rotate: skills.jsonl has $total lines, no trim needed"
  fi
fi
