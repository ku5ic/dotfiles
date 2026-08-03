#!/usr/bin/env bats
# Tests for ~/.claude/hooks/guard-tone.sh.
#
# guard-tone.sh is a PreToolUse hook for Edit/Write/MultiEdit. It blocks two
# independent things: a banned AI-tell opener/closer phrase (CLAUDE.md Voice
# section) anywhere in written content, and an unchunked wall of text (>4
# consecutive prose lines) specifically in write-* deliverable filenames
# (pr-*, explainer-*, release-notes-*, review-comment-*, stakeholder-*).
# Each test feeds a synthetic Edit/Write/MultiEdit payload on stdin and
# asserts the exit code: 0 = allow, 2 = block.
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-tone.sh"
}

# run_guard_tone <path> <content>
# Builds a Write-shaped payload (tool_input.content) and pipes it to the hook.
run_guard_tone() {
  local path="$1" content="$2"
  jq -n --arg path "$path" --arg content "$content" \
    '{tool_input: {file_path: $path, content: $content}}' | "$HOOK"
}

# run_guard_tone_edit <path> <new_string>  Edit-shaped payload.
run_guard_tone_edit() {
  local path="$1" content="$2"
  jq -n --arg path "$path" --arg content "$content" \
    '{tool_input: {file_path: $path, new_string: $content}}' | "$HOOK"
}

# run_guard_tone_multiedit <path> <new_string...>  MultiEdit-shaped payload,
# each arg after path becomes one edits[] entry's new_string.
run_guard_tone_multiedit() {
  local path="$1"
  shift
  jq -n --arg path "$path" --args '
    {tool_input: {file_path: $path, edits: ($ARGS.positional | map({new_string: .}))}}
  ' "$@" | "$HOOK"
}

# five_line_prose builds 5 consecutive non-list, non-heading prose lines --
# one over the >4 wall-of-text threshold.
five_line_prose() {
  printf 'line one is prose.\nline two is prose.\nline three is prose.\nline four is prose.\nline five is prose.'
}

four_line_prose() {
  printf 'line one is prose.\nline two is prose.\nline three is prose.\nline four is prose.'
}

# banned-phrase checks

@test "allow: ordinary content with no banned phrase" {
  run run_guard_tone '/tmp/notes.md' 'Just a normal sentence about the fix.'
  [ "$status" -eq 0 ]
}

@test "block: banned opener 'Certainly,' at line start" {
  run run_guard_tone '/tmp/notes.md' 'Certainly, here is the answer.'
  [ "$status" -eq 2 ]
  [[ "$output" == *"ai-tell-phrase"* ]] || [[ "$output" == *"AI-tell"* ]]
}

@test "block: banned closer 'In conclusion'" {
  run run_guard_tone '/tmp/notes.md' 'In conclusion, the fix works.'
  [ "$status" -eq 2 ]
}

@test "block: banned phrase 'happy to help'" {
  run run_guard_tone '/tmp/notes.md' 'happy to help with anything else.'
  [ "$status" -eq 2 ]
}

@test "allow: banned phrase text appearing mid-sentence, not at line start" {
  run run_guard_tone '/tmp/notes.md' 'This is certainly true, and of course there are tradeoffs.'
  [ "$status" -eq 0 ]
}

@test "block message names the matched phrase" {
  run run_guard_tone '/tmp/notes.md' 'Absolutely! that will work.'
  [ "$status" -eq 2 ]
  [[ "$output" == *"Absolutely"* ]]
}

# path exemptions (banned-phrase check only)

@test "allow: banned phrase inside CLAUDE.md (documents the phrase itself)" {
  run run_guard_tone '/repo/claude/CLAUDE.md' 'Certainly, is a banned opener.'
  [ "$status" -eq 0 ]
}

@test "allow: banned phrase inside a rules/*.md file" {
  run run_guard_tone '/repo/claude/rules/voice.md' 'Certainly, and Absolutely are banned.'
  [ "$status" -eq 0 ]
}

@test "allow: banned phrase inside a skills/*.md file" {
  run run_guard_tone '/repo/claude/skills/voice-check/SKILL.md' 'Certainly, is banned.'
  [ "$status" -eq 0 ]
}

@test "allow: banned phrase inside scratch/" {
  run run_guard_tone '/repo/scratch/notes.md' 'Certainly, this is a draft quoting the phrase.'
  [ "$status" -eq 0 ]
}

@test "block: a non-exempt path still blocks even if it superficially resembles rules dir" {
  run run_guard_tone '/repo/other-rules/notes.md' 'Certainly, this should still block.'
  [ "$status" -eq 2 ]
}

# content-shape extraction: Write / Edit / MultiEdit

@test "extracts content from Edit's new_string shape" {
  run run_guard_tone_edit '/tmp/notes.md' 'Certainly, this came from new_string.'
  [ "$status" -eq 2 ]
}

@test "extracts and joins content from MultiEdit's edits array" {
  run run_guard_tone_multiedit '/tmp/notes.md' 'a harmless line' 'Certainly, this is the second edit.'
  [ "$status" -eq 2 ]
}

@test "MultiEdit with no banned phrase across any edit allows" {
  run run_guard_tone_multiedit '/tmp/notes.md' 'first edit is fine' 'second edit is also fine'
  [ "$status" -eq 0 ]
}

# empty content

@test "allow: empty content never blocks" {
  run run_guard_tone '/tmp/notes.md' ''
  [ "$status" -eq 0 ]
}

# wall-of-text check (write-* deliverables only)

@test "block: pr- deliverable with 5 consecutive prose lines" {
  run run_guard_tone "/tmp/pr-description.md" "$(five_line_prose)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"wall of text"* ]]
}

@test "allow: pr- deliverable with exactly 4 consecutive prose lines (boundary)" {
  run run_guard_tone "/tmp/pr-description.md" "$(four_line_prose)"
  [ "$status" -eq 0 ]
}

@test "block: explainer- deliverable with 5 consecutive prose lines" {
  run run_guard_tone "/tmp/explainer-bug.md" "$(five_line_prose)"
  [ "$status" -eq 2 ]
}

@test "block: release-notes- deliverable with 5 consecutive prose lines" {
  run run_guard_tone "/tmp/release-notes-1.2.0.md" "$(five_line_prose)"
  [ "$status" -eq 2 ]
}

@test "block: review-comment- deliverable with 5 consecutive prose lines" {
  run run_guard_tone "/tmp/review-comment-42.md" "$(five_line_prose)"
  [ "$status" -eq 2 ]
}

@test "block: stakeholder- deliverable with 5 consecutive prose lines" {
  run run_guard_tone "/tmp/stakeholder-update.md" "$(five_line_prose)"
  [ "$status" -eq 2 ]
}

@test "allow: 5 consecutive prose lines in a non-write-* path never trips the wall check" {
  run run_guard_tone "/tmp/plain-notes.md" "$(five_line_prose)"
  [ "$status" -eq 0 ]
}

@test "allow: pr- deliverable whose prose is broken up by a list item every 4 lines" {
  content="$(printf 'line one.\nline two.\nline three.\nline four.\n- a list item resets the run\nline five.\nline six.\nline seven.\nline eight.')"
  run run_guard_tone "/tmp/pr-description.md" "$content"
  [ "$status" -eq 0 ]
}
