#!/usr/bin/env bash
# Stop hook: enforces two things CLAUDE.md can only ask for, in chat output -
# the tiered prose ceiling and the banned AI-tell opener/closer phrases.
#
# Tiers (CLAUDE.md ## Length): short is default. A user message that IS a
# mode-switch command ("normal mode" etc, the whole trimmed message) sets the
# sticky tier, last match wins; per-message triggers lift one tier without
# changing it. Long has no ceiling. Tier is derived from the transcript every
# run - no state file.
#
# exit 0 allows the response; exit 2 blocks (stderr fed back for a retry).
# Inert unless CLAUDE_GUARD_RESPONSE=1. Loop safety: stop_hook_active is true
# on the retry after a block, so the second pass always allows (one retry max).
#
# Tunables (env): CLAUDE_GUARD_RESPONSE, CLAUDE_GUARD_RESPONSE_MAX_LINES
# (short ceiling, default 12), CLAUDE_GUARD_RESPONSE_MAX_LINES_NORMAL
# (normal ceiling, default 40).

HOOK_NAME="guard-response.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

[[ "${CLAUDE_GUARD_RESPONSE:-0}" == "1" ]] || exit 0

[[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
[[ -n "$transcript" && -r "$transcript" ]] || exit 0

# Last real user prompt. Skips tool_result turns (no text) and isMeta turns
# (Claude Code's marker for injected content, e.g. agent relays), plus the
# skill's expanded body prefixed "Base directory for this skill:" - isMeta on
# some invocation shapes but not others, so both filters are needed.
last_user="$(jq -rs '
  [.[] | select(.type == "user") | select(.isMeta != true) | .message.content
   | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
   | select(length > 0)
   | select(startswith("Base directory for this skill:") | not)] | last // ""' "$transcript" 2>/dev/null || true)"

# Slash commands define their own output shape; no ceiling. Covers a bare
# "/command" prompt and the "<command-message>...<command-name>..." wrapper
# Claude Code emits - anchored to message start so a reply merely quoting
# the tag isn't exempted.
if [[ "$last_user" == /* || "$last_user" == '<command-message>'* || "$last_user" == '<command-name>'* ]]; then
  exit 0
fi

# Sticky tier: a message only sets the tier when it IS a mode-switch command
# (the whole trimmed message), not when it merely mentions one - otherwise
# quoting the mode words (this file's own header, CLAUDE.md ## Length) would
# pin the tier. Last match wins. Default short.
tier="short"
while IFS= read -r _line; do
  _msg="$(printf '%s' "$_line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  case "${_msg,,}" in
  "long mode" | "long mode." | "switch to long mode") tier="long" ;;
  "normal mode" | "normal mode." | "switch to normal mode") tier="normal" ;;
  "short mode" | "short mode." | "terse mode" | "switch to short mode") tier="short" ;;
  esac
done < <(jq -rs '
  .[] | select(.type == "user") | select(.isMeta != true) | .message.content
  | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join(" ")) end
  | select(length > 0) | gsub("\n"; " ")' "$transcript" 2>/dev/null)

# Per-message lift, this reply only; a trigger never downgrades a sticky tier.
if printf '%s' "$last_user" | grep -qiE '(--full|\bin detail\b|walk me through|long version)'; then
  tier="long"
elif printf '%s' "$last_user" | grep -qiE '(\bexplain\b|\bwhy\b|how come|tradeoffs?|\breport\b|\breview\b|\baudit\b|\bwrite\b)'; then
  [[ "$tier" == "short" ]] && tier="normal"
fi

# Final assistant text of the turn.
last_assistant="$(jq -rs '
  [.[] | select(.type == "assistant") | .message.content
   | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
   | select(length > 0)] | last // ""' "$transcript" 2>/dev/null || true)"
[[ -z "$last_assistant" ]] && exit 0

# Same set and anchoring as guard-tone.sh; extends the block from files to chat.
if printf '%s' "$last_assistant" | grep -qiE "$BANNED_TELL_REGEX"; then
  log_block "chat-ai-tell" "stop-hook"
  echo "The response opens or closes with a banned AI-tell phrase. Rewrite without it; do not add anything else." >&2
  exit 2
fi

# Long tier: tells already checked above, no line ceiling.
[[ "$tier" == "long" ]] && exit 0

# Ceilings are looser than CLAUDE.md's instructions on purpose: the hook
# catches walls of text, the instruction shapes everything below them.
prose_lines="$(printf '%s\n' "$last_assistant" | awk '/^```/{f=!f; next} !f && NF {n++} END{print n+0}')"
if [[ "$tier" == "normal" ]]; then
  max="${CLAUDE_GUARD_RESPONSE_MAX_LINES_NORMAL:-40}"
else
  max="${CLAUDE_GUARD_RESPONSE_MAX_LINES:-12}"
fi
if ((prose_lines > max)); then
  log_block "chat-over-length" "tier=${tier} lines=${prose_lines}"
  echo "The response is ${prose_lines} prose lines; the ${tier}-tier ceiling is ${max}. Answer again shorter: lead with the answer, cut narration and recap, keep code blocks intact. The user lifts the ceiling with 'normal mode' / 'long mode' or an explicit ask to explain." >&2
  exit 2
fi

exit 0
