#!/usr/bin/env bats
# Characterization tests for bin/detect-stack.sh: pins today's report on
# three fixtures so later refactors change it only on purpose.
#
# Runs the real script against the real kit.yml; HOME is faked so the
# stack-list cache lands in the test's tmpdir.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../bin/detect-stack.sh"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR
}

# Creates a git repo at $1 and prints its physical path, which is what
# git rev-parse (and so the report's root: line) uses.
make_repo() {
  mkdir -p "$1"
  git init -q -b main "$1"
  (cd -P "$1" && pwd)
}

@test "pnpm Next.js repo reports js with extras and the pnpm tag" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/next")"
  printf '{"dependencies":{"next":"15.0.0","react":"19.0.0"},"devDependencies":{"typescript":"5.6.0"}}\n' >"$root/package.json"
  printf '{}\n' >"$root/tsconfig.json"
  touch "$root/pnpm-lock.yaml"

  cd "$root"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "root: $root
js: yes (typescript,next,react) [pnpm]" ]
}

@test "uv Django repo reports python with django and no manager tag" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/django")"
  printf '[project]\nname = "x"\ndependencies = ["django>=5.0"]\n' >"$root/pyproject.toml"
  touch "$root/uv.lock" "$root/manage.py"

  cd "$root"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "root: $root
python: yes (django)" ]
}

@test "repo with no sentinel prints nothing" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/none")"

  cd "$root"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
