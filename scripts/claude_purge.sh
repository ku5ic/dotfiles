#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob dotglob

dry_run=false
case "${1:-}" in
  "") ;;
  -n | --dry-run) dry_run=true ;;
  *)
    echo "usage: claude_purge [-n|--dry-run]" >&2
    exit 2
    ;;
esac

targets=(
  ~/.claude/backups/*
  ~/.claude/cache/*
  ~/.claude/file-history/*
  ~/.claude/logs/*
  ~/.claude/paste-cache/*
  ~/.claude/scratch/*
  ~/.claude/security/log.txt*
  ~/.claude/security/security_warnings_state_*
  ~/.claude/session-env/*
  ~/.claude/sessions/*
  ~/.claude/shell-snapshots/*
  ~/.claude/history.jsonl
  /tmp/claude-501
)
while IFS= read -r -d '' path; do
  targets+=("$path")
done < <(find ~/.claude/projects -mindepth 2 -maxdepth 2 ! -name memory -print0)

if [[ "$dry_run" == true ]]; then
  for path in "${targets[@]}"; do
    [[ -e "$path" ]] && printf 'would remove: %s\n' "$path"
  done
  exit 0
fi

if pgrep -x claude >/dev/null; then
  echo "Claude is running; quit all sessions first." >&2
  exit 1
fi

printf 'Do you want to purge claude cached data? (y/n): '
read -r response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
  rm -rf "${targets[@]}"
  find ~/.claude/projects -mindepth 1 -maxdepth 1 -type d -empty -delete
else
  echo "Skipping the purge command."
fi
