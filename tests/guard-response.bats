#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/hooks/guard-response.sh.
#
# guard-response.sh is a Stop hook: it reads a synthetic transcript_path
# (JSONL, one line per turn) plus stop_hook_active off the payload, derives a
# sticky short/normal/long tier from every prior user message, and blocks the
# final assistant message on banned opener/closer phrases or an over-length
# prose ceiling. Each test writes its own transcript fixture (oldest turn
# first, matching real JSONL append order) and feeds a payload referencing it
# on stdin. CLAUDE_GUARD_RESPONSE=1 is set explicitly per the experiment gate
# the hook itself documents; the disabled-by-default case is tested without it.
#
# user_turn/assistant_turn default to the array content shape ([{type: text,
# text: ...}]) real transcripts overwhelmingly use; pass "string" as the
# second arg for the plain-string shape the hook also has to handle (see the
# back-compat test below).
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-response.sh"
  TRANSCRIPT="$BATS_TEST_TMPDIR/transcript.jsonl"
  : >"$TRANSCRIPT"
}

# user_turn <text> [shape]  shape defaults to "array" -- the shape a real
# transcript uses for typed prompts and skill-body-expansion turns alike
# (159/178 of this session's own user entries). Pass "string" for the plain-
# string shape Claude Code also emits (e.g. the raw <command-message>/
# <command-name> tag for a slash command, or a bare "/command" prompt).
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

# append_turns <jsonl-line> [jsonl-line ...]  appends to $TRANSCRIPT in order.
append_turns() {
  printf '%s\n' "$@" >>"$TRANSCRIPT"
}

# run_guard_response [stop_hook_active] [transcript_path]
# Enables the experiment gate (CLAUDE_GUARD_RESPONSE=1) unless the caller
# overrides the env directly (see the disabled-by-default test).
run_guard_response() {
  local stop_active="${1:-false}" transcript_path="${2:-$TRANSCRIPT}"
  jq -n --arg t "$transcript_path" --argjson stop "$stop_active" \
    '{transcript_path: $t, stop_hook_active: $stop}' |
    CLAUDE_GUARD_RESPONSE=1 "$HOOK"
}

# n_lines <count> <label>  builds <count> distinct non-empty prose lines.
n_lines() {
  local count="$1" label="$2" i out=""
  for ((i = 1; i <= count; i++)); do
    out+="${label} line ${i}"$'\n'
  done
  printf '%s' "$out"
}

@test "disabled by default: a banned-phrase, over-length response is not blocked when CLAUDE_GUARD_RESPONSE is unset" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "Certainly, $(n_lines 30 prose)")"
  # env -u, not a bare omission: this session's own settings.json env block
  # already exports CLAUDE_GUARD_RESPONSE=1 into every Bash tool call, so an
  # omitted assignment here would silently inherit it and defeat the test.
  run env -u CLAUDE_GUARD_RESPONSE bash -c "jq -n --arg t '$TRANSCRIPT' '{transcript_path: \$t}' | '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "loop safety: stop_hook_active true allows the response through even when over the short ceiling" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 30 prose)")"
  run run_guard_response true
  [ "$status" -eq 0 ]
}

@test "slash-command last user message exits allow regardless of response shape" {
  append_turns "$(user_turn "/flow-test")" "$(assistant_turn "Certainly, $(n_lines 30 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "slash-command exemption still fires when the expanded skill body is the later turn (real transcript shape)" {
  # Real shape: the typed command is a plain-string turn carrying the
  # <command-message>/<command-name> tag; Claude Code then injects the
  # skill's own procedure text as a later, array-shaped user turn. last_user
  # must resolve to the command turn, not the skill body, or the vocabulary
  # of the skill's own procedure ("review", "report", "audit", "write") gets
  # evaluated as if the user asked for that.
  append_turns \
    "$(user_turn "<command-message>flow-review</command-message>
<command-name>/flow-review</command-name>" string)" \
    "$(user_turn "Base directory for this skill: /Users/ku5ic/.claude/skills/flow-review

## Procedure
Write the review report and audit every file.")" \
    "$(assistant_turn "Certainly, $(n_lines 30 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "last_user ignores an isMeta turn that is not the skill-body prefix shape" {
  # isMeta marks any injected content the user did not type, not only the
  # skill-body case above - e.g. a relayed message from another agent. Without
  # filtering on isMeta, its vocabulary ("report") fires the per-message
  # trigger and lifts the tier past the point where 13 lines still blocks.
  append_turns \
    "$(user_turn "hello")" \
    "$(jq -nc --arg text "Another Claude session sent a message: it has a bug report for you." \
      '{type: "user", isMeta: true, message: {content: [{type: "text", text: $text}]}}')" \
    "$(assistant_turn "$(n_lines 13 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"short-tier ceiling is 12"* ]]
}

@test "string-shaped content (back-compat): a banned-phrase response is still blocked" {
  append_turns "$(user_turn "hello" string)" "$(assistant_turn "Certainly, here is the answer." string)"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"banned AI-tell phrase"* ]]
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
  # Built from two fragments (not one literal line) so this test file's own
  # source text never contains the trigger phrase at a line start -- that
  # would otherwise trip guard-tone.sh on this very file.
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

@test "short tier: a response over the default 12-line ceiling is blocked" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 13 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"short-tier ceiling is 12"* ]]
}

@test "short tier: a response at exactly the 12-line ceiling is allowed" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 12 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "fenced code block lines do not count toward the prose ceiling" {
  response="one prose line
\`\`\`
$(n_lines 30 code)
\`\`\`
another prose line"
  append_turns "$(user_turn "hello")" "$(assistant_turn "$response")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "a per-message 'explain' trigger lifts the ceiling to the normal tier for this reply" {
  append_turns "$(user_turn "explain how this works")" "$(assistant_turn "$(n_lines 20 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "the normal-tier ceiling still blocks a response over 40 lines" {
  append_turns "$(user_turn "explain how this works")" "$(assistant_turn "$(n_lines 41 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"normal-tier ceiling is 40"* ]]
}

@test "sticky long mode set in an earlier message removes the line ceiling for a later, unrelated reply" {
  append_turns "$(user_turn "long mode")" \
    "$(user_turn "what time is it")" \
    "$(assistant_turn "$(n_lines 80 prose)")"
  run run_guard_response
  [ "$status" -eq 0 ]
}

@test "sticky mode uses the last mode word, not the first, when both appear across the session" {
  append_turns "$(user_turn "long mode")" \
    "$(user_turn "switch to short mode")" \
    "$(assistant_turn "$(n_lines 20 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
}

@test "a message quoting all three mode words does not pin the tier (must BE the command, not mention one)" {
  append_turns "$(user_turn "Quick check: does long mode, normal mode, and short mode all live in the same file?")" \
    "$(assistant_turn "$(n_lines 13 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"short-tier ceiling is 12"* ]]
}

@test "a compound same-message mode-switch sentence does not resolve to long via if/elif precedence" {
  append_turns "$(user_turn "we were in long mode, switch to short mode")" \
    "$(assistant_turn "$(n_lines 13 prose)")"
  run run_guard_response
  [ "$status" -eq 2 ]
  [[ "$output" == *"short-tier ceiling is 12"* ]]
}

@test "a custom short-tier ceiling env var is respected" {
  append_turns "$(user_turn "hello")" "$(assistant_turn "$(n_lines 4 prose)")"
  run bash -c "jq -n --arg t '$TRANSCRIPT' '{transcript_path: \$t}' | CLAUDE_GUARD_RESPONSE=1 CLAUDE_GUARD_RESPONSE_MAX_LINES=3 '$HOOK'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"short-tier ceiling is 3"* ]]
}
