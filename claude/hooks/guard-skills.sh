#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit.
# Blocks edits to mapped file types until the required patterns skill is loaded
# for this session. One extra round trip per skill-set per session by design;
# that is the enforcement cost and it is accepted.
HOOK_NAME="guard-skills.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"
[[ -z "$path" ]] && exit 0

session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
[[ -z "$session_id" ]] && exit 0

stacks_yml="$HOME/.claude/_stacks.yml"
command -v yq >/dev/null 2>&1 || exit 0
[[ -f "$stacks_yml" ]] || exit 0

# Load the full skill_file_map in one yq call.
# Each output line: on<TAB>globs-space-separated<TAB>skills-space-separated
# If the map is absent or yq fails, map_entries is empty and we exit below.
mapfile -t map_entries < <(
  yq -r '.skill_file_map // [] | .[] | [.on, (.globs // [] | join(" ")), (.skills // [] | join(" "))] | join("\t")' \
    "$stacks_yml" 2>/dev/null
)
[[ ${#map_entries[@]} -eq 0 ]] && exit 0

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
    # Unquoted glob so bash treats it as a pattern, not a literal string.
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

[[ ${#required_skills[@]} -eq 0 ]] && exit 0

skills_log="$HOME/.claude/logs/skills.jsonl"
# Missing or unreadable log: fail open. Without the log we cannot determine
# what has been loaded, and blocking on uncertainty causes false positives.
[[ -r "$skills_log" ]] || exit 0

declare -a missing=()
for sk in "${required_skills[@]}"; do
  found=""
  # Accept: exact skill_file match (PreToolUse Skill or required-skill events) OR
  # path-based match (PostToolUse Read of <skill>/SKILL.md, which is the reliable
  # logged signal when the Skill tool loads a skill and Claude reads its file).
  found="$(jq -rs --arg sid "$session_id" --arg sk "$sk" \
    'any(.[]; .session_id == $sid and .skill_file != null and (
      .skill_file == $sk or
      (.skill_file | contains("/skills/" + $sk + "/"))
    ))' \
    "$skills_log" 2>/dev/null)" || true
  [[ "$found" == "true" ]] || missing+=("$sk")
done

[[ ${#missing[@]} -eq 0 ]] && exit 0

missing_list="$(printf '%s, ' "${missing[@]}")"
missing_list="${missing_list%, }"

log_block "skills-not-loaded" "$path"
echo "This edit touches $path. Load the following skills via the Skill tool first, then retry the edit: $missing_list" >&2
exit 2
