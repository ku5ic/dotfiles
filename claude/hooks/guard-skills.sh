#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit, Read. Blocks edits/reads of
# mapped file types until the required patterns skill is loaded for this
# session - one extra round trip per skill-set per session, by design.
# Callable standalone (also the sole PreToolUse Read hook) or sourced by
# guard-dispatch.sh for the Edit|Write|MultiEdit path.
HOOK_NAME="guard-skills.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

run_guard_skills() {
  # See run_guard_edit.sh - same HOOK_NAME shadowing need.
  local HOOK_NAME="guard-skills.sh"
  path="$(extract_path)"
  [[ -z "$path" ]] && return 0

  case "$path" in
  */.claude/scratch/* | */scratch/*) return 0 ;;
  esac

  session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
  [[ -z "$session_id" ]] && return 0

  tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
  case "$tool_name" in
  Read) verb="read" ;;
  *) verb="edit" ;;
  esac

  stacks_yml="$HOME/.claude/_stacks.yml"
  command -v yq >/dev/null 2>&1 || return 0
  [[ -f "$stacks_yml" ]] || return 0

  # Full skill_file_map in one yq call, cached to disk while _stacks.yml is
  # unchanged. Each line: on<TAB>globs-space-separated<TAB>skills-space-separated
  map_cache="$HOME/.claude/cache/skill-map"
  if [[ -s "$map_cache" && "$map_cache" -nt "$stacks_yml" ]]; then
    mapfile -t map_entries <"$map_cache"
  else
    mapfile -t map_entries < <(
      yq -r '.skill_file_map // [] | .[] | [.on, (.globs // [] | join(" ")), (.skills // [] | join(" "))] | join("\t")' \
        "$stacks_yml" 2>/dev/null
    )
    if ((${#map_entries[@]} > 0)); then
      mkdir -p "$(dirname "$map_cache")" 2>/dev/null || true
      printf '%s\n' "${map_entries[@]}" >"$map_cache" 2>/dev/null || true
    fi
  fi
  [[ ${#map_entries[@]} -eq 0 ]] && return 0

  basename_target="$(basename "$path")"
  declare -A seen_skills=()
  required_skills=()

  for entry in "${map_entries[@]}"; do
    IFS=$'\t' read -r on globs_str skills_str <<<"$entry"
    case "$on" in
    basename) target="$basename_target" ;;
    path) target="$path" ;;
    *) continue ;;
    esac

    read -ra globs <<<"$globs_str"
    matched=0
    for glob in "${globs[@]}"; do
      # Unquoted so bash treats $glob as a pattern, not a literal string.
      # shellcheck disable=SC2053
      [[ "$target" == $glob ]] && matched=1 && break
    done
    ((matched)) || continue

    read -ra entry_skills <<<"$skills_str"
    for sk in "${entry_skills[@]}"; do
      [[ -z "$sk" ]] && continue
      if [[ -z "${seen_skills[$sk]:-}" ]]; then
        seen_skills[$sk]=1
        required_skills+=("$sk")
      fi
    done
  done

  [[ ${#required_skills[@]} -eq 0 ]] && return 0

  cache_dir="$HOME/.claude/cache/skills-loaded"

  declare -a to_check=()
  for sk in "${required_skills[@]}"; do
    [[ -f "$cache_dir/${session_id}-${sk}" ]] || to_check+=("$sk")
  done

  [[ ${#to_check[@]} -eq 0 ]] && return 0

  skills_log="$HOME/.claude/logs/skills.jsonl"
  # Missing or unreadable log: fail open rather than block on uncertainty.
  [[ -r "$skills_log" ]] || return 0

  mkdir -p "$cache_dir" 2>/dev/null || true

  declare -a missing=()
  for sk in "${to_check[@]}"; do
    found=""
    # Accept exact skill_file match (Skill tool) or path match (Read of
    # <skill>/SKILL.md). Excludes inject-context.sh's synthetic
    # required-skill/suggested-skill markers, which mean "surfaced", not
    # "loaded" - without the exclusion either would satisfy the check for a
    # skill never actually invoked.
    found="$(jq -rs --arg sid "$session_id" --arg sk "$sk" \
      'any(.[]; .session_id == $sid and .skill_file != null
        and .event != "required-skill" and .event != "suggested-skill"
        and (
        .skill_file == $sk or
        (.skill_file | contains("/skills/" + $sk + "/"))
      ))' \
      "$skills_log" 2>/dev/null)" || true
    if [[ "$found" == "true" ]]; then
      touch "$cache_dir/${session_id}-${sk}" 2>/dev/null || true
    else
      missing+=("$sk")
    fi
  done

  [[ ${#missing[@]} -eq 0 ]] && return 0

  missing_list="$(printf '%s, ' "${missing[@]}")"
  missing_list="${missing_list%, }"

  log_block "skills-not-loaded" "$path"
  echo "This $verb touches $path. Load the following skills via the Skill tool first, then retry the $verb: $missing_list" >&2
  exit 2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  read_payload
  require_jq
  run_guard_skills
fi
