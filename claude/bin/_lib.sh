#!/usr/bin/env bash
# Single source of truth for stack sentinels. Sourced by:
#   bin/detect-stack.sh
#   bin/project-root.sh
#   hooks/inject-context.sh
#
# Previously defined STACK_SENTINELS_FULL and STACK_SENTINELS_PROJECT_ROOT
# as hand-written arrays. Both are now derived from _stacks.yml via yq so
# adding a stack or sentinel here is the only edit required.
#
# Requires: yq (mikefarah, installed via Brewfile)

_STACKS_YML="$HOME/.claude/_stacks.yml"

if ! command -v yq >/dev/null 2>&1; then
  echo "_lib.sh: yq not found; stack detection disabled" >&2
  STACK_SENTINELS_FULL=()
  STACK_SENTINELS_PROJECT_ROOT=()
  return 0
fi

# Full set: every sentinel any consumer cares about.
# Used by inject-context.sh for cache invalidation and by detect-stack.sh
# as the canonical union.
# shellcheck disable=SC2034
mapfile -t STACK_SENTINELS_FULL < <(
  yq '.stacks[].sentinels[].name' "$_STACKS_YML" 2>/dev/null
)

# Anchor-walk subset: the small, fast list project-root.sh walks ancestors
# with. Marked anchor: true in _stacks.yml. Keep minimal; every entry
# slows the ancestor walk for repos without that sentinel.
# shellcheck disable=SC2034
mapfile -t STACK_SENTINELS_PROJECT_ROOT < <(
  yq '.stacks[].sentinels[] | select(.anchor == true) | .name' "$_STACKS_YML" 2>/dev/null
)
