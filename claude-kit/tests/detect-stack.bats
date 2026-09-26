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

# The user overlay at ~/.claude/claude-kit.local.yml merges over kit.yml.

write_overlay() {
  mkdir -p "$HOME/.claude"
  cat >"$HOME/.claude/claude-kit.local.yml"
}

@test "a stack added by the overlay is detected" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/custom")"
  touch "$root/custom.marker"
  write_overlay <<'YAML'
stacks:
  custom:
    sentinels:
      - name: custom.marker
    skills: []
YAML

  cd "$root"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "root: $root
custom: yes" ]
}

@test "the overlay's arrays append to kit.yml's instead of replacing them" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/next")"
  printf '{"dependencies":{"react":"19.0.0"}}\n' >"$root/package.json"
  touch "$root/extra.marker"
  write_overlay <<'YAML'
stacks:
  js:
    extras:
      - name: marked
        file: extra.marker
YAML

  cd "$root"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"js: yes (react,marked) [npm]"* ]]
}

@test "editing the overlay invalidates the merged copy" {
  local root
  root="$(make_repo "$BATS_TEST_TMPDIR/custom")"
  touch "$root/custom.marker"
  write_overlay <<'YAML'
stacks: {}
YAML
  cd "$root"
  run "$SCRIPT"
  [ -z "$output" ]

  write_overlay <<'YAML'
stacks:
  custom:
    sentinels:
      - name: custom.marker
    skills: []
YAML
  # A future mtime: the rewrite can land in the same second as the merge.
  touch -t 209901010000 "$HOME/.claude/claude-kit.local.yml"
  run "$SCRIPT"
  [[ "$output" == *"custom: yes"* ]]
}
