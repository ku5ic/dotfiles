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
  STACK_DETECT_FILES=()
  resolve_package_manager() { return 0; }
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

# Union of every file that influences stack detection: sentinels plus every
# path referenced in extras rules (file:, in:, any_of[].file, any_of[].in[]).
# Used by inject-context.sh for cache invalidation so that adding tsconfig.json
# or conftest.py to an existing project triggers re-detection.
# Known limit: only $project_root/<file> is checked, not search_dirs subdirs;
# this matches the sentinel walk scope and is intentional.
# shellcheck disable=SC2034
mapfile -t STACK_DETECT_FILES < <(
  {
    yq '.stacks[].sentinels[].name' "$_STACKS_YML"
    yq '.stacks[].extras[] | select(has("file")) | .file' "$_STACKS_YML"
    yq '.stacks[].extras[] | select(has("in")) | .in[]' "$_STACKS_YML"
    yq '.stacks[].extras[] | .any_of // [] | .[] | select(has("file")) | .file' "$_STACKS_YML"
    yq '.stacks[].extras[] | .any_of // [] | .[] | select(has("in")) | .in[]' "$_STACKS_YML"
  } 2>/dev/null | sort -u
)

# resolve_package_manager <dir>
# Prints the package manager name for <dir> by walking the package_managers
# table in _stacks.yml (first lockfile match wins). Checks <dir> first, then
# the git toplevel of <dir> to handle monorepos where lockfiles live at the
# root. Prints nothing when no lockfile is found; callers should apply their
# own default (e.g. npm) when empty output means "no preference".
resolve_package_manager() {
  local dir="${1:-.}"
  local toplevel
  toplevel="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"

  local -a lockfiles managers
  mapfile -t lockfiles < <(yq '.package_managers[].lockfile' "$_STACKS_YML" 2>/dev/null)
  mapfile -t managers < <(yq '.package_managers[].manager' "$_STACKS_YML" 2>/dev/null)

  local i lf mgr
  for ((i = 0; i < ${#lockfiles[@]}; i++)); do
    lf="${lockfiles[$i]}"
    mgr="${managers[$i]}"
    [[ -z "$lf" || "$lf" == "null" ]] && continue
    [[ -z "$mgr" || "$mgr" == "null" ]] && continue
    if [[ -f "$dir/$lf" || (-n "$toplevel" && -f "$toplevel/$lf") ]]; then
      printf '%s\n' "$mgr"
      return 0
    fi
  done
}
