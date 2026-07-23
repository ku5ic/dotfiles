#!/usr/bin/env bats
# Tests for memory_files_status() in ~/.dotfiles/claude/bin/_lib.sh.
#
# memory_files_status prints one found/absent line per CLAUDE.md/CLAUDE.local.md
# location Claude Code auto-loads: global (~/.claude/) and the given cwd.
# Each test fakes $HOME and a cwd fixture dir so real machine state never
# leaks into the assertions.
#
# Run with: bats tests/

setup() {
  LIB="$BATS_TEST_DIRNAME/../claude/bin/_lib.sh"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  FAKE_CWD="$BATS_TEST_TMPDIR/project"
  mkdir -p "$FAKE_HOME/.claude" "$FAKE_CWD"
}

run_memory_files_status() {
  HOME="$FAKE_HOME" bash -c "source '$LIB'; memory_files_status '$FAKE_CWD'"
}

@test "reports absent for all four when none exist" {
  run run_memory_files_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.md: absent"* ]]
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.local.md: absent"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.md: absent"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.local.md: absent"* ]]
}

@test "reports found for global CLAUDE.md only" {
  touch "$FAKE_HOME/.claude/CLAUDE.md"
  run run_memory_files_status
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.md: found"* ]]
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.local.md: absent"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.md: absent"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.local.md: absent"* ]]
}

@test "reports found for cwd-local CLAUDE.local.md only" {
  touch "$FAKE_CWD/CLAUDE.local.md"
  run run_memory_files_status
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.md: absent"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.local.md: found"* ]]
}

@test "reports found for all four when all exist" {
  touch "$FAKE_HOME/.claude/CLAUDE.md" "$FAKE_HOME/.claude/CLAUDE.local.md" \
    "$FAKE_CWD/CLAUDE.md" "$FAKE_CWD/CLAUDE.local.md"
  run run_memory_files_status
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.md: found"* ]]
  [[ "$output" == *"$FAKE_HOME/.claude/CLAUDE.local.md: found"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.md: found"* ]]
  [[ "$output" == *"$FAKE_CWD/CLAUDE.local.md: found"* ]]
}
