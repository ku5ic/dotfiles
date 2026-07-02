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

# Shared stack-cache and skill-derivation logic. Consumed by:
#   hooks/inject-context.sh (UserPromptSubmit hook, main session only)
#   bin/agent-context.sh (agent startup; agents never see the hook output)
# Kept here so the two never carry a private copy of the same yq queries.

# stack_cache_file <project_name> <project_root>
# Prints the cache file path for a project's detect-stack.sh output. The
# project root is hashed into the filename so same-basename projects
# elsewhere on disk cannot collide.
stack_cache_file() {
  local project_name="$1" project_root="$2"
  printf '%s/%s-%s.txt\n' \
    "$HOME/.claude/cache/stack" \
    "$project_name" \
    "$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8)"
}

# refresh_stack_cache_if_stale <project_root> <cache_file>
# Regenerates the cache by running detect-stack.sh when any detection-relevant
# file (STACK_DETECT_FILES) is newer than the cache, or the cache is
# empty/missing. No output; callers read $cache_file afterward.
refresh_stack_cache_if_stale() {
  local project_root="$1" cache_file="$2"
  mkdir -p "$(dirname "$cache_file")"

  local newest_sentinel=0 f m
  for f in "${STACK_DETECT_FILES[@]/#/$project_root/}"; do
    [[ -f "$f" ]] || continue
    m="$(stat -f '%m' "$f" 2>/dev/null || echo 0)"
    ((m > newest_sentinel)) && newest_sentinel="$m"
  done

  local cache_mtime=0
  [[ -f "$cache_file" ]] && cache_mtime="$(stat -f '%m' "$cache_file" 2>/dev/null || echo 0)"

  if ((cache_mtime < newest_sentinel)) || [[ ! -s "$cache_file" ]]; then
    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN
    if bash "$HOME/.claude/bin/detect-stack.sh" >"$tmp" 2>/dev/null; then
      mv "$tmp" "$cache_file"
    else
      rm -f "$tmp"
    fi
  fi
}

# stacks_signals_from_cache <cache_file>
# Parses a detect-stack.sh cache file into stack and stack+extra signal
# tokens, one per line, in first-seen order. Example: a cache line
# "js: yes at frontend/ (typescript, react) [pnpm]" yields "js", "js+typescript",
# "js+react".
stacks_signals_from_cache() {
  local cache="$1"
  local line stack extras extra_token
  local -a extra_tokens
  while IFS= read -r line; do
    [[ "$line" =~ ^root: ]] && continue
    [[ -z "$line" ]] && continue
    stack="${line%%:*}"
    printf '%s\n' "$stack"
    extras=$(echo "$line" | grep -oE '\([^)]+\)' | head -1 | tr -d '()') || true
    if [[ -n "$extras" ]]; then
      IFS=', ' read -ra extra_tokens <<<"$extras"
      for extra_token in "${extra_tokens[@]}"; do
        extra_token="${extra_token//[[:space:]]/}"
        [[ -n "$extra_token" ]] && printf '%s\n' "${stack}+${extra_token}"
      done
    fi
  done <"$cache"
}

# global_skills_list <yml>
# Prints _stacks.yml's global_skills, deduped, in first-seen order.
global_skills_list() {
  local yml="$1"
  local -A seen=()
  local skill
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    if [[ -z "${seen[$skill]:-}" ]]; then
      seen[$skill]=1
      printf '%s\n' "$skill"
    fi
  done < <(yq '.global_skills // [] | .[]' "$yml" 2>/dev/null || true)
}

# suggested_skills_from_signals <yml>
# Reads stack/extra signals from stdin (one per line, as produced by
# stacks_signals_from_cache), prints the per-stack/extra skills mapped in
# _stacks.yml, deduped, first-seen order, excluding global_skills (those are
# required, not suggested).
suggested_skills_from_signals() {
  local yml="$1"
  local -A global_set=()
  local gsk
  while IFS= read -r gsk; do
    [[ -n "$gsk" ]] && global_set[$gsk]=1
  done < <(global_skills_list "$yml")

  local -A seen=()
  local sig stack extra sk
  while IFS= read -r sig; do
    [[ -z "$sig" ]] && continue
    if [[ "$sig" == *"+"* ]]; then
      stack="${sig%%+*}"
      extra="${sig##*+}"
      while IFS= read -r sk; do
        [[ -z "$sk" ]] && continue
        [[ -n "${global_set[$sk]:-}" ]] && continue
        if [[ -z "${seen[$sk]:-}" ]]; then
          seen[$sk]=1
          printf '%s\n' "$sk"
        fi
      done < <(yq ".stacks.${stack}.extras[] | select(.name == \"${extra}\") | .skills // [] | .[]" "$yml" 2>/dev/null || true)
    else
      while IFS= read -r sk; do
        [[ -z "$sk" ]] && continue
        [[ -n "${global_set[$sk]:-}" ]] && continue
        if [[ -z "${seen[$sk]:-}" ]]; then
          seen[$sk]=1
          printf '%s\n' "$sk"
        fi
      done < <(yq ".stacks.${sig}.skills // [] | .[]" "$yml" 2>/dev/null || true)
    fi
  done
}
