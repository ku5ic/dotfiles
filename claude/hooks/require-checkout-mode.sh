#!/usr/bin/env bash
# Blocks /code-review and /verify unless the args name a checkout mode (here|worktree).
# Wired to UserPromptSubmit (typed command) and PreToolUse:Skill (model-invoked).
set -euo pipefail

text=$(jq -r '
  if .tool_input then "/\(.tool_input.skill) \(.tool_input.args // "")"
  else .prompt // "" end')

[[ $text =~ ^/(code-review|verify)([[:space:]]|$) ]] || exit 0
[[ $text =~ [[:space:]](here|worktree)([[:space:]]|$) ]] && exit 0

printf '%s\n' "/code-review and /verify need a checkout mode: add 'here' or 'worktree'." >&2
exit 2
