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
home | root | unknown)
  touch "$session_marker"
  exit 0
  ;;
esac

project_root="$("$HOME/.claude/bin/project-root.sh" 2>/dev/null || echo "")"
[[ -z "$project_root" ]] && {
  touch "$session_marker"
  exit 0
}

cache_dir="$HOME/.claude/cache/stack"
# Hash the project root path into the cache key so projects with the same
# basename cannot collide.
cache_file="$cache_dir/${project_name}-$(printf '%s' "$project_root" | shasum -a 256 | cut -c1-8).txt"
mkdir -p "$cache_dir"

# Invalidate cache when any detection-relevant file is newer than the cache.
# Checks $project_root/<file> only; search_dirs subdirectories are not walked
# (same scope as the original sentinel walk, intentional).
newest_sentinel=0
for f in "${STACK_DETECT_FILES[@]/#/$project_root/}"; do
  [[ -f "$f" ]] || continue
  m="$(stat -f '%m' "$f" 2>/dev/null || echo 0)"
  ((m > newest_sentinel)) && newest_sentinel="$m"
done

cache_mtime=0
[[ -f "$cache_file" ]] && cache_mtime="$(stat -f '%m' "$cache_file" 2>/dev/null || echo 0)"

if ((cache_mtime < newest_sentinel)) || [[ ! -s "$cache_file" ]]; then
  _cache_tmp="$(mktemp)"
  trap 'rm -f "$_cache_tmp"' EXIT
  if bash "$HOME/.claude/bin/detect-stack.sh" >"$_cache_tmp" 2>/dev/null; then
    mv "$_cache_tmp" "$cache_file"
  else
    rm -f "$_cache_tmp"
  fi
fi

if [[ -s "$cache_file" ]]; then
  echo ""
  echo "<repo-context>"
  cat "$cache_file"
  echo "branch (at session start): $(git -C "$project_root" branch --show-current 2>/dev/null || echo unknown)"
  dirty="$(git -C "$project_root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "dirty-files (at session start): $dirty"
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
  [[ -f "$yml" ]] || return 0
  command -v yq >/dev/null 2>&1 || return 0

  # Extract signals from detect-stack.sh output.
  # "js: yes at frontend/ (typescript, react, next) [pnpm]"
  # -> signals: js, js+typescript, js+react, js+next
  local -a signals=()
  while IFS= read -r line; do
    [[ "$line" =~ ^root: ]] && continue
    [[ -z "$line" ]] && continue
    local stack="${line%%:*}"
    signals+=("$stack")
    local extras
    extras=$(echo "$line" | grep -oE '\([^)]+\)' | head -1 | tr -d '()') || true
    if [[ -n "$extras" ]]; then
      IFS=', ' read -ra parts <<<"$extras"
      for part in "${parts[@]}"; do
        part="${part//[[:space:]]/}"
        [[ -n "$part" ]] && signals+=("${stack}+${part}")
      done
    fi
  done <"$cache"

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
    echo "BLOCKING REQUIREMENT: invoke the Skill tool for each of these skills NOW, before any other action: ${required[*]}"
    echo "</required-skills>"
    if command -v jq >/dev/null 2>&1; then
      local log_dir ts cwd_val sk
      log_dir="$HOME/.claude/logs"
      mkdir -p "$log_dir"
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      cwd_val="$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)"
      for sk in "${required[@]}"; do
        jq -cn \
          --arg ts "$ts" \
          --arg sess "$session_id" \
          --arg cwd "$cwd_val" \
          --arg skill "$sk" \
          '{ts:$ts,hook:"inject-context.sh",event:"required-skill",session_id:$sess,cwd:$cwd,expansion_type:null,command_name:null,command_args:null,command_source:null,skill_file:$skill,tool_name:null}' \
          >>"$log_dir/skills.jsonl"
      done
    fi
  fi
}

# emit_tooling_block <root>
# Emits a <tooling> block computed live (not from the stack cache) for JS/TS
# and Python projects. Root-and-workspace-level detection only; search_dirs
# subdirectories are not walked (same scope as the sentinel walk, intentional).
emit_tooling_block() {
  local root="$1"

  local has_js=0 has_python=0
  [[ -f "$root/package.json" ]] && has_js=1
  if [[ -f "$root/pyproject.toml" || -f "$root/requirements.txt" || -f "$root/Pipfile" ]]; then
    has_python=1
  fi
  if ! ((has_js)) && ! ((has_python)); then
    return 0
  fi

  local pm
  pm="$(resolve_package_manager "$root" 2>/dev/null || true)"

  local body
  body="$(
    set +e

    if ((has_js)) && command -v jq >/dev/null 2>&1; then
      [[ -n "$pm" ]] && echo "package-manager: $pm"

      if jq -e 'has("scripts") and (.scripts | length > 0)' "$root/package.json" >/dev/null 2>&1; then
        echo "scripts (package.json):"
        jq -r '.scripts | to_entries[] | "  \(.key): \(.value[0:120])\(if (.value | length) > 120 then "..." else "" end)"' "$root/package.json" 2>/dev/null
      fi

      local is_ws=0
      if jq -e 'has("workspaces")' "$root/package.json" >/dev/null 2>&1 || [[ -f "$root/pnpm-workspace.yaml" ]]; then
        is_ws=1
      fi

      if ((is_ws)); then
        local -a ws_pats=()
        if jq -e '.workspaces | arrays' "$root/package.json" >/dev/null 2>&1; then
          mapfile -t ws_pats < <(jq -r '.workspaces[]' "$root/package.json" 2>/dev/null)
        elif jq -e '.workspaces.packages | arrays' "$root/package.json" >/dev/null 2>&1; then
          mapfile -t ws_pats < <(jq -r '.workspaces.packages[]' "$root/package.json" 2>/dev/null)
        fi
        if command -v yq >/dev/null 2>&1 && [[ -f "$root/pnpm-workspace.yaml" ]]; then
          local -a _pp
          mapfile -t _pp < <(yq '.packages[]' "$root/pnpm-workspace.yaml" 2>/dev/null)
          ws_pats+=("${_pp[@]}")
        fi
        if [[ ${#ws_pats[@]} -gt 0 ]]; then
          (
            cd "$root" 2>/dev/null || exit 0
            shopt -s nullglob globstar 2>/dev/null || true
            local _pat _dir _sc _ws_shown=0 _ws_max=20
            for _pat in "${ws_pats[@]}"; do
              # shellcheck disable=SC2231
              for _dir in $_pat; do
                [[ -d "$_dir" && -f "$_dir/package.json" ]] || continue
                _sc="$(jq '.scripts | length' "$_dir/package.json" 2>/dev/null || echo 0)"
                [[ "${_sc:-0}" -gt 0 ]] || continue
                if [[ $_ws_shown -ge $_ws_max ]]; then
                  echo "  (workspace packages capped at $_ws_max; run-checks.sh covers all)"
                  break 2
                fi
                echo "scripts ($_dir/package.json):"
                jq -r '.scripts | to_entries[] | "  \(.key): \(.value[0:120])\(if (.value | length) > 120 then "..." else "" end)"' "$_dir/package.json" 2>/dev/null
                _ws_shown=$((_ws_shown + 1))
              done
            done
          ) 2>/dev/null
        fi
      fi
    fi

    if ((has_python)) && ! ((has_js)) && [[ -n "$pm" ]]; then
      echo "package-manager: $pm"
      case "$pm" in
      uv) echo "run-form: uv run <command>" ;;
      poetry) echo "run-form: poetry run <command>" ;;
      pipenv) echo "run-form: pipenv run <command>" ;;
      esac
    fi

    if ((has_python)) && [[ -f "$root/Makefile" ]]; then
      local _mkt
      _mkt="$(grep -E '^[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*:' "$root/Makefile" 2>/dev/null | cut -d: -f1 | tr -d '[:space:]' | sort -u || true)"
      if [[ -n "$_mkt" ]]; then
        echo "makefile-targets:"
        printf '%s\n' "$_mkt" | sed 's/^/  /'
      fi
    fi

    if ((has_python)); then
      local _jf=""
      [[ -f "$root/justfile" ]] && _jf="$root/justfile"
      [[ -f "$root/Justfile" ]] && _jf="$root/Justfile"
      if [[ -n "$_jf" ]]; then
        local _jft
        _jft="$(grep -E '^[a-zA-Z_][a-zA-Z0-9_-]*' "$_jf" 2>/dev/null | grep -v '^#' | cut -d: -f1 | sed 's/[[:space:]].*//' | sort -u || true)"
        if [[ -n "$_jft" ]]; then
          echo "justfile-targets:"
          printf '%s\n' "$_jft" | sed 's/^/  /'
        fi
      fi
    fi

    true
  )"

  [[ -z "$body" ]] && return 0

  echo ""
  echo "<tooling>"
  printf '%s\n' "$body"
  echo ""
  echo "guidance: Run scripts only through the package manager named above, prefer these scripts and run-checks.sh over direct tool invocation, and never substitute a different package manager."
  echo "</tooling>"
}

emit_required_skills "$cache_file"

emit_tooling_block "$project_root"

touch "$session_marker"
exit 0
