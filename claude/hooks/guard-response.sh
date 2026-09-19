#!/usr/bin/env bash
# Stop hook: blocks the final chat reply on two things the i-have-adhd
# plugin can only ask for - a banned AI-tell opener/closer phrase, and an
# unchunked wall of text (more than 4 consecutive prose lines outside a
# fence), plus a 10-line cap on a reply that names a scratch report. General
# reply length is the plugin's job, not this hook's: a ceiling there forces a
# full regeneration, which is the slowest possible outcome for the reader.
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

# Final assistant text of the turn, scoped to entries after the last user
# entry - the closing tool_result, or the prompt itself when no tool ran.
# Tool-call preambles sit before that boundary and are deliberately out of
# scope: a Stop hook fires after they have already streamed, and a block
# regenerates only the final message, so it cannot unsay a preamble. Judging
# one just rewrites a reply that was already clean.
#
# An empty read therefore means the final message has not flushed to the
# transcript yet, not that there is nothing to check - skipping is correct.
# Falling back to the last entry overall is what let a preamble be judged.
# Content is either a plain string or an array of typed blocks; only text counts.
#
# Only the transcript's tail is parsed: slurping the whole file costs time
# proportional to the session's history (38ms on a 4MB transcript, and it
# only grows) to read entries that are, by definition, at the end. A turn
# longer than the window leaves $u null, which falls back to scanning the
# window - still the final assistant message.
last_assistant="$(tail -n "${CLAUDE_TRANSCRIPT_TAIL:-400}" "$transcript" | jq -rs '
  (map(.type == "user") | rindex(true)) as $u
  | .[(($u // -1) + 1):]
  | [.[] | select(.type == "assistant") | .message.content
     | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
     | select(length > 0)] | last // ""' 2>/dev/null || true)"
[[ -z "$last_assistant" ]] && exit 0

# Same set and anchoring as guard-tone.sh; extends the block from files to chat.
# Report the phrase that matched, as guard-tone.sh does - a block naming only
# the rule sends the rewrite hunting and it lands on the wrong line.
matched="$(printf '%s' "$last_assistant" | grep -m1 -ioE "$BANNED_TELL_REGEX" || true)"
if [[ -n "$matched" ]]; then
  echo "The response contains a banned AI-tell phrase: '${matched}'. Rewrite without it; do not add anything else." >&2
  exit 2
fi

run="$(longest_prose_run "$last_assistant")"
if ((run > 4)); then
  echo "The response has an unchunked wall of text (${run} consecutive prose lines). Break it into short paragraphs separated by blank lines, or a list. Keep the content; change only the shape." >&2
  exit 2
fi

# Length ceiling, only when the reply names a scratch report: the artifact is
# the deliverable and the reply is a pointer to it. General replies stay
# uncapped - a ceiling there forces a full regeneration, the slowest possible
# outcome for the reader.
if printf '%s' "$last_assistant" | grep -qE 'scratch/[^[:space:]]+\.md'; then
  cap="${CLAUDE_REPLY_CAP_REPORT:-10}"
  lines="$(printf '%s\n' "$last_assistant" | grep -c '')"
  if ((lines > cap)); then
    echo "Reply is ${lines} lines, cap is ${cap}. A report file was written: give the path, the headline counts, and one next action. Do not restate findings the file already contains." >&2
    exit 2
  fi
fi

exit 0
