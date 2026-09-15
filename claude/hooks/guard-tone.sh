#!/usr/bin/env bash
# PreToolUse hook: inspects content being written/edited and blocks (1)
# banned AI-tell opener/closer phrases (CLAUDE.md Voice section) and (2)
# unchunked walls of text in write-* deliverables (rules/output.md section 1).
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

# True only for Write's flat content, which carries the whole file and so can
# carry a wall the file already had. Edit and MultiEdit carry only the
# replacement text, where every line is by definition newly added.
is_full_file_write() {
  [[ "$(printf '%s' "$payload" | jq -r 'if .tool_input.content != null then "y" else "n" end')" == "y" ]]
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
  # Every prose file, not just the write-* deliverables: rules/output.md
  # section 1 applies wherever the reader reads, scratch reports and rule
  # files included. Extension-gated because longest_prose_run counts any
  # non-list, non-heading line - in a .ts file every statement would read as
  # a wall, so source must never reach it.
  #
  # Known gap: on Edit/MultiEdit the content is a fragment, so a replacement
  # landing wholly inside a fenced code block has no opening fence to detect
  # and its lines count as prose. Rare enough to accept; chunk or rewrite the
  # surrounding block if it trips.
  case "$path" in
  *.md | *.mdx | *.markdown | *.txt)
    if [[ -n "$content" ]]; then
      run="$(longest_prose_run "$content")"
      if ((run > 4)); then
        # Ratchet, not a gate: a whole-file Write over existing documentation
        # carries walls the file already had, which this change did not write.
        # Block only when the worst run is new or got worse, so legacy docs
        # stay editable while nothing regresses. Edit/MultiEdit take baseline
        # 0 - their content is only the new text, so every line counts.
        local baseline=0
        if is_full_file_write && [[ -f "$path" ]]; then
          baseline="$(longest_prose_run "$(cat -- "$path")")"
        fi
        if ((run > baseline)); then
          block "unchunked wall of text (${run} consecutive prose lines, was ${baseline}). rules/output.md section 1: break into short paragraphs, headers, or a list." "wall-of-text"
        fi
      fi
    fi
    ;;
  esac

  # These document or plan around the banned phrases as literal examples and
  # must be able to quote them without tripping the block.
  case "$path" in
  */claude/CLAUDE.md | */.claude/CLAUDE.md | */claude/rules/*.md | */.claude/rules/*.md | \
    */claude/skills/*.md | */.claude/skills/*.md | */claude/agents/*.md | */.claude/agents/*.md | \
    */.claude/scratch/* | */scratch/*) return 0 ;;
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
