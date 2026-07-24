#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/bin/subagent-statusline.sh.
#
# subagent-statusline.sh reads the per-task subagentStatusLine payload from
# stdin and renders one line: "name [status] <model> effort:<level> <ctx%>".
# model/contextWindowSize/tokenCount/effort are all version-gated fields that
# older Claude Code builds omit, so most tests check graceful omission.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../claude/bin/subagent-statusline.sh"
}

run_subagent_statusline() {
  printf '%s' "$1" | bash "$SCRIPT"
}

@test "renders name and status" {
  run run_subagent_statusline '{"name":"scout","status":"running"}'
  [ "$status" -eq 0 ]
  [ "$output" = "scout [running]" ]
}

@test "renders model when present" {
  run run_subagent_statusline '{"name":"scout","status":"running","model":"claude-opus-4-8"}'
  [ "$output" = "scout [running] claude-opus-4-8" ]
}

@test "omits model when absent (pre-v2.1.205 payload)" {
  run run_subagent_statusline '{"name":"scout","status":"running"}'
  [[ "$output" != *"claude-"* ]]
}

@test "renders effort when present" {
  run run_subagent_statusline '{"name":"scout","status":"running","effort":"high"}'
  [[ "$output" == *"effort:high"* ]]
}

@test "omits effort when absent (pre-v2.1.214 payload)" {
  run run_subagent_statusline '{"name":"scout","status":"running"}'
  [[ "$output" != *"effort:"* ]]
}

@test "renders a numeric token-budget effort value verbatim" {
  run run_subagent_statusline '{"name":"scout","status":"running","effort":12000}'
  [[ "$output" == *"effort:12000"* ]]
}

@test "renders context percentage from tokenCount over contextWindowSize" {
  run run_subagent_statusline '{"name":"scout","status":"running","contextWindowSize":200000,"tokenCount":45000}'
  [[ "$output" == *" 22%"* ]]
}

@test "omits context percentage when contextWindowSize is absent" {
  run run_subagent_statusline '{"name":"scout","status":"running","tokenCount":45000}'
  [[ "$output" != *"%"* ]]
}

@test "omits context percentage when tokenCount is absent" {
  run run_subagent_statusline '{"name":"scout","status":"running","contextWindowSize":200000}'
  [[ "$output" != *"%"* ]]
}

@test "omits context percentage when contextWindowSize is explicitly zero (no divide by zero)" {
  run run_subagent_statusline '{"name":"scout","status":"running","contextWindowSize":0,"tokenCount":5000}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"%"* ]]
}

@test "renders zero percent when tokenCount is zero" {
  run run_subagent_statusline '{"name":"scout","status":"running","contextWindowSize":200000,"tokenCount":0}'
  [[ "$output" == *" 0%"* ]]
}

@test "full payload renders every segment in order" {
  run run_subagent_statusline '{"name":"scout","status":"running","model":"claude-opus-4-8","contextWindowSize":200000,"tokenCount":45000,"effort":"high"}'
  [ "$output" = "scout [running] claude-opus-4-8 effort:high 22%" ]
}

@test "falls back to a placeholder name when name is absent" {
  run run_subagent_statusline '{"status":"running"}'
  [[ "$output" == "task "* ]]
}

@test "missing jq prints a notice instead of erroring or blanking" {
  local stub_dir="$BATS_TEST_TMPDIR/stub_no_jq"
  mkdir -p "$stub_dir"
  ln -s "$(command -v cat)" "$stub_dir/cat"
  local bash_bin
  bash_bin="$(command -v bash)"
  run env PATH="$stub_dir" "$bash_bin" "$SCRIPT" <<<'{}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"jq not found"* ]]
}
