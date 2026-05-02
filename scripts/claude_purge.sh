#!/usr/bin/bin/env bash
set -euo pipefail


printf 'Do you want to purge claude cached data? (y/n): '
read -r response

if [[ "$response" != "y" && "$response" != "Y" ]]; then
  rm -rf ~/.claude/cache/*
  rm -rf ~/.claude/file-history/*
  rm -rf ~/.claude/logs/*
  rm -rf ~/.claude/paste-cache/*
  rm -rf ~/.claude/plans/*
  rm -rf ~/.claude/projects/*
  rm -rf ~/.claude/scratch/*
  rm -rf ~/.claude/session-env/*
  rm -rf ~/.claude/sessions/*
  rm -rf ~/.claude/tasks/*
  rm ~/.claude/history.jsonl
  rm ~/.claude/stats-cache.json
else
  echo "Skipping the purge command."
fi

