#!/usr/bin/env bash
set -euo pipefail

session="${1:-}"
[[ -z "$session" ]] && exit 0

tmux list-windows -t "$session" -F "#{session_name}:#{window_index} #{window_layout}" 2>/dev/null |
  while IFS=' ' read -r target layout; do
    # #{window_layout} is the raw checksum-prefixed string, e.g. "91aa,200x58,0,0[...]".
    # Outer "[...]" -> horizontal split (main-horizontal); outer "{...}" -> vertical split.
    if [[ "$layout" == *"["* ]]; then
      tmux select-layout -t "$target" main-horizontal 2>/dev/null || true
    fi
  done
