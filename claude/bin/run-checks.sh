#!/usr/bin/env bash
# ~/.claude/bin/run-checks.sh
# Detects and runs typecheck, lint, format-check, and tests for the current project.
# Each section is independent: failures are reported, not aborted.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

pass=0
fail=0
skip=0

run() {
  local label="$1"; shift
  local out
  out="$(mktemp -t run-checks)"
  if "$@" >"$out" 2>&1; then
    echo "PASS $label"
    pass=$((pass+1))
  else
    echo "FAIL $label ($*)"
    head -30 "$out"
    fail=$((fail+1))
  fi
  rm -f "$out"
}

skip_msg() {
  echo "SKIP $1"
  skip=$((skip+1))
}

# JS/TS
if [[ -f package.json ]]; then
  pm="npm"
  [[ -f pnpm-lock.yaml ]] && pm="pnpm"
  [[ -f yarn.lock ]] && pm="yarn"
  [[ -f bun.lockb ]] && pm="bun"

  if [[ -f tsconfig.json ]]; then
    run "ts: typecheck" $pm exec tsc --noEmit
  else
    skip_msg "ts: typecheck (no tsconfig)"
  fi

  if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
    run "js: lint" $pm run lint
  elif [[ -f biome.json || -f biome.jsonc ]]; then
    run "js: lint (biome)" $pm exec biome lint .
  else
    skip_msg "js: lint (no script)"
  fi

  if jq -e '.scripts["format:check"]' package.json >/dev/null 2>&1; then
    run "js: format-check" $pm run format:check
  elif jq -e '.scripts.format' package.json >/dev/null 2>&1; then
    skip_msg "js: format-check (no format:check script; format would mutate)"
  fi

  if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
    if [[ "$pm" == "bun" ]]; then
      run "js: test" bun test
    else
      run "js: test" $pm test --silent
    fi
  else
    skip_msg "js: test (no script)"
  fi
fi

# Python
if [[ -f pyproject.toml || -f requirements.txt ]]; then
  if command -v ruff >/dev/null 2>&1; then
    run "py: lint" ruff check .
    run "py: format-check" ruff format --check .
  fi
  if command -v mypy >/dev/null 2>&1 && [[ -f mypy.ini || -f pyproject.toml ]]; then
    run "py: typecheck" mypy .
  fi
  if command -v pytest >/dev/null 2>&1; then
    run "py: test" pytest -q
  fi
fi

# Ruby
if [[ -f Gemfile ]]; then
  if [[ -f .rubocop.yml ]] && command -v rubocop >/dev/null 2>&1; then
    run "rb: lint" bundle exec rubocop --no-color
  fi
  if [[ -f Rakefile ]] && grep -q "task.*:test\|RSpec" Rakefile 2>/dev/null; then
    run "rb: test" bundle exec rake test
  elif [[ -d spec ]]; then
    run "rb: test (rspec)" bundle exec rspec --no-color
  fi
fi

# Rust
if [[ -f Cargo.toml ]]; then
  run "rs: check" cargo check --quiet
  run "rs: clippy" cargo clippy --quiet -- -D warnings
  run "rs: fmt-check" cargo fmt --check
  run "rs: test" cargo test --quiet
fi

# Go
if [[ -f go.mod ]]; then
  run "go: vet" go vet ./...
  run "go: test" go test ./...
fi

echo ""
echo "checks: $pass passed, $fail failed, $skip skipped"
exit "$fail"
