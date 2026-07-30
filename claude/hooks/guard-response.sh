#!/usr/bin/env bash
# ~/.claude/hooks/guard-response.sh
# Stop hook. Reads the transcript, inspects the final assistant message, and
# enforces two things CLAUDE.md can only ask for: the tiered prose ceiling
# and the banned AI-tell opener/closer phrases, in chat output.
#
# Tiers (see CLAUDE.md ## Length): short is the default; a user message that
# IS a mode-switch command - "normal mode" / "long mode" / "short mode" /
# "switch to <tier> mode", the whole trimmed message, nothing else in it -
# sets the sticky tier (last matching message wins). Per-message triggers
# lift the current reply one tier without changing the sticky mode. Long has
# no ceiling. The tier is derived from the transcript on every run - no
# state file.
#
# Contract:
#   exit 0 -> allow the response to stand
#   exit 2 -> block; stderr is fed back to Claude, which answers again
#
# Experiment gate: inert unless CLAUDE_GUARD_RESPONSE=1 (settings.json "env"
# block). Loop safety: stop_hook_active is true on the retry that follows a
# stop-hook block, so the second pass always allows. One retry max.
#
# Tunables (env):
#   CLAUDE_GUARD_RESPONSE                    1 to enable
#   CLAUDE_GUARD_RESPONSE_MAX_LINES          short ceiling, default 12
#   CLAUDE_GUARD_RESPONSE_MAX_LINES_NORMAL   normal ceiling, default 40

HOOK_NAME="guard-response.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

[[ "${CLAUDE_GUARD_RESPONSE:-0}" == "1" ]] || exit 0

[[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
[[ -n "$transcript" && -r "$transcript" ]] || exit 0

# Last real user prompt. tool_result turns carry no text and are skipped; so
# is any isMeta turn - Claude Code's own marker for injected content the user
# did not type, such as an agent-to-agent relay message - and the skill's own
# expanded body, injected as a synthetic turn prefixed "Base directory for
# this skill:" (isMeta on some invocation shapes, not on others, so both
# filters are needed). Without them, one of those is frequently the text this
# variable picks up instead of what was typed.
last_user="$(jq -rs '
  [.[] | select(.type == "user") | select(.isMeta != true) | .message.content
   | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
   | select(length > 0)
   | select(startswith("Base directory for this skill:") | not)] | last // ""' "$transcript" 2>/dev/null || true)"

# Slash commands: the skill defines its own output shape; no ceiling. Covers
# a bare "/command" prompt and the "<command-message>...</command-message>
# <command-name>...</command-name>" wrapper Claude Code emits for commands
# with a defined display message - anchored to the start of the message, not
# a substring match, so a reply that merely quotes the tag is not exempted.
if [[ "$last_user" == /* || "$last_user" == '<command-message>'* || "$last_user" == '<command-name>'* ]]; then
  exit 0
fi

# Sticky tier: scan every user message oldest-to-newest; a message only sets
# the tier when it IS a mode-switch command (the whole trimmed message, case
# insensitive), not when it merely mentions one - otherwise quoting or
# discussing the mode words (this file's own header, CLAUDE.md's ## Length
# section) would pin the tier. The last matching message wins; since a single
# message can equal only one of these phrases, this also settles same-message
# ambiguity, which the old substring-grepped if/elif resolved by precedence
# rather than recency. Default short.
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

# Per-message lift for this reply only. Long triggers win over normal; a
# trigger never downgrades a sticky tier.
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

# Banned openers/closers, line-anchored, every tier. Same set and anchoring
# as guard-tone.sh; this extends the block from written files to chat.
if printf '%s' "$last_assistant" | grep -qiE "$BANNED_TELL_REGEX"; then
  log_block "chat-ai-tell" "stop-hook"
  echo "The response opens or closes with a banned AI-tell phrase. Rewrite without it; do not add anything else." >&2
  exit 2
fi

# Long tier: tells checked above, no line ceiling.
[[ "$tier" == "long" ]] && exit 0

# Prose ceiling for short/normal: non-empty lines outside fenced code blocks.
# Ceilings are looser than the CLAUDE.md instructions on purpose: the hook
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
