#!/usr/bin/env bash
# PreToolUse hook: inspects content being written/edited and blocks (1)
# banned AI-tell opener/closer phrases (CLAUDE.md Voice section) and (2)
# unchunked walls of text in write-* deliverables (adhd-output.md rule 8).
# exit 2 blocks; any other nonzero exit is a soft failure. Callable
# standalone or sourced by guard-dispatch.sh for the Edit|Write|MultiEdit path.

HOOK_NAME="guard-tone.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

# Handles all three tool shapes: Write's flat content, Edit's new_string,
# or MultiEdit's edits array (each entry's new_string joined).
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

run_guard_tone() {
  # See run_guard_edit.sh - same HOOK_NAME shadowing need.
  local HOOK_NAME="guard-tone.sh"
  path="$(extract_path)"
  content="$(extract_content)"

  block() {
    echo "Blocked by ${HOOK_NAME}: $1" >&2
    exit 2
  }

  # Runs before the scratch exemption below on purpose: that exemption is for
  # the banned-phrase check only - audit/planning notes in scratch legitimately
  # quote those phrases, but a deliverable never needs to and never skips
  # the structure pass.
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

  # These document or plan around the banned phrases as literal examples and
  # must be able to quote them without tripping the block.
  case "$path" in
  */claude/CLAUDE.md | */.claude/CLAUDE.md | */claude/rules/*.md | */.claude/rules/*.md | \
    */claude/skills/*.md | */.claude/skills/*.md | */.claude/scratch/* | */scratch/*) return 0 ;;
  esac

  [[ -z "$content" ]] && return 0

  # Anchored to line start so mid-sentence uses ("this is certainly true")
  # aren't flagged - only the opener/closer position these phrases fill.
  matched="$(printf '%s' "$content" | grep -m1 -ioE "$BANNED_TELL_REGEX" || true)"

  if [[ -n "$matched" ]]; then
    block "AI-tell opener/closer phrase found: '${matched}'. Remove it and retry." "ai-tell-phrase"
  fi

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  read_payload
  require_jq
  run_guard_tone
fi
