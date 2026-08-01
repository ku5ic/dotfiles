#!/usr/bin/env bats
# Tests for ~/.claude/hooks/guard-dispatch.sh.
#
# guard-dispatch.sh is the single PreToolUse hook wired to Edit|Write|
# MultiEdit in settings.json. It sources guard-edit.sh, guard-skills.sh, and
# guard-tone.sh once each and runs their run_guard_* functions in declared
# order (edit-safety, then skills-gate, then tone), each inside its own
# subshell with a fresh set -e/errtrace/ERR trap so one check's fail-open
# never masks a different check's genuine violation.
#
# Each test fakes $HOME so guard-skills.sh's _stacks.yml/skills.jsonl/cache
# reads never touch real machine state, same convention as guard-skills.bats.
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-dispatch.sh"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME/.claude/logs"
}

# run_dispatch <path> <content> [session_id] [tool_name]
# Builds a Write-shaped payload (tool_input.content) with the fields every
# one of the three sourced checks reads, and pipes it to the dispatcher.
run_dispatch() {
  local path="$1" content="$2" session="${3:-s1}" tool_name="${4:-Write}"
  jq -n --arg path "$path" --arg content "$content" --arg sess "$session" --arg tn "$tool_name" \
    '{tool_input: {file_path: $path, content: $content}, session_id: $sess, tool_name: $tn}' |
    HOME="$FAKE_HOME" "$HOOK"
}

last_block_hook() {
  jq -rs '.[-1].hook' "$FAKE_HOME/.claude/logs/guard-blocks.jsonl"
}

block_count() {
  wc -l <"$FAKE_HOME/.claude/logs/guard-blocks.jsonl" | tr -d ' '
}

@test "clean write with no _stacks.yml, no risky path, no banned phrase passes all three checks" {
  run run_dispatch '/tmp/project/notes.md' 'A normal sentence with nothing wrong.'
  [ "$status" -eq 0 ]
}

@test "guard-edit's check fires first and blocks a lockfile edit" {
  run run_dispatch '/tmp/project/package-lock.json' 'harmless content'
  [ "$status" -eq 2 ]
  [[ "$output" == *"Blocked by guard-edit.sh"* ]]
  [ "$(last_block_hook)" = "guard-edit.sh" ]
}

@test "guard-skills' check blocks when a required skill has not been loaded" {
  cat >"$FAKE_HOME/.claude/_stacks.yml" <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_dispatch '/tmp/project/deploy.sh' 'harmless content'
  [ "$status" -eq 2 ]
  [[ "$output" == *"bash-patterns"* ]]
  [ "$(last_block_hook)" = "guard-skills.sh" ]
}

@test "guard-tone's check blocks a banned AI-tell phrase when the other two checks pass" {
  run run_dispatch '/tmp/project/notes.md' 'Certainly, this should be blocked by tone.'
  [ "$status" -eq 2 ]
  [[ "$output" == *"Blocked by guard-tone.sh"* ]]
  [ "$(last_block_hook)" = "guard-tone.sh" ]
}

@test "ordering: a lockfile edit that also contains a banned phrase surfaces only guard-edit's message" {
  run run_dispatch '/tmp/project/yarn.lock' 'Certainly, this content has both violations.'
  [ "$status" -eq 2 ]
  [[ "$output" == *"Blocked by guard-edit.sh"* ]]
  [[ "$output" != *"Blocked by guard-tone.sh"* ]]
  # Only one violation is logged: the dispatcher exits at the first blocking
  # check instead of running (and logging) the remaining two.
  [ "$(block_count)" -eq 1 ]
  [ "$(last_block_hook)" = "guard-edit.sh" ]
}

@test "a required skill already loaded this session passes the skills-gate and reaches the tone check" {
  cat >"$FAKE_HOME/.claude/_stacks.yml" <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  jq -nc --arg sid s1 '{ts:"2026-01-01T00:00:00Z",hook:"log-skills.sh",event:"PreToolUse",session_id:$sid,cwd:"/x",expansion_type:null,command_name:null,command_args:null,command_source:null,skill_file:"bash-patterns",tool_name:"Skill"}' \
    >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_dispatch '/tmp/project/deploy.sh' 'Certainly, tone should still catch this.'
  [ "$status" -eq 2 ]
  [[ "$output" == *"Blocked by guard-tone.sh"* ]]
}

@test "a required skill already loaded this session allows a clean write through all three checks" {
  cat >"$FAKE_HOME/.claude/_stacks.yml" <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  jq -nc --arg sid s1 '{ts:"2026-01-01T00:00:00Z",hook:"log-skills.sh",event:"PreToolUse",session_id:$sid,cwd:"/x",expansion_type:null,command_name:null,command_args:null,command_source:null,skill_file:"bash-patterns",tool_name:"Skill"}' \
    >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_dispatch '/tmp/project/deploy.sh' 'A perfectly ordinary comment.'
  [ "$status" -eq 0 ]
}

# Resilience: each check runs inside its own subshell with a fresh ERR trap,
# so an unexpected internal error in one does not abort the dispatcher before
# the remaining checks run. Malformed JSON breaks every extract_path/jq call
# identically (all three checks share the same $payload), so this cannot
# isolate one specific check's failure from another's success -- but it does
# prove the dispatcher survives and fails open end-to-end instead of hanging
# or erroring out at the first broken check, printing a distinct
# "unexpected error, failing open" notice per check along the way.
@test "malformed JSON payload fails open through all three checks instead of erroring out" {
  run bash -c "printf 'not valid json' | HOME='$FAKE_HOME' '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"guard-edit.sh: unexpected error, failing open"* ]]
  [[ "$output" == *"guard-skills.sh: unexpected error, failing open"* ]]
  [[ "$output" == *"guard-tone.sh: unexpected error, failing open"* ]]
}

@test "empty stdin payload fails open cleanly" {
  run bash -c "printf '' | HOME='$FAKE_HOME' '$HOOK'"
  [ "$status" -eq 0 ]
}
