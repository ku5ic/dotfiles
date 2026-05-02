#!/usr/bin/env bash
# UserPromptSubmit hook. Prepends repo context to the first prompt of a session.
HOOK_NAME="inject-context.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"
# shellcheck source=../bin/_lib.sh
source "$(dirname "$0")/../bin/_lib.sh"

payload=""
read_payload
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)"
safe_session_id="${session_id//[^a-zA-Z0-9_-]/}"
# Without a stable session_id we cannot guarantee "first prompt only" injection;
# falling back to $$ would re-inject every turn. Skip and warn instead.
if [[ -z "$safe_session_id" ]]; then
  warn "no session_id in payload, skipping injection"
  exit 0
fi
session_marker="$HOME/.claude/scratch/.injected-${safe_session_id}"
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
# basename cannot collide.
cache_file="$cache_dir/${project_name}-$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8).txt"
mkdir -p "$cache_dir"

# Invalidate cache when any stack sentinel is newer than the cache.
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

# Emit required skills derived from the detected stack.
# Reads skill mappings directly from _stacks.yml (replaces skill-map.conf).
# Signals are derived from detect-stack.sh output: bare stack name plus
# compound stack+extra for each token in the extras parenthetical.
emit_required_skills() {
  local cache="$1"
  local yml="$HOME/.claude/_stacks.yml"

  [[ -s "$cache" ]] || return 0
  [[ -f "$yml" ]]   || return 0
  command -v yq >/dev/null 2>&1 || return 0

  # Extract signals from detect-stack.sh output.
  # "js: yes at frontend/ (typescript, react, next) [pnpm]"
  # -> signals: js, js+typescript, js+react, js+next
  local -a signals=()
  while IFS= read -r line; do
    [[ "$line" =~ ^root: ]] && continue
    [[ -z "$line" ]]        && continue
    local stack="${line%%:*}"
    signals+=("$stack")
    local extras
    extras=$(echo "$line" | grep -oE '\([^)]+\)' | head -1 | tr -d '()')
    if [[ -n "$extras" ]]; then
      IFS=', ' read -ra parts <<< "$extras"
      for part in "${parts[@]}"; do
        part="${part//[[:space:]]/}"
        [[ -n "$part" ]] && signals+=("${stack}+${part}")
      done
    fi
  done < "$cache"

  # For each matched signal, collect skills from _stacks.yml.
  # Base signal (js): .stacks.js.skills[]
  # Extra signal (js+react): .stacks.js.extras[] | select(.name == "react") | .skills[]
  # Skills are deduplicated in first-seen order.
  local -A seen=()
  local -a required=()

  add_skill() {
    local sk="$1"
    if [[ -z "${seen[$sk]:-}" ]]; then
      seen[$sk]=1
      required+=("$sk")
    fi
  }

  # Global skills: added first, before any per-stack signal.
  while IFS= read -r skill; do
    [[ -n "$skill" ]] && add_skill "$skill"
  done < <(yq '.global_skills // [] | .[]' "$yml" 2>/dev/null || true)

  for sig in "${signals[@]}"; do
    if [[ "$sig" == *"+"* ]]; then
      # compound signal: stack+extra
      local stack="${sig%%+*}"
      local extra="${sig##*+}"
      while IFS= read -r skill; do
        [[ -n "$skill" ]] && add_skill "$skill"
      done < <(yq ".stacks.${stack}.extras[] | select(.name == \"${extra}\") | .skills // [] | .[]" "$yml" 2>/dev/null || true)
    else
      # bare stack signal
      while IFS= read -r skill; do
        [[ -n "$skill" ]] && add_skill "$skill"
      done < <(yq ".stacks.${sig}.skills // [] | .[]" "$yml" 2>/dev/null || true)
    fi
  done

  if [[ ${#required[@]} -gt 0 ]]; then
    local IFS=', '
    echo ""
    echo "<required-skills>"
    echo "Load these skills at the start of every task for this project: ${required[*]}"
    echo "</required-skills>"
  fi
}

emit_required_skills "$cache_file"

touch "$session_marker"
exit 0
