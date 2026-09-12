#!/usr/bin/env bash
# Stop hook: blocks the final chat reply on two things the i-have-adhd
# plugin can only ask for - a banned AI-tell opener/closer phrase, and an
# unchunked wall of text (more than 4 consecutive prose lines outside a
# fence). Reply length is the plugin's job, not this hook's: a length
# ceiling forces a full regeneration, which is the slowest possible outcome
# for the reader.
#
# exit 0 allows the response; exit 2 blocks (stderr fed back for a retry).
# Inert unless CLAUDE_GUARD_RESPONSE=1 (set in settings.json). Loop safety:
# stop_hook_active is true on the retry after a block, so the second pass
# always allows (one retry max).

HOOK_NAME="guard-response.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

[[ "${CLAUDE_GUARD_RESPONSE:-0}" == "1" ]] || exit 0

[[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
[[ -n "$transcript" && -r "$transcript" ]] || exit 0

# Final assistant text of the turn. Content is either a plain string or an
# array of typed blocks; only text blocks count.
last_assistant="$(jq -rs '
  [.[] | select(.type == "assistant") | .message.content
   | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
   | select(length > 0)] | last // ""' "$transcript" 2>/dev/null || true)"
[[ -z "$last_assistant" ]] && exit 0

# Same set and anchoring as guard-tone.sh; extends the block from files to chat.
if printf '%s' "$last_assistant" | grep -qiE "$BANNED_TELL_REGEX"; then
  echo "The response opens or closes with a banned AI-tell phrase. Rewrite without it; do not add anything else." >&2
  exit 2
fi

run="$(longest_prose_run "$last_assistant")"
if ((run > 4)); then
  echo "The response has an unchunked wall of text (${run} consecutive prose lines). Break it into short paragraphs separated by blank lines, or a list. Keep the content; change only the shape." >&2
  exit 2
fi

exit 0
