#!/usr/bin/env bash
# Requires bash 4.0+. Personal dotfiles; bash 5.x is installed via Brewfile.
# Emits a compact stack report for the current project or a nearby ancestor.
# Output is terse on purpose. Each line is meant to be scanned by Claude in
# under a few hundred tokens of context.
#
# Detection runs in every subproject kit_subprojects returns (the root,
# tracked anchor-sentinel directories, workspace members). One line per stack:
#   <stack>: yes (<extras>) [<package manager>] at <subproject>, ...
# The "at" part is left off when the stack is only at the root. The package
# manager is the nearest lockfile of the stack's own ecosystem, so a uv
# service under a pnpm root reports [uv].
#
# All stack knowledge (sentinels, extras detection rules, skills) lives in
# kit.yml at the kit root ($KIT_ROOT, see _lib.sh). To add a new stack or
# extend an existing one, edit that file only. No edits to this script are
# required.
#
# Requires: yq (mikefarah, installed via Brewfile)

set -euo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"
kit_stacks_load

STACKS_YML="$KIT_YML"
ROOT="$("$KIT_ROOT/bin/project-root.sh")"
cd "$ROOT"

# Load stack names in document order
mapfile -t STACK_NAMES < <(yq '.stacks | keys | .[]' "$STACKS_YML")
mapfile -t SUBPROJECTS < <(kit_subprojects "$ROOT")

# True when kit.yml's package_managers has ecosystem $1.
has_ecosystem() {
  local eco
  for eco in "${STACK_PM_ECOSYSTEMS[@]}"; do
    [[ "$eco" == "$1" ]] && return 0
  done
  return 1
}

# Evaluates a single extras entry detection rule against $loc.
# Prints the extra name if the rule matches; prints nothing otherwise.
# rule types: dep, file, grep+in, any_of
eval_extra() {
  local stack="$1" loc="$2" idx="$3"

  local name
  name="$(yq ".stacks.${stack}.extras[${idx}].name" "$STACKS_YML")"

  local rename
  rename="$(yq ".stacks.${stack}.extras[${idx}].rename // \"\"" "$STACKS_YML")"
  local token="${rename:-$name}"

  # dep: package.json dependency check
  local dep
  dep="$(yq ".stacks.${stack}.extras[${idx}].dep // \"\"" "$STACKS_YML")"
  if [[ -n "$dep" ]]; then
    if command -v jq >/dev/null 2>&1 && [[ -f "$loc/package.json" ]]; then
      local found
      found="$(jq -r '((.dependencies // {}) + (.devDependencies // {})) | keys[]' "$loc/package.json" 2>/dev/null | grep -Fx "$dep" || true)"
      if [[ -n "$found" ]]; then echo "$token"; fi
    fi
    return
  fi

  # file: existence check
  local file
  file="$(yq ".stacks.${stack}.extras[${idx}].file // \"\"" "$STACKS_YML")"
  if [[ -n "$file" ]]; then
    if [[ -f "$loc/$file" ]]; then echo "$token"; fi
    return
  fi

  # grep: + in:
  local pattern
  pattern="$(yq ".stacks.${stack}.extras[${idx}].grep // \"\"" "$STACKS_YML")"
  if [[ -n "$pattern" ]]; then
    local grep_files
    mapfile -t grep_files < <(yq ".stacks.${stack}.extras[${idx}].in[]" "$STACKS_YML" 2>/dev/null || true)
    for f in "${grep_files[@]}"; do
      if [[ -f "$loc/$f" ]] && grep -qE "$pattern" "$loc/$f" 2>/dev/null; then
        echo "$token"
        return
      fi
    done
    return
  fi

  # any_of: OR over sub-rules (supports file: and grep:+in: sub-rules)
  local any_of_count
  any_of_count="$(yq ".stacks.${stack}.extras[${idx}].any_of | length" "$STACKS_YML" 2>/dev/null || echo 0)"
  if ((any_of_count > 0)); then
    local i
    for ((i = 0; i < any_of_count; i++)); do
      local sub_file sub_pattern
      sub_file="$(yq ".stacks.${stack}.extras[${idx}].any_of[${i}].file // \"\"" "$STACKS_YML")"
      if [[ -n "$sub_file" ]] && [[ -f "$loc/$sub_file" ]]; then
        echo "$token"
        return
      fi
      sub_pattern="$(yq ".stacks.${stack}.extras[${idx}].any_of[${i}].grep // \"\"" "$STACKS_YML")"
      if [[ -n "$sub_pattern" ]]; then
        local sub_files
        mapfile -t sub_files < <(yq ".stacks.${stack}.extras[${idx}].any_of[${i}].in[]" "$STACKS_YML" 2>/dev/null || true)
        for f in "${sub_files[@]}"; do
          if [[ -f "$loc/$f" ]] && grep -qE "$sub_pattern" "$loc/$f" 2>/dev/null; then
            echo "$token"
            return
          fi
        done
      fi
    done
  fi
}

lines=()
js_loc=""

for stack in "${STACK_NAMES[@]}"; do
  locs=()
  extras_parts=()
  pm=""
  extra_count=""

  for sub in "${SUBPROJECTS[@]}"; do
    dir="$ROOT"
    [[ "$sub" == . ]] || dir="$ROOT/$sub"
    kit_dir_has_stack "$dir" "$stack" || continue
    locs+=("$sub")

    # Extras: the union across locations, in first-seen order.
    [[ -n "$extra_count" ]] || extra_count="$(yq ".stacks.${stack}.extras | length" "$STACKS_YML" 2>/dev/null || echo 0)"
    for ((i = 0; i < extra_count; i++)); do
      matched="$(eval_extra "$stack" "$sub" "$i")"
      [[ -n "$matched" ]] || continue
      [[ " ${extras_parts[*]:-} " == *" $matched "* ]] || extras_parts+=("$matched")
    done

    if [[ -z "$pm" ]] && has_ecosystem "$stack"; then
      pm="$(kit_nearest_pm_lockfile "$dir" "$stack")"
      pm="${pm%%:*}"
    fi
  done
  ((${#locs[@]} > 0)) || continue

  line="$stack: yes"
  if ((${#extras_parts[@]} > 0)); then
    line+=" ($(
      IFS=,
      echo "${extras_parts[*]}"
    ))"
  fi
  if [[ "$stack" == js ]]; then
    line+=" [${pm:-npm}]"
    js_loc="${locs[0]}"
  elif [[ -n "$pm" ]]; then
    line+=" [$pm]"
  fi
  if [[ "${locs[*]}" != . ]]; then
    locs_str="$(
      IFS=,
      echo "${locs[*]}"
    )"
    line+=" at ${locs_str//,/, }"
  fi
  lines+=("$line")
done

# Early exit: no stack in any subproject.
((${#lines[@]} > 0)) || exit 0

echo "root: $ROOT"
printf '%s\n' "${lines[@]}"

# Node version. Prefer the JS stack's first location, fall back to the root.
if [[ -n "$js_loc" ]]; then
  if [[ -f "$js_loc/.nvmrc" ]]; then
    echo "node: $(tr -d 'v\n' <"$js_loc/.nvmrc")"
  elif [[ -f .nvmrc ]]; then
    echo "node: $(tr -d 'v\n' <.nvmrc)"
  fi
fi
