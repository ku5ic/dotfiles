#!/usr/bin/env bash
# SessionStart hook. Prepends repo context at session start/resume/compact/
# clear. The harness itself guarantees this fires once per boundary (matcher:
# startup|resume|compact|clear in settings.json) -- no self-dedup needed here.
HOOK_NAME="inject-context.sh"

# Every guard fails open (exit 0) without these, so say so at session start.
# Runs before bin/_lib.sh, which needs bash 4.2+, and so before strict mode:
# bash 3.2 syntax only, and the JSON is built with printf because jq may be
# the thing missing.
check_prereqs() {
  local missing="" kit_rules entry linked=0
  if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
    missing="${missing} bash 4.2+ (found ${BASH_VERSION}; brew install bash, and put it first on PATH);"
  fi
  if ! command -v jq >/dev/null 2>&1; then
    missing="${missing} jq (brew install jq);"
  fi
  if ! yq --version 2>/dev/null | grep -q mikefarah; then
    missing="${missing} mikefarah yq (brew install yq);"
  fi
  kit_rules="$(cd -P "$(dirname "$0")/../rules" 2>/dev/null && pwd || true)"
  # KIT_HOME's default, inlined: this runs before the lib is sourced.
  for entry in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/rules/*; do
    if [ -d "$entry" ] && [ "$(cd -P "$entry" 2>/dev/null && pwd)" = "$kit_rules" ]; then
      linked=1
    fi
  done
  if [ "$linked" -eq 0 ]; then
    missing="${missing} the kit rules linked under ~/.claude/rules (run bootstrap.sh);"
  fi
  # KIT_ROOT's default, inlined for the same reason.
  if [ ! -r "${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/kit.yml" ]; then
    missing="${missing} a readable kit.yml at the kit root (run bootstrap.sh);"
  fi
  if [ -n "$missing" ]; then
    printf '{"systemMessage":"claude-kit guards fail open until this is fixed. Missing:%s"}\n' "${missing%;}"
    exit 0
  fi
}
check_prereqs

# shellcheck source=../bin/_lib.sh
source "$(dirname "$0")/../bin/_lib.sh"
kit_hook_init

payload=""
read_payload
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"

project_name="$("$KIT_ROOT/bin/project-name.sh" 2>/dev/null || echo "unknown")"

# Skip injection for non-project contexts.
case "$project_name" in
home | root | unknown)
  exit 0
  ;;
esac

project_root="$("$KIT_ROOT/bin/project-root.sh" 2>/dev/null || echo "")"
[[ -z "$project_root" ]] && exit 0

cache_file="$(stack_cache_file "$project_name" "$project_root")"
refresh_stack_cache_if_stale "$project_root" "$cache_file"

if [[ -s "$cache_file" ]]; then
  echo ""
  echo "<repo-context>"
  cat "$cache_file"
  echo "branch (at session start): $(git -C "$project_root" branch --show-current 2>/dev/null || echo unknown)"
  dirty="$(git -C "$project_root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')" || dirty="unknown"
  echo "dirty-files (at session start): $dirty"
  echo "</repo-context>"
fi

# Only global_skills are emitted here; stack-derived skills go through
# emit_suggested_skills so session start only blocks on the core set. Not
# gated on the stack cache being non-empty: global_skills apply to every
# project regardless of detected stack (a docs-only or config-only repo
# still deserves them - the earlier `project_name` exit above already
# filters out non-project contexts).
emit_required_skills() {
  local yml="$KIT_YML"

  [[ -f "$yml" ]] || return 0
  command -v yq >/dev/null 2>&1 || return 0

  local -a required=()
  mapfile -t required < <(global_skills_list "$yml")
  [[ ${#required[@]} -eq 0 ]] && return 0

  render_required_skills_block "$yml"

  local sk
  for sk in "${required[@]}"; do
    log_event skills required-skill cwd "$cwd" skill_file "$sk"
  done
}

# Skills already in global_skills are excluded (required, not suggested).
# Logged as event:"suggested-skill" so skills-report.sh can measure whether a
# suggestion was ever acted on - this records "surfaced", not "loaded";
# log-skills.sh's Skill-tool/Read entries are the only record of an
# actual invocation.
emit_suggested_skills() {
  local cache="$1"
  local yml="$KIT_YML"

  [[ -s "$cache" ]] || return 0
  [[ -f "$yml" ]] || return 0
  command -v yq >/dev/null 2>&1 || return 0

  local -a suggested=()
  mapfile -t suggested < <(stacks_signals_from_cache "$cache" | suggested_skills_from_signals "$yml")
  [[ ${#suggested[@]} -eq 0 ]] && return 0

  render_suggested_skills_block "$yml" "$cache"

  local sk
  for sk in "${suggested[@]}"; do
    log_event skills suggested-skill cwd "$cwd" skill_file "$sk"
  done
}

# Emits a <tooling> block computed live (not from the stack cache): for each
# subproject, the run form of every task kit.yml's task_providers find and of
# every toolchain check its stacks get. The same lists run-checks.sh reads, so
# Claude is never told about a task the checks skip, or the reverse.
emit_tooling_block() {
  local root="$1"

  local body
  body="$(
    set +e
    local pm sub dir header shown=0 max=20 i
    local -a lines
    kit_stacks_load
    pm="$(resolve_package_manager "$root" 2>/dev/null)"
    [[ -n "$pm" ]] && echo "package-manager: $pm"

    while IFS= read -r sub; do
      lines=()
      dir="$root"
      header="tasks:"
      if [[ "$sub" != . ]]; then
        dir="$root/$sub"
        header="tasks [$sub]:"
      fi
      mapfile -t lines < <(kit_tasks "$dir" | cut -f4)
      for ((i = 0; i < ${#KIT_TC_STACKS[@]}; i++)); do
        if kit_dir_has_stack "$dir" "${KIT_TC_STACKS[i]}"; then
          lines+=("${KIT_TC_CMDS[i]}")
        fi
      done
      ((${#lines[@]} > 0)) || continue
      if [[ "$sub" != . ]]; then
        if ((shown >= max)); then
          echo "(subprojects capped at $max; run-checks.sh covers all)"
          break
        fi
        shown=$((shown + 1))
      fi
      echo "$header"
      printf '  %s\n' "${lines[@]}"
    done < <(kit_subprojects "$root")
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

emit_required_skills

emit_suggested_skills "$cache_file"

emit_tooling_block "$project_root"

exit 0
