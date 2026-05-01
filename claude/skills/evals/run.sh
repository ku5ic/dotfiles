#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Skills evals runner. Manual-grade. Prepares inputs; user runs prompts in Claude and grades.
# Schema matches skill-creator's documented format.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="${SCRIPT_DIR}/scenarios"
FIXTURES_DIR="${SCRIPT_DIR}/fixtures"

usage() {
  cat <<'EOF'
Usage:
  run.sh list                        List skills with available evals
  run.sh <skill-name>                Run all evals for a skill
  run.sh <skill-name> <eval-id>      Run a specific eval (integer id)
  run.sh --schema                    Print the evals.json schema

Examples:
  run.sh wcag-audit
  run.sh engineering-fundamentals 2
EOF
}

print_schema() {
  cat <<'EOF'
evals.json schema (matches skill-creator):

{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "Task prompt",
      "files": ["fixture.ext"],
      "expected_output": "Description of expected result",
      "assertions": []
    }
  ]
}

Fields:
  skill_name        - must match a directory under ~/.dotfiles/claude/skills/
  evals             - array, three minimum per skill
  id                - integer, 1-indexed
  prompt            - exact user text
  files             - optional, paths relative to fixtures/
  expected_output   - description for manual grading
  assertions        - reserved for automated grading; empty for manual mode
EOF
}

list_skills() {
  local count=0
  for d in "${SCENARIOS_DIR}"/*/; do
    [[ -d "$d" ]] || continue
    local skill
    skill="$(basename "$d")"
    local file="${d}evals.json"
    if [[ ! -f "$file" ]]; then
      printf '%-30s (no evals.json)\n' "$skill"
      continue
    fi
    local n
    n="$(jq '.evals | length' "$file")"
    printf '%-30s %s eval(s)\n' "$skill" "$n"
    count=$((count + 1))
  done
  if [[ $count -eq 0 ]]; then
    echo "No evals found in ${SCENARIOS_DIR}" >&2
    exit 1
  fi
}

print_eval() {
  local file="$1"
  local idx="$2"
  local skill_name
  skill_name="$(jq -r '.skill_name' "$file")"
  local eval_id prompt expected
  eval_id="$(jq -r ".evals[$idx].id" "$file")"
  prompt="$(jq -r ".evals[$idx].prompt" "$file")"
  expected="$(jq -r ".evals[$idx].expected_output" "$file")"

  printf '\n=== %s / eval %s ===\n' "$skill_name" "$eval_id"
  printf '\nPROMPT:\n%s\n' "$prompt"

  local files_count
  files_count="$(jq ".evals[$idx].files | length // 0" "$file")"
  if [[ "$files_count" -gt 0 ]]; then
    printf '\nFIXTURES:\n'
    local i=0
    while [[ $i -lt $files_count ]]; do
      local fixture
      fixture="$(jq -r ".evals[$idx].files[$i]" "$file")"
      printf '  %s\n' "${FIXTURES_DIR}/${fixture}"
      i=$((i + 1))
    done
  fi

  printf '\nEXPECTED OUTPUT:\n%s\n' "$expected"

  printf '\n--- Copy PROMPT into Claude with %s loaded. Grade against EXPECTED OUTPUT. ---\n' "$skill_name"
}

run_evals() {
  local skill_name="$1"
  local eval_id="${2:-}"
  local file="${SCENARIOS_DIR}/${skill_name}/evals.json"

  if [[ ! -f "$file" ]]; then
    echo "No evals file for skill: $skill_name" >&2
    echo "Looked at: $file" >&2
    exit 1
  fi

  if [[ -z "$eval_id" ]]; then
    local total
    total="$(jq '.evals | length' "$file")"
    local i=0
    while [[ $i -lt $total ]]; do
      print_eval "$file" "$i"
      i=$((i + 1))
    done
    return
  fi

  local idx
  idx="$(jq --argjson id "$eval_id" '.evals | map(.id) | index($id)' "$file")"
  if [[ "$idx" == "null" ]]; then
    echo "Eval id not found: $eval_id" >&2
    echo "Available eval ids in $skill_name:" >&2
    jq -r '.evals[].id | "  " + (. | tostring)' "$file" >&2
    exit 1
  fi

  print_eval "$file" "$idx"
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    -h|--help)
      usage
      ;;
    --schema)
      print_schema
      ;;
    list)
      list_skills
      ;;
    *)
      run_evals "$@"
      ;;
  esac
}

main "$@"
