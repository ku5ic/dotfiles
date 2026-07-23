#!/usr/bin/env bash
# Agent startup context. Agents never receive the UserPromptSubmit hook
# injection that the main session gets (hooks/inject-context.sh), so agent
# shells run this directly at the start of their body instead.
#
# Emits the same repo-context content as the hook (stack lines from the
# detect-stack cache or a fresh run, branch, dirty count) plus a
# skills-to-load list derived from _stacks.yml exactly as the hook derives
# required and suggested skills. Shared derivation lives in bin/_lib.sh.
#
# Requires: yq (mikefarah, installed via Brewfile)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

project_name="$("$HOME/.claude/bin/project-name.sh" 2>/dev/null || echo "unknown")"

case "$project_name" in
home | root | unknown)
  exit 0
  ;;
esac

project_root="$("$HOME/.claude/bin/project-root.sh" 2>/dev/null || echo "")"
[[ -z "$project_root" ]] && exit 0

cache_file="$(stack_cache_file "$project_name" "$project_root")"
refresh_stack_cache_if_stale "$project_root" "$cache_file"

if [[ -s "$cache_file" ]]; then
  echo "<repo-context>"
  cat "$cache_file"
  echo "branch: $(git -C "$project_root" branch --show-current 2>/dev/null || echo unknown)"
  dirty="$(git -C "$project_root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "dirty-files: $dirty"
  echo "</repo-context>"
fi

echo ""
echo "<memory-files>"
memory_files_status "$PWD"
echo "</memory-files>"

yml="$HOME/.claude/_stacks.yml"
if [[ -f "$yml" ]] && command -v yq >/dev/null 2>&1; then
  required=()
  mapfile -t required < <(global_skills_list "$yml")

  suggested=()
  if [[ -s "$cache_file" ]]; then
    mapfile -t suggested < <(stacks_signals_from_cache "$cache_file" | suggested_skills_from_signals "$yml")
  fi

  if [[ ${#required[@]} -gt 0 || ${#suggested[@]} -gt 0 ]]; then
    echo ""
    echo "skills-to-load:"
    sk=""
    for sk in "${required[@]}"; do
      echo "  $sk"
    done
    for sk in "${suggested[@]}"; do
      echo "  $sk"
    done
  fi
fi
