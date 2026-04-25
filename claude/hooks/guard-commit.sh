#!/usr/bin/env bash
# PreToolUse hook for Bash. Inspects git commit commands for AI signatures.
set -euo pipefail
trap 'echo "guard-commit: unexpected error, failing open" >&2; exit 0' ERR

payload="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"

[[ "$cmd" =~ git[[:space:]]+commit ]] || exit 0

msg_dq="$(printf '%s' "$cmd" | grep -oE '(-m|--message=?)[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"/\1/' || true)"
msg_sq="$(printf '%s' "$cmd" | grep -oE "(-m|--message=?)[[:space:]]*'[^']*'" | sed -E "s/.*'([^']*)'/\1/" || true)"
msg="${msg_dq}${msg_sq}"

[[ -z "$msg" ]] && exit 0

block() {
  echo "Blocked by guard-commit.sh: $1" >&2
  exit 2
}

if echo "$msg" | grep -qiE 'Co-Authored-By:[[:space:]]*Claude|Generated[[:space:]]+(by|with)[[:space:]]+Claude|🤖[[:space:]]*Generated'; then
  block "AI signature in commit message"
fi

subject="$(echo "$msg" | head -1)"
if echo "$subject" | grep -qiE '^(feat|fix|chore|refactor|docs|test|perf|build|ci|style)?:?[[:space:]]*(certainly|here is|i have|let me|in this commit|this commit)'; then
  block "AI-tell phrasing in commit subject"
fi

exit 0
