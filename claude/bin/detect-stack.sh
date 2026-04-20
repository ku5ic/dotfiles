#!/usr/bin/env bash
# ~/.claude/bin/detect-stack.sh
# Emits a compact stack report for the current project or a nearby ancestor.
# Output is terse on purpose. Each line is meant to be scanned by Claude in
# under a few hundred tokens of context.

set -euo pipefail

# Walk up at most 3 levels to find a project anchor. Some projects nest a
# backend inside a subfolder (e.g. zanakadric/backend), which is handled
# separately below.
find_root() {
  local dir="$PWD" depth=0
  while [[ "$dir" != "/" && $depth -lt 3 ]]; do
    for f in package.json pyproject.toml Gemfile Cargo.toml go.mod; do
      [[ -f "$dir/$f" ]] && { echo "$dir"; return; }
    done
    [[ -d "$dir/.git" ]] && { echo "$dir"; return; }
    dir="$(dirname "$dir")"
    depth=$((depth + 1))
  done
  echo "$PWD"
}

ROOT="$(find_root)"
cd "$ROOT"

echo "root: $ROOT"

# JavaScript and TypeScript
if [[ -f package.json ]]; then
  parts=()
  [[ -f tsconfig.json || -f tsconfig.base.json ]] && parts+=("typescript")

  if command -v jq >/dev/null 2>&1; then
    # Merge dependencies and devDependencies, then emit each key.
    deps=$(jq -r '((.dependencies // {}) + (.devDependencies // {})) | keys[]' package.json 2>/dev/null || true)
    for pkg in next react vue @angular/core svelte express fastify @nestjs/core tailwindcss vitest jest @playwright/test cypress eslint prettier @biomejs/biome; do
      if echo "$deps" | grep -qx "$pkg"; then
        # Shorten common scoped names for readability.
        case "$pkg" in
          @angular/core) parts+=("angular") ;;
          @nestjs/core)  parts+=("nestjs") ;;
          @playwright/test) parts+=("playwright") ;;
          @biomejs/biome) parts+=("biome") ;;
          *) parts+=("$pkg") ;;
        esac
      fi
    done
  fi

  pm="npm"
  [[ -f pnpm-lock.yaml ]] && pm="pnpm"
  [[ -f yarn.lock ]] && pm="yarn"
  [[ -f bun.lockb ]] && pm="bun"

  if [[ ${#parts[@]} -gt 0 ]]; then
    joined=$(IFS=', '; echo "${parts[*]}")
    echo "js: yes (${joined}) [$pm]"
  else
    echo "js: yes [$pm]"
  fi

  [[ -f .nvmrc ]] && echo "node: $(tr -d 'v\n' < .nvmrc)"
else
  echo "js: no"
fi

# Python. Also check common backend subfolders for dual-stack projects.
py_loc=""
for dir in . backend server api; do
  if [[ -f "$dir/pyproject.toml" || -f "$dir/requirements.txt" || -f "$dir/manage.py" || -f "$dir/Pipfile" ]]; then
    py_loc="$dir"
    break
  fi
done

if [[ -n "$py_loc" ]]; then
  py_parts=()
  [[ -f "$py_loc/manage.py" ]] && py_parts+=("django")

  for f in "$py_loc/pyproject.toml" "$py_loc/requirements.txt" "$py_loc/Pipfile"; do
    [[ -f "$f" ]] || continue
    grep -qiE '^[ "]*(django|Django)' "$f" 2>/dev/null && py_parts+=("django")
    grep -qiE '^[ "]*fastapi' "$f" 2>/dev/null && py_parts+=("fastapi")
    grep -qiE '^[ "]*flask' "$f" 2>/dev/null && py_parts+=("flask")
    grep -qiE '^[ "]*pytest' "$f" 2>/dev/null && py_parts+=("pytest")
    grep -qiE '^[ "]*ruff' "$f" 2>/dev/null && py_parts+=("ruff")
    grep -qiE '^[ "]*mypy' "$f" 2>/dev/null && py_parts+=("mypy")
  done
  [[ -f "$py_loc/conftest.py" || -f "$py_loc/pytest.ini" ]] && py_parts+=("pytest")

  # Deduplicate while preserving order.
  py_uniq=$(printf "%s\n" "${py_parts[@]}" | awk '!seen[$0]++' | paste -sd ", " -)

  loc_note=""
  [[ "$py_loc" != "." ]] && loc_note=" at $py_loc/"

  if [[ -n "$py_uniq" ]]; then
    echo "python: yes${loc_note} (${py_uniq})"
  else
    echo "python: yes${loc_note}"
  fi
else
  echo "python: no"
fi

# Ruby
if [[ -f Gemfile ]]; then
  rb=""
  [[ -f config/routes.rb && -d app/controllers ]] && rb=" (rails)"
  echo "ruby: yes${rb}"
else
  echo "ruby: no"
fi

# Rust
if [[ -f Cargo.toml ]]; then
  echo "rust: yes"
else
  echo "rust: no"
fi

# Monorepo signals. Only print if at least one is present.
mono=()
[[ -f pnpm-workspace.yaml ]] && mono+=("pnpm-workspaces")
[[ -f turbo.json ]] && mono+=("turbo")
[[ -f nx.json ]] && mono+=("nx")
[[ -f lerna.json ]] && mono+=("lerna")
if [[ ${#mono[@]} -gt 0 ]]; then
  joined_mono=$(IFS=','; echo "${mono[*]}")
  echo "monorepo: yes (${joined_mono})"
fi
