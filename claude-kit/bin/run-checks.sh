#!/usr/bin/env bash
# Runs a project's declared checks in every subproject kit_subprojects finds:
# the repo root, directories holding a tracked anchor sentinel, and workspace
# members. What counts as a task, and how it runs, is kit.yml data:
#   task_providers    where each runner declares tasks, and its run form
#   checks            which task names count as typecheck, lint, format-check,
#                     and test
#   toolchain_checks  a stack's own check commands (cargo, go), run where that
#                     stack is detected
# It never invokes a third-party linter binary directly off a config file. A
# check with no declared task is skipped, not synthesized.
#
# Output contract, parsed by hooks/stop-checks.sh: one PASS, FAIL, or SKIP
# line per check, labeled "<stack>: <check> (<task>) [<subproject>]" (a
# provider without a stack labels with its own name; the root has no
# [<subproject>]), then a final "checks: N passed, N failed, N skipped" line.
# Exit status is the failure count. Each check is independent: failures are
# reported, not aborted.
#
#   run-checks.sh                      every subproject
#   run-checks.sh --only . services/api  only these (as kit_subprojects names
#                                        them; "." is the root)
set -uo pipefail

only=()
if [[ "${1:-}" == --only ]]; then
  shift
  only=("$@")
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 1

# shellcheck source=_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
kit_stacks_load

pass=0
fail=0
skip=0

# run <label> <dir> <command...>: runs the command in <dir>.
run() {
  local label="$1" dir="$2"
  shift 2
  local out
  # Portable template: `mktemp -t <prefix>` differs between BSD (macOS) and GNU
  # (Linux CI); an explicit path template with X's behaves the same on both.
  out="$(mktemp "${TMPDIR:-/tmp}/run-checks.XXXXXX")"
  if (cd "$dir" && "$@") >"$out" 2>&1; then
    echo "PASS $label"
    pass=$((pass + 1))
  else
    echo "FAIL $label ($*)"
    head -30 "$out"
    fail=$((fail + 1))
  fi
  rm -f "$out"
}

skip_msg() {
  echo "SKIP $1"
  skip=$((skip + 1))
}

# True when task name $2 matches any glob in the space-separated list $1.
matches_any() {
  local glob
  local -a globs
  read -ra globs <<<"$1"
  for glob in "${globs[@]}"; do
    # shellcheck disable=SC2053  # a glob on purpose
    [[ "$2" == $glob ]] && return 0
  done
  return 1
}

check_subproject() {
  local sub="$1" dir="$root" sfx="" i
  if [[ "$sub" != . ]]; then
    dir="$root/$sub"
    sfx=" [$sub]"
  fi

  local -a task_labels=() task_names=() task_cmds=()
  local provider stack task cmd
  while IFS=$'\t' read -r provider stack task cmd; do
    [[ "$stack" == - ]] && stack="$provider"
    task_labels+=("$stack")
    task_names+=("$task")
    task_cmds+=("$cmd")
  done < <(kit_tasks "$dir")

  # SKIP lines take the first present provider's stack (else its name), so a
  # package.json with no scripts still reports what it lacks.
  local skip_label=""
  while IFS=$'\t' read -r provider stack; do
    if [[ "$stack" != - ]]; then
      skip_label="$stack"
      break
    fi
    [[ -n "$skip_label" ]] || skip_label="$provider"
  done < <(kit_providers "$dir")

  local check j matched
  local -a parts
  for ((i = 0; i < ${#KIT_CHECK_NAMES[@]}; i++)); do
    check="${KIT_CHECK_NAMES[i]}"
    matched=0
    for ((j = 0; j < ${#task_names[@]}; j++)); do
      matches_any "${KIT_CHECK_TASKS[i]}" "${task_names[j]}" || continue
      if [[ "${KIT_CHECK_EXCLUDES[i]}" != - ]] && matches_any "${KIT_CHECK_EXCLUDES[i]}" "${task_names[j]}"; then
        continue
      fi
      matched=1
      read -ra parts <<<"${task_cmds[j]}"
      run "${task_labels[j]}: $check (${task_names[j]})$sfx" "$dir" "${parts[@]}"
    done
    if ((! matched)) && [[ -n "$skip_label" ]]; then
      skip_msg "$skip_label: $check$sfx (no $check task)"
    fi
  done

  local bin tc_cmd found
  local -a bins
  for ((i = 0; i < ${#KIT_TC_STACKS[@]}; i++)); do
    kit_dir_has_stack "$dir" "${KIT_TC_STACKS[i]}" || continue
    local label="${KIT_TC_STACKS[i]}: ${KIT_TC_NAMES[i]}$sfx"
    if [[ "${KIT_TC_WHEN_DIRS[i]}" != - && ! -d "$dir/${KIT_TC_WHEN_DIRS[i]}" ]]; then
      skip_msg "$label (no ${KIT_TC_WHEN_DIRS[i]}/ yet)"
      continue
    fi
    tc_cmd="${KIT_TC_CMDS[i]}"
    if [[ "${KIT_TC_BINS[i]}" != - ]]; then
      found=""
      read -ra bins <<<"${KIT_TC_BINS[i]}"
      for bin in "${bins[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
          found="$bin"
          break
        fi
      done
      if [[ -z "$found" ]]; then
        skip_msg "$label (none of ${KIT_TC_BINS[i]} on PATH)"
        continue
      fi
      tc_cmd="${tc_cmd//\{bin\}/$found}"
    fi
    read -ra parts <<<"$tc_cmd"
    run "$label" "$dir" "${parts[@]}"
  done
}

while IFS= read -r sub; do
  if ((${#only[@]} > 0)) && [[ " ${only[*]} " != *" $sub "* ]]; then
    continue
  fi
  check_subproject "$sub"
done < <(kit_subprojects "$root")

echo ""
echo "checks: $pass passed, $fail failed, $skip skipped"
exit "$fail"
