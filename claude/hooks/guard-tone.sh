#!/usr/bin/env bash
# ~/.claude/hooks/guard-tone.sh
# PreToolUse hook. Reads the tool call JSON from stdin, inspects the content
# being written or edited, and blocks two things:
#   1. Distinctive AI-tell opener/closer phrases named in CLAUDE.md's Voice
#      "banned openers and closers" bullet.
#   2. Unchunked walls of text in write-* external-communication deliverables,
#      per rules/adhd-output.md rule 8.
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

# Override _lib.sh block() to show the matched phrase/path for context.
block() {
  log_block "${2:-unknown}" "$path"
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  exit 2
}

# Wall-of-text check for write-* deliverables (scratch-conventions.md kind
# prefixes). Runs before the scratch exemption below on purpose: that
# exemption is for the banned-phrase check only -- audit/planning notes in
# scratch legitimately quote those phrases, but a PR/devnote/explainer/etc
# deliverable never needs to, and never gets a structure pass either way.
case "$(basename -- "$path")" in
pr-* | explainer-* | release-notes-* | review-comment-* | stakeholder-*)
  if [[ -n "$content" ]]; then
    run="$(longest_prose_run "$content")"
    if ((run > 4)); then
      block "unchunked wall of text (${run} consecutive prose lines). rules/adhd-output.md rule 8: break into short paragraphs, headers, or a list." "wall-of-text"
    fi
  fi
  ;;
esac

# Files that document or plan around the banned phrases as literal examples
# and must be able to quote them without tripping the block.
case "$path" in
*/claude/CLAUDE.md | */.claude/CLAUDE.md | */claude/rules/*.md | */.claude/rules/*.md | \
  */claude/skills/*.md | */.claude/skills/*.md | */.claude/scratch/* | */scratch/*) exit 0 ;;
esac

[[ -z "$content" ]] && exit 0

# Anchored to line start so legitimate mid-sentence uses ("this is certainly
# true", "of course there are tradeoffs") are not flagged -- only the
# opener/closer position these phrases actually appear in as filler.
matched="$(printf '%s' "$content" | grep -m1 -ioE "$BANNED_TELL_REGEX" || true)"

if [[ -n "$matched" ]]; then
  block "AI-tell opener/closer phrase found: '${matched}'. Remove it and retry." "ai-tell-phrase"
fi

exit 0
