#!/usr/bin/env bash
# Session/window/pane picker for tmux: a single fzf list you drill into with
# the right arrow (like tmux's own choose-tree) and back out of with left,
# previewing the highlighted target's live content at every level. Enter
# switches immediately at whatever level the cursor sits on - `switch-client
# -t` accepts a session, session:window, or session:window.pane target
# directly, so no branching is needed on accept. Bound to prefix + s in
# .tmux.conf, run inside a display-popup.
set -euo pipefail

self="$0"

list_sessions() {
  local current
  current="$(tmux display-message -p '#S')"
  tmux list-sessions -F '#{session_name}' | grep -vxF "$current" | while IFS= read -r s; do
    printf '%s\t  %s\n' "$s" "$s"
  done
}

list_windows() {
  local session="$1"
  tmux list-windows -t "$session" -F "${session}:#{window_index}"$'\t'"    #{window_index}: #{window_name}"
}

list_panes() {
  local session_window="$1"
  tmux list-panes -t "$session_window" -F "${session_window}.#{pane_index}"$'\t'"      #{pane_index}: #{pane_current_command} (#{pane_current_path})"
}

case "${1:-}" in
--sessions)
  list_sessions
  exit 0
  ;;
--children)
  target="$2"
  if [[ "$target" == *.* ]]; then
    list_panes "${target%.*}" # already at pane level, nothing further to expand
  elif [[ "$target" == *:* ]]; then
    list_panes "$target"
  else
    list_windows "$target"
  fi
  exit 0
  ;;
--parent)
  target="$2"
  if [[ "$target" == *.* ]]; then
    list_windows "${target%%:*}"
  else
    list_sessions # already at session level (or window level) - back to top
  fi
  exit 0
  ;;
esac

selection="$(list_sessions | fzf --reverse \
  --delimiter=$'\t' --with-nth=2 \
  --header='enter: switch  ->: expand  <-: collapse  ctrl-/: bigger preview' \
  --preview 'tmux capture-pane -ep -t {1}' \
  --preview-window=down,70%,nowrap \
  --bind 'ctrl-/:change-preview-window(down,90%,nowrap|down,70%,nowrap)' \
  --bind "right:reload($self --children {1})" \
  --bind "left:reload($self --parent {1})")" || exit 0

target="${selection%%$'\t'*}"
tmux switch-client -t "$target"
