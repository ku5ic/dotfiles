#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/hooks/require-checkout-mode.sh.
#
# The hook reads Claude Code's hook JSON on stdin: UserPromptSubmit sends
# {"prompt": ...}, PreToolUse:Skill sends {"tool_input": {"skill", "args"}}.
# Exit 0 lets the prompt or tool call through, exit 2 blocks it.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../claude/hooks/require-checkout-mode.sh"
}

# typed <prompt>
typed() {
  run "$SCRIPT" <<<"$(jq -n --arg prompt "$1" '{prompt: $prompt}')"
}

# invoked <skill> [<args>]
invoked() {
  if [ $# -eq 2 ]; then
    run "$SCRIPT" <<<"$(jq -n --arg skill "$1" --arg args "$2" '{tool_input: {skill: $skill, args: $args}}')"
  else
    run "$SCRIPT" <<<"$(jq -n --arg skill "$1" '{tool_input: {skill: $skill}}')"
  fi
}

@test "lets an unrelated prompt through" {
  typed 'fix the starship prompt'
  [ "$status" -eq 0 ]
}

@test "blocks a bare typed /code-review" {
  typed '/code-review'
  [ "$status" -eq 2 ]
  [[ "$output" == *"need a checkout mode"* ]]
}

@test "blocks a typed /verify with a target but no mode" {
  typed '/verify 123'
  [ "$status" -eq 2 ]
}

@test "lets a typed /code-review with here through" {
  typed '/code-review high here'
  [ "$status" -eq 0 ]
}

@test "lets a typed /verify with worktree through" {
  typed '/verify worktree 123'
  [ "$status" -eq 0 ]
}

@test "does not treat a word ending in here as the mode" {
  typed '/code-review therefore'
  [ "$status" -eq 2 ]
}

@test "ignores a command that only starts with verify" {
  typed '/verifyx'
  [ "$status" -eq 0 ]
}

@test "ignores /code-review mentioned mid-prompt" {
  typed 'please run /code-review later'
  [ "$status" -eq 0 ]
}

@test "blocks a model-invoked code-review without args" {
  invoked code-review
  [ "$status" -eq 2 ]
}

@test "blocks a model-invoked verify whose args lack a mode" {
  invoked verify '123'
  [ "$status" -eq 2 ]
}

@test "lets a model-invoked code-review with a mode through" {
  invoked code-review 'worktree 123'
  [ "$status" -eq 0 ]
}

@test "lets another model-invoked skill through" {
  invoked simplify
  [ "$status" -eq 0 ]
}
