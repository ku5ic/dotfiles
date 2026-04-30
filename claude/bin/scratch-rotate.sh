#!/usr/bin/env bash
# Prunes ~/.claude/scratch/ artifacts older than 30 days.
# Run manually or wire to launchd. Safe to run repeatedly; idempotent.
#
# Override the retention window with the first argument (number of days):
#   scratch-rotate.sh        # 30 days (default)
#   scratch-rotate.sh 14     # 14 days

set -euo pipefail

scratch_dir="$HOME/.claude/scratch"
days="${1:-30}"

[[ -d "$scratch_dir" ]] || exit 0

# Only prune .md artifacts. Hidden marker files (.injected-*) are session
# scoped and small; leave them alone.
removed="$(find "$scratch_dir" -type f -name '*.md' -mtime +"$days" -print -delete | wc -l | tr -d ' ')"

echo "scratch-rotate: pruned $removed artifact(s) older than ${days}d from $scratch_dir"
