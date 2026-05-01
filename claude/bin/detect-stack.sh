#!/usr/bin/env bash
# Requires bash 4.0+. Personal dotfiles; bash 5.x is installed via Brewfile.
# Emits a compact stack report for the current project or a nearby ancestor.
# Output is terse on purpose. Each line is meant to be scanned by Claude in
# under a few hundred tokens of context.
#
# Adding a new stack (illustrative; not a live example):
#
#   stacks+=(elixir)
#   stack_sentinels[elixir]="mix.exs"
#   stack_extras_fn[elixir]=     # leave empty for presence-only
#
# Optional extras function (parts on line 1, suffix on line 2):
#
#   elixir_extras() {
#     local loc="$1" parts=()
#     [[ -f "$loc/lib/<app>_web.ex" ]] && parts+=("phoenix")
#     local IFS=', '; echo "${parts[*]}"; echo ""
#   }
#
# That is the entire diff. No edits to the main loop, no edits to the
# early-return list, no edits to emit_stack.

set -euo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

ROOT="$("$HOME/.claude/bin/project-root.sh")"
cd "$ROOT"

stacks=(js python ruby rust go docker monorepo)

# Per-stack categorization of sentinels. The union of values here must equal
# STACK_SENTINELS_FULL in _lib.sh; inject-context.sh relies on that union for
# cache invalidation. Add new sentinels to _lib.sh AND here.
declare -A stack_sentinels=(
  [js]="package.json"
  [python]="pyproject.toml requirements.txt Pipfile manage.py"
  [ruby]="Gemfile"
  [rust]="Cargo.toml"
  [go]="go.mod"
  [docker]="Dockerfile docker-compose.yml docker-compose.yaml compose.yml compose.yaml"
  [monorepo]="pnpm-workspace.yaml turbo.json nx.json lerna.json"
)

declare -A stack_extras_fn=(
  [js]=js_extras
  [python]=python_extras
  [ruby]=ruby_extras
  [monorepo]=monorepo_extras
)

# Per-stack overrides only. Missing entries fall back to default_search_dirs.
declare -A stack_search_dirs=()

default_search_dirs=(. frontend client web app backend server api)

stack_dirs() {
  local name="$1"
  if [[ -n "${stack_search_dirs[$name]:-}" ]]; then
    echo "${stack_search_dirs[$name]}"
  else
    echo "${default_search_dirs[*]}"
  fi
}

find_stack_dir() {
  local name="$1"
  local sentinels="${stack_sentinels[$name]}"
  local dirs
  dirs="$(stack_dirs "$name")"
  for dir in $dirs; do
    for sentinel in $sentinels; do
      if [[ -f "$dir/$sentinel" ]]; then
        echo "$dir"
        return 0
      fi
    done
  done
}

emit_stack() {
  local name="$1" loc="$2" parts="$3" suffix="$4"
  local line="$name: yes"
  [[ "$loc" != "." ]] && line+=" at $loc/"
  [[ -n "$parts" ]] && line+=" ($parts)"
  [[ -n "$suffix" ]] && line+=" $suffix"
  echo "$line"
}

js_extras() {
  local loc="$1" parts=()
  [[ -f "$loc/tsconfig.json" || -f "$loc/tsconfig.base.json" ]] && parts+=("typescript")

  if command -v jq >/dev/null 2>&1; then
    local deps
    deps=$(jq -r '((.dependencies // {}) + (.devDependencies // {})) | keys[]' "$loc/package.json" 2>/dev/null || true)
    for pkg in next nuxt react vue @angular/core svelte express fastify @nestjs/core tailwindcss vitest jest @playwright/test cypress eslint prettier @biomejs/biome; do
      if echo "$deps" | grep -qx "$pkg"; then
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

  local pm="npm"
  [[ -f "$loc/pnpm-lock.yaml" ]] && pm="pnpm"
  [[ -f "$loc/yarn.lock" ]] && pm="yarn"
  [[ -f "$loc/bun.lockb" ]] && pm="bun"

  local IFS=', '
  echo "${parts[*]}"
  echo "[$pm]"
}

python_extras() {
  local loc="$1" parts=()
  [[ -f "$loc/manage.py" ]] && parts+=("django")

  for f in "$loc/pyproject.toml" "$loc/requirements.txt" "$loc/Pipfile"; do
    [[ -f "$f" ]] || continue
    grep -qiE '^[ "]*(django|Django)' "$f" 2>/dev/null && parts+=("django")
    grep -qiE '^[ "]*djangorestframework' "$f" 2>/dev/null && parts+=("drf")
    grep -qiE '^[ "]*fastapi' "$f" 2>/dev/null && parts+=("fastapi")
    grep -qiE '^[ "]*flask' "$f" 2>/dev/null && parts+=("flask")
    grep -qiE '^[ "]*pytest' "$f" 2>/dev/null && parts+=("pytest")
    grep -qiE '^[ "]*ruff' "$f" 2>/dev/null && parts+=("ruff")
    grep -qiE '^[ "]*mypy' "$f" 2>/dev/null && parts+=("mypy")
  done
  [[ -f "$loc/conftest.py" || -f "$loc/pytest.ini" ]] && parts+=("pytest")

  if [[ ${#parts[@]} -gt 0 ]]; then
    printf "%s\n" "${parts[@]}" | awk '!seen[$0]++' | paste -sd ", " -
  else
    echo ""
  fi
  echo ""
}

ruby_extras() {
  local loc="$1" parts=()
  [[ -f "$loc/config/routes.rb" && -d "$loc/app/controllers" ]] && parts+=("rails")
  local IFS=', '
  echo "${parts[*]}"
  echo ""
}

monorepo_extras() {
  local loc="$1" parts=()
  [[ -f "$loc/pnpm-workspace.yaml" ]] && parts+=("pnpm-workspaces")
  [[ -f "$loc/turbo.json" ]] && parts+=("turbo")
  [[ -f "$loc/nx.json" ]] && parts+=("nx")
  [[ -f "$loc/lerna.json" ]] && parts+=("lerna")
  local IFS=','
  echo "${parts[*]}"
  echo ""
}

# Generate the early-return sentinel list from the same config so the main
# loop and the short-circuit cannot drift out of sync.
all_sentinels=()
for stack in "${stacks[@]}"; do
  for dir in $(stack_dirs "$stack"); do
    for sentinel in ${stack_sentinels[$stack]}; do
      all_sentinels+=("$dir/$sentinel")
    done
  done
done

has_stack=0
for f in "${all_sentinels[@]}"; do
  if [[ -f "$f" ]]; then has_stack=1; break; fi
done
(( has_stack )) || exit 0

echo "root: $ROOT"

js_loc=""
for stack in "${stacks[@]}"; do
  loc=$(find_stack_dir "$stack")
  [[ -z "$loc" ]] && continue
  fn="${stack_extras_fn[$stack]:-}"
  # shellcheck disable=SC2178,SC2128  # extras functions output two strings via mapfile
  extras_parts=""
  extras_suffix=""
  if [[ -n "$fn" ]]; then
    mapfile -t out < <("$fn" "$loc")
    extras_parts="${out[0]:-}"
    extras_suffix="${out[1]:-}"
  fi
  emit_stack "$stack" "$loc" "$extras_parts" "$extras_suffix"
  [[ "$stack" == "js" ]] && js_loc="$loc"
done

# Node version. Prefer the JS stack's location, fall back to project root.
if [[ -n "$js_loc" ]]; then
  if [[ -f "$js_loc/.nvmrc" ]]; then
    echo "node: $(tr -d 'v\n' < "$js_loc/.nvmrc")"
  elif [[ -f .nvmrc ]]; then
    echo "node: $(tr -d 'v\n' < .nvmrc)"
  fi
fi
