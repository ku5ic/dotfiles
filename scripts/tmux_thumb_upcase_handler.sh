#!/usr/bin/env bash
# tmux-thumbs upcase handler.
# Routes the captured target through macOS `open`, letting Launch Services
# pick the registered handler (browser for URLs, default app per file UTI).

notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"tmux-thumbs\"" 2>/dev/null || true
}

target="${1:-}"
if [ -z "$target" ]; then
  notify "empty target"
  exit 1
fi

# URLs and other schemes go straight to Launch Services.
case "$target" in
  *://*|mailto:*|file:*)
    /usr/bin/open "$target"
    exit $?
    ;;
esac

# Expand a leading ~ or ~user manually. Bash only expands tildes in unquoted
# tokens at command position, not inside quoted variable values, so the raw
# captured string `~/foo` would otherwise be checked as a literal path.
expand_tilde() {
  local s="$1"
  # shellcheck disable=SC2088  # case patterns; literal tilde is intentional
  case "$s" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s\n' "$HOME/${s#"~/"}"
      ;;
    "~"[!/]*/*)
      local rest="${s#"~"}"
      local user="${rest%%/*}"
      local tail="${rest#*/}"
      local home
      home="$(/usr/bin/dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
      if [ -n "$home" ]; then
        printf '%s\n' "$home/$tail"
      else
        printf '%s\n' "$s"
      fi
      ;;
    *)
      printf '%s\n' "$s"
      ;;
  esac
}

target="$(expand_tilde "$target")"

pane_pwd="$(tmux display-message -p -F '#{pane_current_path}' 2>/dev/null || true)"

resolve() {
  local s="$1"
  if [ -e "$s" ]; then printf '%s\n' "$s"; return 0; fi
  if [ -n "$pane_pwd" ] && [ -e "$pane_pwd/$s" ]; then printf '%s\n' "$pane_pwd/$s"; return 0; fi
  return 1
}

resolved=""
if resolved="$(resolve "$target")"; then
  :
elif [[ "$target" =~ ^(.+):[0-9]+(:[0-9]+)?$ ]]; then
  stripped="${BASH_REMATCH[1]}"
  if resolved="$(resolve "$stripped")"; then :; fi
fi

if [ -n "$resolved" ]; then
  /usr/bin/open "$resolved"
  rc=$?
  [ "$rc" -ne 0 ] && notify "open failed: $resolved"
  exit "$rc"
fi

/usr/bin/open "$target"
rc=$?
[ "$rc" -ne 0 ] && notify "could not resolve: $target"
exit "$rc"
