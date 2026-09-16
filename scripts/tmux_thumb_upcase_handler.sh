#!/usr/bin/env bash
set -euo pipefail

# tmux-thumbs handler.
#
# Default mode routes the captured target through macOS `open`, letting Launch
# Services pick the registered handler (browser for URLs, default app per file
# UTI).
#
# `--print` mode normalizes the target and writes it to stdout with no trailing
# newline, for the lowercase-hint copy path to pipe into pbcopy. It lives here
# rather than in its own script so the punctuation stripping below has one
# definition shared by both hint paths.

notify() {
  /usr/bin/osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "tmux-thumbs"' \
    -e 'end run' \
    -- "$1" 2>/dev/null || true
}

# Every caller is terminal, so this exits rather than returning. Capturing rc
# via `|| rc=$?` is what keeps `set -e` from killing us before the notify.
# TMUX_THUMB_DRY_RUN prints the target instead; /usr/bin/open is hardcoded and
# unstubbable, so the bats suite needs the seam.
launch() {
  local target="$1" failure="$2" rc=0
  if [ -n "${TMUX_THUMB_DRY_RUN:-}" ]; then
    printf '%s\n' "$target"
    exit 0
  fi
  /usr/bin/open "$target" || rc=$?
  [ "$rc" -eq 0 ] || notify "$failure: $target"
  exit "$rc"
}

closer_is_balanced() {
  local s="$1" open="$2" close="$3" opens closes
  opens="${s//[^"$open"]/}"
  closes="${s//[^"$close"]/}"
  [ "${#opens}" -ge "${#closes}" ]
}

# tmux-thumbs hands over whatever its regex matched on screen, so a target
# lifted from prose keeps the surrounding punctuation: `(see src/foo.ts)`,
# `https://example.com.`, `"~/notes.md",`.
#
# Leading strip runs first on purpose. Trailing `)` is kept when it closes an
# opener still present in the string, so `/wiki/Foo_(disambiguation)` survives;
# stripping the leading `(` first is what lets `(src/foo.ts)` shed both.
# Leading `.` is never stripped: `.zshrc` and `./foo` are real paths.
strip_wrapping_punct() {
  local s="$1" head tail

  while [ -n "$s" ]; do
    head="${s:0:1}"
    case "$head" in
    '(' | '[' | '{' | '<' | '"' | "'" | '`')
      s="${s#?}"
      ;;
    *)
      break
      ;;
    esac
  done

  while [ -n "$s" ]; do
    tail="${s: -1}"
    case "$tail" in
    '.' | ',' | ';' | ':' | '!' | '?' | '>' | '"' | "'" | '`')
      s="${s%?}"
      ;;
    ')')
      if closer_is_balanced "$s" '(' ')'; then break; fi
      s="${s%?}"
      ;;
    ']')
      if closer_is_balanced "$s" '[' ']'; then break; fi
      s="${s%?}"
      ;;
    '}')
      if closer_is_balanced "$s" '{' '}'; then break; fi
      s="${s%?}"
      ;;
    *)
      break
      ;;
    esac
  done

  printf '%s\n' "$s"
}

mode="open"
if [ "${1:-}" = "--print" ]; then
  mode="print"
  shift
fi

target="${1:-}"
if [ -z "$target" ]; then
  if [ "$mode" = "open" ]; then
    notify "empty target"
  fi
  exit 1
fi

trimmed="$(strip_wrapping_punct "$target")"

if [ "$mode" = "print" ]; then
  # A capture that is punctuation all the way down trims to nothing. Copying
  # that would silently clobber the clipboard, so hand back the raw match.
  if [ -n "$trimmed" ]; then
    printf '%s' "$trimmed"
  else
    printf '%s' "$target"
  fi
  exit 0
fi

if [ -z "$trimmed" ]; then
  notify "empty target"
  exit 1
fi

# URLs and other schemes go straight to Launch Services.
case "$trimmed" in
*://* | mailto:* | file:*)
  launch "$trimmed" "open failed"
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

pane_pwd="$(tmux display-message -p -F '#{pane_current_path}' 2>/dev/null || true)"

resolve() {
  local s="$1"
  if [ -e "$s" ]; then
    printf '%s\n' "$s"
    return 0
  fi
  if [ -n "$pane_pwd" ] && [ -e "$pane_pwd/$s" ]; then
    printf '%s\n' "$pane_pwd/$s"
    return 0
  fi
  return 1
}

# Raw before trimmed: a file whose name genuinely ends in punctuation still
# wins over the stripped interpretation of the same string.
resolved=""
for candidate in "$target" "$trimmed"; do
  expanded="$(expand_tilde "$candidate")"
  if resolved="$(resolve "$expanded")"; then
    break
  fi
  if [[ "$expanded" =~ ^(.+):[0-9]+(:[0-9]+)?$ ]]; then
    if resolved="$(resolve "${BASH_REMATCH[1]}")"; then
      break
    fi
  fi
done

if [ -n "$resolved" ]; then
  launch "$resolved" "open failed"
fi

# Nothing on disk matched, so a dotted host with a real TLD is a URL wearing no
# scheme: `github.com/foo/bar`, `www.example.com`, `docs.rs/serde`.
# Assume https. Checked after file resolution on purpose, so an actual file
# named `foo.com` still beats the domain reading of the same string.
host_label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
scheme_less_url="^$host_label(\.$host_label)*\.[A-Za-z]{2,}(:[0-9]+)?([/?#].*)?$"
if [[ "$trimmed" =~ $scheme_less_url ]]; then
  launch "https://$trimmed" "open failed"
fi

launch "$target" "could not resolve"
