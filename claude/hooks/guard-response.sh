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
# Slash commands are NOT exempt from the ceiling. Only write-commit,
# write-devnote, and write-explainer are, because terminal output is their
# deliverable; every other skill writes to a file and summarizes.
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

# Last real user prompt. Skips tool_result turns (no text) and isMeta turns
# (Claude Code's marker for injected content, e.g. agent relays), plus the
# skill's expanded body prefixed "Base directory for this skill:" - isMeta on
# some invocation shapes but not others, so both filters are needed.
last_user="$(jq -rs '
  [.[] | select(.type == "user") | select(.isMeta != true) | .message.content
   | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
   | select(length > 0)
   | select(startswith("Base directory for this skill:") | not)] | last // ""' "$transcript" 2>/dev/null || true)"

# Slash-command name, if this turn is one. Covers a bare "/command" prompt and
# the "<command-message>...<command-name>..." wrapper Claude Code emits -
# anchored to message start so a reply merely quoting the tag isn't matched.
cmd_name=""
if [[ "$last_user" == /* ]]; then
  cmd_name="${last_user#/}"
  cmd_name="${cmd_name%%[[:space:]]*}"
elif [[ "$last_user" == '<command-message>'* || "$last_user" == '<command-name>'* ]]; then
  cmd_name="$(printf '%s' "$last_user" | sed -n 's|.*<command-name>/\{0,1\}\([^<]*\)</command-name>.*|\1|p' | head -1)"
  [[ -z "$cmd_name" ]] &&
    cmd_name="$(printf '%s' "$last_user" | sed -n 's|.*<command-message>\([^<]*\)</command-message>.*|\1|p' | head -1)"
fi

# Only the commands whose deliverable IS terminal output are exempt from the
# ceiling (rules/output.md names these three). Every other skill writes
# its deliverable to a file and reports a summary, so the ceiling applies.
# This exempts length only - the banned-tell check below still runs, since a
# long deliverable is no licence for an AI-tell opener.
no_ceiling=0
case "$cmd_name" in
write-commit | write-devnote | write-explainer) no_ceiling=1 ;;
esac

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
# A slash command lifts nothing: its own name ("/flow-review", "/write-commit")
# would otherwise match the trigger vocabulary and buy a ceiling the user never
# asked for.
trigger_text="$last_user"
[[ -n "$cmd_name" ]] && trigger_text=""

# The normal-tier lift is anchored to the start of the message (bare, or after
# a short polite prefix): the user asking "explain X" wants prose, whereas the
# same word buried in "I fixed the thing you flagged in the review" does not.
# Long-tier triggers stay unanchored - "--full" and "long version" are explicit
# enough that an incidental match is not a real risk.
if printf '%s' "$trigger_text" | grep -qiE '(--full|\bin detail\b|walk me through|long version)'; then
  tier="long"
elif printf '%s' "$trigger_text" |
  grep -qiE '^[[:space:]]*((can|could|would)[[:space:]]+you[[:space:]]+)?(please[[:space:]]+)?(explain|why|how come|tradeoffs?|report|review|audit|write)\b'; then
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
  echo "The response opens or closes with a banned AI-tell phrase. Rewrite without it; do not add anything else." >&2
  exit 2
fi

# Tells are checked above; past this point only the line ceiling remains.
((no_ceiling)) && exit 0
[[ "$tier" == "long" ]] && exit 0

# Ceilings are looser than CLAUDE.md's instructions on purpose: the hook
# catches walls of text, the instruction shapes everything below them.
prose_lines="$(printf '%s\n' "$last_assistant" | awk '/^```/{f=!f; next} !f && NF {n++} END{print n+0}')"
if [[ "$tier" == "normal" ]]; then
  max=40
else
  max=12
fi
if ((prose_lines > max)); then
  echo "The response is ${prose_lines} prose lines; the ${tier}-tier ceiling is ${max}. Answer again shorter: lead with the answer, cut narration and recap, keep code blocks intact. The user lifts the ceiling with 'normal mode' / 'long mode' or an explicit ask to explain." >&2
  exit 2
fi

exit 0
