#!/usr/bin/env bash
# ~/.claude/hooks/guard-tone.sh
# PreToolUse hook. Reads the tool call JSON from stdin, inspects the content
# being written or edited, and blocks distinctive AI-tell opener/closer
# phrases named in CLAUDE.md's Output Rules "No AI tells" bullet.
#
# Contract:
#   exit 0 -> allow the tool call
#   exit 2 -> block the tool call. stderr is shown to Claude as the reason.
# Any other non-zero exit is treated as a soft failure and does not block.

HOOK_NAME="guard-tone.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"

# Files that document or plan around the banned phrases as literal examples
# and must be able to quote them without tripping the block.
case "$path" in
*/claude/CLAUDE.md | */.claude/CLAUDE.md | */claude/rules/*.md | */.claude/rules/*.md | \
  */claude/skills/*.md | */.claude/skills/*.md | */.claude/scratch/*) exit 0 ;;
esac

# Extracts the text being written, regardless of which of the three tool
# shapes sent it: Write's flat content, Edit's new_string, or MultiEdit's
# edits array (each entry's new_string joined).
extract_content() {
  printf '%s' "$payload" | jq -r '
    if (.tool_input.content != null) then .tool_input.content
    elif (.tool_input.new_string != null) then .tool_input.new_string
    elif (.tool_input.edits != null) then
      ([.tool_input.edits[] | .new_string // ""] | join("\n"))
    else ""
    end
  '
}

content="$(extract_content)"
[[ -z "$content" ]] && exit 0

# Override _lib.sh block() to show the matched phrase for context.
block() {
  log_block "${2:-unknown}" "$path"
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  exit 2
}

# Anchored to line start so legitimate mid-sentence uses ("this is certainly
# true", "of course there are tradeoffs") are not flagged -- only the
# opener/closer position these phrases actually appear in as filler.
matched="$(printf '%s' "$content" | grep -m1 -ioE \
  '^(certainly|absolutely|of course|sure)[!,.]|^(great question|i hope this helps|let.s dive in|happy to help|in conclusion)([[:space:]]|[!,.]|$)' ||
  true)"

if [[ -n "$matched" ]]; then
  block "AI-tell opener/closer phrase found: '${matched}'. Remove it and retry." "ai-tell-phrase"
fi

exit 0
