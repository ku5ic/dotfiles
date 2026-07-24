#!/usr/bin/env bash
# subagentStatusLine command (see claude/settings.json). Reads the per-task
# payload Claude Code pipes to stdin for each row in the agent panel and
# prints "name [status] <resolved-model> effort:<level> <ctx%>" on one line.
# Fields absent on older Claude Code versions (model/contextWindowSize below
# v2.1.205, effort below v2.1.214) are simply omitted, never erroring.

set -euo pipefail
trap 'exit 0' ERR

payload="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "subagent-statusline: jq not found"
  exit 0
fi

# One value per line via a while-read loop, not `IFS=$'\t' read`: tab is IFS
# whitespace, so `read` would collapse consecutive empty tab fields and
# silently shift every later value one slot left (see statusline.sh).
fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(
  jq -r '
    (.name // "task"),
    (.status // ""),
    (.model // ""),
    (.contextWindowSize // ""),
    (.tokenCount // ""),
    (.effort // "")
  ' <<<"$payload"
)
# Empty or invalid-JSON stdin makes jq exit non-zero with no stdout, leaving
# fields short; pad to the 6 values above so indexing below can't hit
# `set -u`'s unbound-variable error (which bypasses the ERR trap).
while ((${#fields[@]} < 6)); do fields+=(""); done
name="${fields[0]}"
status="${fields[1]}"
model="${fields[2]}"
context_window_size="${fields[3]}"
token_count="${fields[4]}"
effort="${fields[5]}"

line="$name"
[[ -n "$status" ]] && line="$line [$status]"
[[ -n "$model" ]] && line="$line $model"
[[ -n "$effort" ]] && line="$line effort:${effort}"
if [[ -n "$context_window_size" && -n "$token_count" && "$context_window_size" != "0" ]]; then
  ctx_pct=$((token_count * 100 / context_window_size))
  line="$line ${ctx_pct}%"
fi

printf '%s\n' "$line"
