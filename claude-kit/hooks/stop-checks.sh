#!/usr/bin/env bash
# Stop hook: when this turn created or edited files via
# Edit/Write/MultiEdit/NotebookEdit, runs kit.yml's file_checks on just those
# files, and blocks the stop (exit 2) on failure so Claude fixes or reports
# it. A question-only turn costs nothing. Files outside the repo, deleted
# files, and files no check claims don't count. Whole-project checks
# (run-checks.sh) are left to /code-review.

HOOK_NAME="stop-checks.sh"
# shellcheck source=../bin/_lib.sh
source "$(dirname "$0")/../bin/_lib.sh"
kit_hook_init

read_payload
require_jq

# Already continuing because of this hook: let the stop through, one retry
# per failure, so a check that can't be fixed never loops.
[[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
[[ -n "$cwd" ]] && cd "$cwd"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

[[ -r "$transcript" ]] || exit 0
# A clean tree means the edits were committed, which already went through
# verification.
[[ -n "$(git status --porcelain)" ]] || exit 0

# Only run when this turn (entries after the last real user prompt) called a
# file-editing tool. Changes made via Bash, or by the user, don't count.
# One line per edit: the file it touched, empty when the call named none.
mapfile -t edited < <(jq -rs '
  (to_entries
    | map(select(.value.type == "user" and (.value.isMeta | not)
        and ([.value.message.content | arrays | .[] | select(.type == "tool_result")] | length == 0)))
    | last.key // -1) as $start
  | .[$start + 1:][] | select(.type == "assistant") | .message.content | arrays | .[]
  | select(.type == "tool_use"
      and (.name == "Edit" or .name == "Write" or .name == "MultiEdit" or .name == "NotebookEdit"))
  | (.input.file_path // .input.notebook_path // "")
' "$transcript" 2>/dev/null)
((${#edited[@]} > 0)) || exit 0

root="$(kit_physical_path "$(git rev-parse --show-toplevel)")"
kit_stacks_load

# is_excluded <dir> <path> "<file> <dotted path>": true when <path>, relative
# to <dir>, matches a regex the TOML <file> in <dir> holds at <dotted path>
# (a string or a list of strings), as mypy's exclude does with re.search.
is_excluded() {
  local rel="${2#"$1"/}" regex
  [[ -f "$1/${3%% *}" ]] || return 1
  while IFS= read -r regex; do
    [[ -n "$regex" && "$rel" =~ $regex ]] && return 0
  done < <(yq -p toml -o json '.' "$1/${3%% *}" 2>/dev/null |
    jq -r --arg p "${3#* }" "$_KIT_GETPATH"' | if type == "array" then .[] else . end | strings' 2>/dev/null)
  return 1
}

# Group each edited file under every check that claims it, keyed by check
# index and the directory holding the check's signal file, the check's cwd.
declare -A group_files=() seen=()
group_keys=()
for path in "${edited[@]}"; do
  [[ -n "$path" ]] || continue
  [[ "$path" == /* ]] || path="$PWD/$path"
  path="$(kit_physical_path "$path")"
  [[ "$path" == "$root/"* && -f "$path" && -z "${seen[$path]:-}" ]] || continue
  seen[$path]=1
  [[ "${path##*/}" == *.* ]] || continue
  ext="${path##*.}"
  ext="${ext,,}"
  for ((i = 0; i < ${#KIT_FC_NAMES[@]}; i++)); do
    [[ " ${KIT_DISABLED_FILE_CHECKS[*]:-} " == *" ${KIT_FC_NAMES[i]} "* ]] && continue
    [[ " ${KIT_FC_EXTS[i]} " == *" $ext "* ]] || continue
    signal=""
    if [[ "${KIT_FC_FILES[i]}" != - ]]; then
      read -ra names <<<"${KIT_FC_FILES[i]}"
      signal="$(find_up "${path%/*}" "$root" "${names[@]}")"
    fi
    if [[ -z "$signal" && "${KIT_FC_TOMLS[i]}" != - ]]; then
      # Walks past a nearer TOML without the table, as ruff's own lookup does.
      from="${path%/*}"
      while toml="$(find_up "$from" "$root" "${KIT_FC_TOMLS[i]%% *}")" && [[ -n "$toml" ]]; do
        if toml_has "$toml" "${KIT_FC_TOMLS[i]#* }"; then
          signal="$toml"
          break
        fi
        [[ "${toml%/*}" != "$root" ]] || break
        from="${toml%/*/*}"
      done
    fi
    [[ -n "$signal" ]] || continue
    if [[ "${KIT_FC_SCRIPTS[i]}" != - ]]; then
      test_script="$(json_value "${signal%/*}/package.json" .scripts.test)"
      [[ " ${test_script//[^A-Za-z0-9_-]/ } " == *" ${KIT_FC_SCRIPTS[i]} "* ]] || continue
    fi
    if [[ "${KIT_FC_NEEDS[i]}" != - ]]; then
      read -ra names <<<"${KIT_FC_NEEDS[i]}"
      [[ -n "$(find_up "${signal%/*}" "$root" "${names[@]}")" ]] || continue
    fi
    if [[ "${KIT_FC_EXCLUDES[i]}" != - ]] && is_excluded "${signal%/*}" "$path" "${KIT_FC_EXCLUDES[i]}"; then
      continue
    fi
    key="$i|${signal%/*}"
    [[ -n "${group_files[$key]+set}" ]] || group_keys+=("$key")
    group_files[$key]+="$path"$'\n'
  done
done
((${#group_keys[@]} > 0)) || exit 0

# resolve_run <dir> <name> <local_only>: fills bin_cmd with the words that run
# <name> from <dir>: a project-local bin, else the first bin_lookups hit, else
# PATH unless <local_only> is true. Empty when none has it.
resolve_run() {
  local dir="$1" name="$2" local_only="$3" found j signal venv
  local -a names words
  bin_cmd=()
  found="$(kit_resolve_bin "$dir" "$root" "$name")"
  if [[ -n "$found" && "$found" == "$root/"* ]]; then
    bin_cmd=("$found")
    return 0
  fi
  for ((j = 0; j < ${#KIT_BL_NAMES[@]}; j++)); do
    read -ra names <<<"${KIT_BL_FILES[j]}"
    signal="$(find_up "$dir" "$root" "${names[@]}")"
    [[ -n "$signal" ]] || continue
    if [[ "${KIT_BL_VENVS[j]}" != - ]]; then
      read -ra words <<<"${KIT_BL_VENVS[j]}"
      command -v "${words[0]}" >/dev/null 2>&1 || continue
      venv="$(cd "${signal%/*}" && "${words[@]}" 2>/dev/null)" || continue
      if [[ -n "$venv" && -x "$venv/bin/$name" ]]; then
        bin_cmd=("$venv/bin/$name")
        return 0
      fi
    elif [[ "${KIT_BL_PROBES[j]}" != - ]]; then
      read -ra words <<<"${KIT_BL_PROBES[j]//\{bin\}/$name}"
      command -v "${words[0]}" >/dev/null 2>&1 || continue
      (cd "${signal%/*}" && "${words[@]}") >/dev/null 2>&1 || continue
      read -ra bin_cmd <<<"${KIT_BL_RUNS[j]//\{bin\}/$name}"
      return 0
    fi
  done
  [[ -n "$found" && "$local_only" != true ]] && bin_cmd=("$found")
  return 0
}

pass=0
fail=0
skip=0
report=""
failures=""
for key in "${group_keys[@]}"; do
  i="${key%%|*}"
  dir="${key#*|}"
  mapfile -t files <<<"${group_files[$key]%$'\n'}"
  label="${KIT_FC_NAMES[i]} (${#files[@]} file$( ((${#files[@]} == 1)) || echo s))"
  [[ "$dir" == "$root" ]] || label+=" [${dir#"$root"/}]"

  resolve_run "$dir" "${KIT_FC_BINS[i]}" "${KIT_FC_LOCALS[i]}"
  if ((${#bin_cmd[@]} == 0)); then
    where="not installed"
    [[ "${KIT_FC_LOCALS[i]}" == true ]] && where="not in the project environment"
    report+="SKIP $label (${KIT_FC_BINS[i]} $where)"$'\n'
    skip=$((skip + 1))
    continue
  fi

  # Substituted word by word, so a path with spaces stays one argument.
  parts=()
  read -ra words <<<"${KIT_FC_CMDS[i]}"
  for word in "${words[@]}"; do
    if [[ "$word" == *"{files}"* ]]; then
      for file in "${files[@]}"; do
        parts+=("${word//\{files\}/$file}")
      done
    elif [[ "$word" == *"{dirs}"* ]]; then
      dirs=()
      for file in "${files[@]}"; do
        rel="./${file#"$dir"/}"
        rel="${rel%/*}"
        [[ " ${dirs[*]:-} " == *" $rel "* ]] || dirs+=("$rel")
      done
      for rel in "${dirs[@]}"; do
        parts+=("${word//\{dirs\}/$rel}")
      done
    elif [[ "$word" == "{bin}" ]]; then
      parts+=("${bin_cmd[@]}")
    else
      parts+=("$word")
    fi
  done

  if out="$(cd "$dir" && "${parts[@]}" 2>&1)"; then
    report+="PASS $label"$'\n'
    pass=$((pass + 1))
  else
    report+="FAIL $label"$'\n'
    # The tail: linters print findings and the summary last, after preambles
    # like rubocop's unconfigured-cops notice.
    failures+="FAIL $label"$'\n'"$(printf '%s\n' "$out" | tail -30)"$'\n'
    fail=$((fail + 1))
  fi
done

summary="checks: $pass passed, $fail failed, $skip skipped"
((fail == 0)) || block "file checks failed; fix them or report and stop.
${failures}${summary}" "checks-failed"

jq -n --arg msg "$HOOK_NAME: ${report}${summary}" '{systemMessage: $msg}'
exit 0
