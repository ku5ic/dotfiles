#!/usr/bin/env bash
# UserPromptSubmit hook. Prepends repo context to the first prompt of a session.
HOOK_NAME="inject-context.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"
# shellcheck source=../bin/_lib.sh
source "$(dirname "$0")/../bin/_lib.sh"

read_payload
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)"
safe_session_id="${session_id//[^a-zA-Z0-9_-]/}"
session_marker="$HOME/.claude/scratch/.injected-${safe_session_id:-$$}"
[[ -f "$session_marker" ]] && exit 0

mkdir -p "$(dirname "$session_marker")"

project_name="$("$HOME/.claude/bin/project-name.sh" 2>/dev/null || echo "unknown")"

# Skip injection for non-project contexts.
case "$project_name" in
  home|root|unknown) touch "$session_marker"; exit 0 ;;
esac

project_root="$("$HOME/.claude/bin/project-root.sh" 2>/dev/null || echo "")"
[[ -z "$project_root" ]] && { touch "$session_marker"; exit 0; }

cache_dir="$HOME/.claude/cache/stack"
# Hash the project root path into the cache key so projects with the same
# basename (e.g. ~/work/foo and ~/clients/acme/foo) cannot collide.
cache_file="$cache_dir/${project_name}-$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8).txt"
mkdir -p "$cache_dir"

# Invalidate cache when any stack sentinel is newer than the cache.
# Iterates the full canonical set from _lib.sh, not just the project-root
# anchor subset, so requirements.txt / Pipfile / manage.py / monorepo files
# also trigger reinvalidation.
newest_sentinel=0
for f in "${STACK_SENTINELS_FULL[@]/#/$project_root/}"; do
  [[ -f "$f" ]] || continue
  m="$(stat -f '%m' "$f" 2>/dev/null || echo 0)"
  (( m > newest_sentinel )) && newest_sentinel="$m"
done

cache_mtime=0
[[ -f "$cache_file" ]] && cache_mtime="$(stat -f '%m' "$cache_file" 2>/dev/null || echo 0)"

if (( cache_mtime < newest_sentinel )) || [[ ! -s "$cache_file" ]]; then
  bash "$HOME/.claude/bin/detect-stack.sh" > "$cache_file" 2>/dev/null || true
fi

if [[ -s "$cache_file" ]]; then
  echo ""
  echo "<repo-context>"
  cat "$cache_file"
  echo "branch: $(git -C "$project_root" branch --show-current 2>/dev/null || echo unknown)"
  dirty="$(git -C "$project_root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "dirty-files: $dirty"
  echo "</repo-context>"
fi

touch "$session_marker"
exit 0
