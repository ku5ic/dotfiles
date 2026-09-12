#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/hooks/guard-response.sh.
#
# guard-response.sh is a Stop hook: it reads a synthetic transcript_path
# (JSONL, one line per turn) plus stop_hook_active off the payload and blocks
# the final assistant message on banned opener/closer phrases or an unchunked
# wall of text (more than 4 consecutive prose lines outside a fence). Each
# test writes its own transcript fixture (oldest turn first, matching real
# JSONL append order) and feeds a payload referencing it on stdin.
# CLAUDE_GUARD_RESPONSE=1 is set explicitly per the gate the hook itself
# documents; the disabled-by-default case is tested without it.
#
# user_turn/assistant_turn default to the array content shape ([{type: text,
# text: ...}]) real transcripts overwhelmingly use; pass "string" as the
# second arg for the plain-string shape the hook also has to handle.
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-response.sh"
  TRANSCRIPT="$BATS_TEST_TMPDIR/transcript.jsonl"
  : >"$TRANSCRIPT"
}

user_turn() {
  local text="$1" shape="${2:-array}"
  if [[ "$shape" == "string" ]]; then
    jq -nc --arg text "$text" '{type: "user", message: {content: $text}}'
  else
    jq -nc --arg text "$text" '{type: "user", message: {content: [{type: "text", text: $text}]}}'
  fi
}

assistant_turn() {
  local text="$1" shape="${2:-array}"
  if [[ "$shape" == "string" ]]; then
    jq -nc --arg text "$text" '{type: "assistant", message: {content: $text}}'
  else
    jq -nc --arg text "$text" '{type: "assistant", message: {content: [{type: "text", text: $text}]}}'
  fi
}

append_turns() {
  printf '%s\n' "$@" >>"$TRANSCRIPT"
}

# run_guard_response [stop_hook_active] [transcript_path]
run_guard_response() {
  local stop_active="${1:-false}" transcript_path="${2:-$TRANSCRIPT}"
  jq -n --arg t "$transcript_path" --argjson stop "$stop_active" \
    '{transcript_path: $t, stop_hook_active: $stop}' |
    CLAUDE_GUARD_RESPONSE=1 "$HOOK"
}

# n_lines <count> <label>  builds <count> distinct non-empty prose lines with
# no blank line between them - a wall.
n_lines() {
  local count="$1" label="$2" i out=""
  for ((i = 1; i <= count; i++)); do
    out+="${label} line ${i}"$'\n'
  done
  printf '%s' "$out"
}

# n_paragraphs <count> <label>  same lines, blank-line separated - chunked.
n_paragraphs() {
  local count="$1" label="$2" i out=""
  for ((i = 1; i <= count; i++)); do
    out+="${label} paragraph ${i}"$'\n\n'
  done
  printf '%s' "$out"
}

@test "disabled by default: a banned-phrase wall of text is not blocked when CLAUDE_GUARD_RESPONSE is unset" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "Certainly, $(n_lines 30 prose)")"
  # env -u, not a bare omission: settings.json exports CLAUDE_GUARD_RESPONSE=1
  # into every Bash tool call, so an omitted assignment would inherit it.
  run env -u CLAUDE_GUARD_RESPONSE bash -c "jq -n --arg t '$TRANSCRIPT' '{transcript_path: \$t}' | '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "loop safety: stop_hook_active true allows a wall of text through" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 30 prose)")"
  run run_guard_response true
  [ "$status" -eq 0 ]
}

@test "no transcript_path in the payload fails open" {
  run bash -c "jq -n '{}' | CLAUDE_GUARD_RESPONSE=1 '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "an unreadable transcript_path fails open" {
  run run_guard_response false "$BATS_TEST_TMPDIR/does-not-exist.jsonl"
  [ "$status" -eq 0 ]
}

@test "empty last assistant message is allowed" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "blocks a banned opener phrase at the start of the response" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "Certainly, here is the answer.")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"banned AI-tell phrase"* ]]
}

@test "blocks a banned closer phrase even when it opens a later line, not just the first" {
  # Built from two fragments so this file's own source never contains the
  # trigger phrase at a line start (that would trip guard-tone.sh on it).
  local closer="In conclu"
  closer+="sion, that covers it."
  append_turns "$(user_turn "hello")" "$(assistant_turn "First line of the answer.
${closer}")"
  run run_guard_response
  [ "$status" -eq 2 ]
}

@test "does not block a banned word used mid-sentence rather than as a line-opening phrase" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "This is certainly useful context.")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "string-shaped content (back-compat): a banned-phrase response is still blocked" {
  append_turns "$(user_turn "hello" string)" "$(assistant_turn "Certainly, here is the answer." string)"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"banned AI-tell phrase"* ]]
}

@test "a banned phrase is blocked inside a slash-command reply too (no exemptions)" {
  append_turns "$(user_turn "/write-commit")" "$(assistant_turn "Certainly, here is the message.")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"banned AI-tell phrase"* ]]
}

@test "wall of text: 5 consecutive prose lines with no blank line are blocked" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 5 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"wall of text"* ]]
}

@test "wall of text: exactly 4 consecutive prose lines are allowed" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 4 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "no length ceiling: 40 blank-line-separated paragraphs are allowed" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_paragraphs 40 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "list items never count toward a wall" {
  response="Answer line.
- one
- two
- three
- four
- five
- six"
  append_turns "$(user_turn "hello")" "$(assistant_turn "$response")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "fenced code block lines never count toward a wall" {
  response="one prose line
\`\`\`
$(n_lines 30 code)
\`\`\`
another prose line"
  append_turns "$(user_turn "hello")" "$(assistant_turn "$response")"
  run run_guard_response
  [ "$status" -eq 0 ]
}
