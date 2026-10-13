#!/usr/bin/env bash
set -euo pipefail

session="${1:-}"
[[ -z "$session" ]] && exit 0

tmux list-windows -t "$session" -F "#{session_name}:#{window_index} #{window_layout}" 2>/dev/null |
  while IFS=' ' read -r target layout; do
    # tmux 3.8+ #{window_layout} is JSON; a root "t":"v" node means panes stacked top/bottom (main-horizontal).
    if [[ "$layout" == *'"L":{"t":"v"'* ]]; then
      tmux select-layout -t "$target" main-horizontal 2>/dev/null || true
    fi
  done
