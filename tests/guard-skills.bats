#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/hooks/guard-skills.sh.
#
# guard-skills.sh reads $HOME/.claude/_stacks.yml (skill_file_map) and
# $HOME/.claude/logs/skills.jsonl (what has been loaded this session) on
# every Edit/Write/MultiEdit/Read. Each test fakes $HOME so real machine
# state never leaks into the assertions; some tests copy the real repo's
# _stacks.yml into the fake $HOME so the production map itself is exercised.
#
# Run with: bats tests/

setup() {
  HOOK="$BATS_TEST_DIRNAME/../claude/hooks/guard-skills.sh"
  REAL_STACKS_YML="$BATS_TEST_DIRNAME/../claude/_stacks.yml"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME/.claude/logs"
}

write_stacks_yml() {
  cat >"$FAKE_HOME/.claude/_stacks.yml"
}

write_skills_log() {
  printf '%s\n' "$@" >"$FAKE_HOME/.claude/logs/skills.jsonl"
}

# run_guard_skills <path> [session_id] [tool_name]
run_guard_skills() {
  local path="$1" session="${2:-s1}" tool_name="${3:-Edit}"
  jq -n --arg path "$path" --arg sess "$session" --arg tn "$tool_name" \
    '{tool_input: {file_path: $path}, session_id: $sess, tool_name: $tn}' |
    HOME="$FAKE_HOME" "$HOOK"
}

@test "every skill_file_map entry in the real _stacks.yml blocks until its skill is loaded" {
  cp "$REAL_STACKS_YML" "$FAKE_HOME/.claude/_stacks.yml"
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"

  while IFS=$'\t' read -r globs skills; do
    read -ra glob_arr <<<"$globs"
    sample_glob="${glob_arr[0]}"
    filename="${sample_glob//\*/sample}"
    run run_guard_skills "/tmp/project/$filename"
    [ "$status" -eq 2 ]
    for sk in $skills; do
      [[ "$output" == *"$sk"* ]]
    done
  done < <(yq -r '.skill_file_map[] | [(.globs // [] | join(" ")), (.skills // [] | join(" "))] | join("\t")' "$REAL_STACKS_YML")
}

@test "declaration order: a .test.tsx file picks up test-patterns before typescript-patterns" {
  cp "$REAL_STACKS_YML" "$FAKE_HOME/.claude/_stacks.yml"
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.test.tsx"
  [ "$status" -eq 2 ]
  # Position, not membership: test-patterns must appear earlier in the
  # message than typescript-patterns, matching _stacks.yml's declared order.
  before_test="${output%%test-patterns*}"
  before_ts="${output%%typescript-patterns*}"
  [ "${#before_test}" -lt "${#before_ts}" ]
}

@test "cumulative matching: a .test.tsx file requires skills from every matching entry, not just one" {
  cp "$REAL_STACKS_YML" "$FAKE_HOME/.claude/_stacks.yml"
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.test.tsx"
  [ "$status" -eq 2 ]
  [[ "$output" == *"test-patterns"* ]]
  [[ "$output" == *"typescript-patterns"* ]]
  [[ "$output" == *"react-patterns"* ]]
  [[ "$output" == *"fix-sizing"* ]]
}

@test "catch-all globs entry composes with specific entries rather than displacing them" {
  cp "$REAL_STACKS_YML" "$FAKE_HOME/.claude/_stacks.yml"
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.ts"
  [ "$status" -eq 2 ]
  [[ "$output" == *"typescript-patterns"* ]]
  [[ "$output" == *"fix-sizing"* ]]
  [[ "$output" == *"root-cause-diagnosis"* ]]
  [[ "$output" == *"context-gathering"* ]]
}

@test "on: path entries match the full path, not just the basename" {
  cp "$REAL_STACKS_YML" "$FAKE_HOME/.claude/_stacks.yml"
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"

  run run_guard_skills "/tmp/random/SKILL.md"
  [[ "$output" != *"skill-authoring"* ]]

  run run_guard_skills "/tmp/project/skills/foo/SKILL.md"
  [[ "$output" == *"skill-authoring"* ]]
}

@test "blocks when the required skill has not been loaded this session" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"bash-patterns"* ]]
}

@test "allows when the required skill was loaded this session via the Skill tool" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  write_skills_log '{"ts":"2026-01-01T00:00:00Z","hook":"log-skills.sh","event":"PreToolUse","session_id":"s1","cwd":"/x","expansion_type":null,"command_name":null,"command_args":null,"command_source":null,"skill_file":"bash-patterns","tool_name":"Skill"}'
  run run_guard_skills "/tmp/project/foo.sh" "s1"
  [ "$status" -eq 0 ]
}

@test "allows when the required skill's SKILL.md was read this session (Read fallback)" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  write_skills_log '{"ts":"2026-01-01T00:00:00Z","hook":"log-skills.sh","event":"PostToolUse","session_id":"s1","cwd":"/x","expansion_type":null,"command_name":null,"command_args":null,"command_source":null,"skill_file":"/Users/x/.claude/skills/bash-patterns/SKILL.md","tool_name":"Read"}'
  run run_guard_skills "/tmp/project/foo.sh" "s1"
  [ "$status" -eq 0 ]
}

@test "a session_id mismatch does not count as loaded" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  write_skills_log '{"ts":"2026-01-01T00:00:00Z","hook":"log-skills.sh","event":"PreToolUse","session_id":"other-session","cwd":"/x","expansion_type":null,"command_name":null,"command_args":null,"command_source":null,"skill_file":"bash-patterns","tool_name":"Skill"}'
  run run_guard_skills "/tmp/project/foo.sh" "s1"
  [ "$status" -eq 2 ]
}

@test "Read tool_name produces a read-verb block message" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.sh" "s1" "Read"
  [ "$status" -eq 2 ]
  [[ "$output" == *"This read touches"* ]]
}

@test "Edit tool_name produces an edit-verb block message" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.sh"]
    skills: [bash-patterns]
YAML
  : >"$FAKE_HOME/.claude/logs/skills.jsonl"
  run run_guard_skills "/tmp/project/foo.sh" "s1" "Edit"
  [ "$status" -eq 2 ]
  [[ "$output" == *"This edit touches"* ]]
}

# Regression coverage for a fixed enforcement-floor gap (see the plan and
# bin/skills-report.sh Phase 2 for context): a skill can be both
# stack-suggested (inject-context.sh logs a "suggested-skill" marker for
# these, meaning "surfaced", not "loaded") and skill_file_map-required (e.g.
# react-patterns in production). guard-skills.sh's compliance query now
# restricts to real invocation events (PreToolUse/PostToolUse/
# UserPromptExpansion), so a bare "suggested-skill" or "required-skill"
# marker can no longer satisfy a required-skill check on its own.
@test "a suggested-skill marker alone does not satisfy the required-skill check" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*.jsx"]
    skills: [react-patterns]
YAML
  write_skills_log '{"ts":"2026-01-01T00:00:00Z","hook":"inject-context.sh","event":"suggested-skill","session_id":"s1","cwd":"/x","expansion_type":null,"command_name":null,"command_args":null,"command_source":null,"skill_file":"react-patterns","tool_name":null}'
  run run_guard_skills "/tmp/project/foo.jsx" "s1"
  [ "$status" -eq 2 ]
  [[ "$output" == *"react-patterns"* ]]
}

@test "a required-skill marker alone does not satisfy the required-skill check" {
  write_stacks_yml <<'YAML'
skill_file_map:
  - on: basename
    globs: ["*"]
    skills: [fix-sizing]
YAML
  write_skills_log '{"ts":"2026-01-01T00:00:00Z","hook":"inject-context.sh","event":"required-skill","session_id":"s1","cwd":"/x","expansion_type":null,"command_name":null,"command_args":null,"command_source":null,"skill_file":"fix-sizing","tool_name":null}'
  run run_guard_skills "/tmp/project/foo.txt" "s1"
  [ "$status" -eq 2 ]
  [[ "$output" == *"fix-sizing"* ]]
}
