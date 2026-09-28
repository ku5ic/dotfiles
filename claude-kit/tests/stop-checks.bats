#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude-kit/hooks/stop-checks.sh.
#
# Each test writes a kit.yml with one file check, fakelint, claiming .ts files
# under a .fakelintrc. Its binary is a stub in the repo's node_modules/.bin
# that records its cwd and arguments, and fails when $REPO/fail exists. Each
# test writes a transcript JSONL describing the turn the hook inspects.
#
# Run with: bats tests/

load helper

setup() {
  HOOK="$BATS_TEST_DIRNAME/../hooks/stop-checks.sh"
  kit_test_home --plugin-root
  REPO="$BATS_TEST_TMPDIR/repo"
  TRANSCRIPT="$BATS_TEST_TMPDIR/transcript.jsonl"
  CALLS="$BATS_TEST_TMPDIR/calls"
  mkdir -p "$REPO/node_modules/.bin"
  REPO="$(cd -P "$REPO" && pwd)"
  git -C "$REPO" init -q
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakelint
    ext: [ts]
    signal_files: [.fakelintrc]
    bin: fakelint
    cmd: "{bin} --check {files}"
EOF
  printf '#!/usr/bin/env bash\necho "$PWD|$*" >>"%s"\necho "lint noise"\n[[ ! -e "%s/fail" ]]\n' \
    "$CALLS" "$REPO" >"$REPO/node_modules/.bin/fakelint"
  chmod +x "$REPO/node_modules/.bin/fakelint"
  touch "$REPO/.fakelintrc"
  echo x >"$REPO/a.ts"
  echo x >"$REPO/b.ts"
  echo x >"$REPO/notes.md"
}

# turn <tool> <path>...  a real user prompt, then one edit per path.
turn() {
  local tool="$1" path
  shift
  jq -nc '{type:"user", message:{content:"do it"}}' >>"$TRANSCRIPT"
  for path in "$@"; do
    jq -nc --arg n "$tool" --arg p "$path" \
      '{type:"assistant", message:{content:[{type:"tool_use", name:$n, input:{file_path:$p}}]}}' >>"$TRANSCRIPT"
    jq -nc '{type:"user", message:{content:[{type:"tool_result"}]}}' >>"$TRANSCRIPT"
  done
}

stop() {
  local active="${1:-false}"
  jq -nc --arg cwd "$REPO" --arg t "$TRANSCRIPT" --argjson active "$active" \
    '{hook_event_name:"Stop", session_id:"s1", cwd:$cwd, transcript_path:$t, stop_hook_active:$active}' |
    HOME="$FAKE_HOME" "$HOOK"
}

@test "missing transcript runs nothing" {
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

@test "stop_hook_active lets the stop through even when checks would fail" {
  turn Edit "$REPO/a.ts"
  touch "$REPO/fail"
  run stop true
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

@test "an edit runs the check on only the edited file, from the signal directory" {
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS fakelint (1 file)"* ]]
  [ "$(cat "$CALLS")" = "$REPO|--check $REPO/a.ts" ]
}

@test "several edited files go to one call, each file once" {
  turn Write "$REPO/a.ts" "$REPO/b.ts" "$REPO/a.ts"
  run stop
  [ "$(cat "$CALLS")" = "$REPO|--check $REPO/a.ts $REPO/b.ts" ]
  [[ "$output" == *"PASS fakelint (2 files)"* ]]
}

@test "a failing check blocks with its output" {
  turn Edit "$REPO/a.ts"
  touch "$REPO/fail"
  run stop
  [ "$status" -eq 2 ]
  [[ "$output" == *"FAIL fakelint (1 file)"* ]]
  [[ "$output" == *"lint noise"* ]]
  [[ "$output" == *"checks: 0 passed, 1 failed, 0 skipped"* ]]
}

@test "a nested signal file groups its files and runs from there" {
  mkdir -p "$REPO/packages/a"
  touch "$REPO/packages/a/.fakelintrc"
  echo x >"$REPO/packages/a/c.ts"
  turn Edit "$REPO/a.ts" "$REPO/packages/a/c.ts"
  run stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS fakelint (1 file) [packages/a]"* ]]
  grep -qx "$REPO/packages/a|--check $REPO/packages/a/c.ts" "$CALLS"
  grep -qx "$REPO|--check $REPO/a.ts" "$CALLS"
}

@test "{dirs} passes each edited file's directory once, relative to the signal" {
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakevet
    ext: [ts]
    signal_files: [.fakelintrc]
    bin: fakelint
    cmd: "{bin} vet {dirs}"
EOF
  mkdir -p "$REPO/pkg/x"
  echo x >"$REPO/pkg/x/c.ts"
  echo x >"$REPO/pkg/x/d.ts"
  turn Edit "$REPO/a.ts" "$REPO/pkg/x/c.ts" "$REPO/pkg/x/d.ts"
  run stop
  [ "$status" -eq 0 ]
  [ "$(cat "$CALLS")" = "$REPO|vet . ./pkg/x" ]
}

@test "a word holding {files} repeats once per file, prefix kept" {
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakelint
    ext: [ts]
    signal_files: [.fakelintrc]
    bin: fakelint
    cmd: "{bin} :{files}"
EOF
  turn Edit "$REPO/a.ts" "$REPO/b.ts"
  run stop
  [ "$(cat "$CALLS")" = "$REPO|:$REPO/a.ts :$REPO/b.ts" ]
}

@test "an & in a path survives the {files} substitution" {
  mkdir -p "$REPO/R&D"
  echo x >"$REPO/R&D/a.ts"
  turn Edit "$REPO/R&D/a.ts"
  run stop
  [ "$(cat "$CALLS")" = "$REPO|--check $REPO/R&D/a.ts" ]
}

# test_script: only the runner the package.json test script names runs.
use_test_script() {
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakelint
    ext: [ts]
    signal_files: [package.json]
    test_script: fakelint
    bin: fakelint
    cmd: "{bin} {files}"
EOF
}

@test "test_script runs the check when the test script names the runner" {
  use_test_script
  printf '{"scripts":{"test":"NODE_ENV=test fakelint --ci"}}\n' >"$REPO/package.json"
  turn Edit "$REPO/a.ts"
  run stop
  [ -e "$CALLS" ]
}

@test "test_script skips the check when the test script names another runner" {
  use_test_script
  printf '{"scripts":{"test":"notfakelint","storybook":"fakelint"}}\n' >"$REPO/package.json"
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

@test "a malformed package.json skips its test_script check, not the others" {
  cat >>"$FAKE_HOME/.claude/kit.yml" <<'EOF'
  - name: faketest
    ext: [ts]
    signal_files: [package.json]
    test_script: faketest
    bin: fakelint
    cmd: "{bin} test {files}"
EOF
  printf '{"scripts": {"test": "faketest",}}\n' >"$REPO/package.json"
  touch "$REPO/fail"
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 2 ]
  [ "$(cat "$CALLS")" = "$REPO|--check $REPO/a.ts" ]
}

@test "signal_toml claims a file when the pyproject table exists, else not" {
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakelint
    ext: [ts]
    signal_toml: "pyproject.toml .tool.fakelint"
    bin: fakelint
    cmd: "{bin} {files}"
EOF
  mkdir -p "$REPO/backend"
  printf '[tool.other]\nx = 1\n' >"$REPO/pyproject.toml"
  printf '[tool.fakelint]\nfix = true\n' >"$REPO/backend/pyproject.toml"
  echo x >"$REPO/backend/c.ts"
  turn Edit "$REPO/a.ts" "$REPO/backend/c.ts"
  run stop
  [ "$status" -eq 0 ]
  [ "$(cat "$CALLS")" = "$REPO/backend|$REPO/backend/c.ts" ]
}

@test "signal_toml walks past a nearer pyproject.toml without the table" {
  cat >"$FAKE_HOME/.claude/kit.yml" <<'EOF'
file_checks:
  - name: fakelint
    ext: [ts]
    signal_toml: "pyproject.toml .tool.fakelint"
    bin: fakelint
    cmd: "{bin} {files}"
EOF
  mkdir -p "$REPO/packages/foo"
  printf '[tool.fakelint]\nx = 1\n' >"$REPO/pyproject.toml"
  printf '[project]\nname = "foo"\n' >"$REPO/packages/foo/pyproject.toml"
  echo x >"$REPO/packages/foo/c.ts"
  turn Edit "$REPO/packages/foo/c.ts"
  run stop
  [ "$status" -eq 0 ]
  [ "$(cat "$CALLS")" = "$REPO|$REPO/packages/foo/c.ts" ]
}

# bin_lookups: fakepm stands in for a package manager on PATH. `fakepm venv`
# prints $REPO/env; `fakepm has <bin>` succeeds unless $REPO/nopm exists;
# `fakepm run <bin> ...` records the call like fakelint does.
use_bin_lookups() {
  cat >>"$FAKE_HOME/.claude/kit.yml" <<'EOF'
bin_lookups:
  - name: venvpm
    signal_files: [venv.lock]
    venv_cmd: "fakepm venv"
  - name: execpm
    signal_files: [exec.lock]
    probe: "fakepm has {bin}"
    run: "fakepm run {bin}"
EOF
  PM_DIR="$BATS_TEST_TMPDIR/pm"
  mkdir -p "$PM_DIR"
  printf '#!/usr/bin/env bash\ncase "$1" in\nvenv) echo "%s/env" ;;\nhas) [[ ! -e "%s/nopm" ]] ;;\nrun) echo "$PWD|pm $*" >>"%s" ;;\nesac\n' \
    "$REPO" "$REPO" "$CALLS" >"$PM_DIR/fakepm"
  chmod +x "$PM_DIR/fakepm"
  rm "$REPO/node_modules/.bin/fakelint"
}

pm_stop() {
  PATH="$PM_DIR:$PATH" stop
}

@test "venv_cmd runs the bin from the environment the manager reports" {
  use_bin_lookups
  touch "$REPO/venv.lock"
  mkdir -p "$REPO/env/bin"
  printf '#!/usr/bin/env bash\necho "$PWD|venv $*" >>"%s"\n' "$CALLS" >"$REPO/env/bin/fakelint"
  chmod +x "$REPO/env/bin/fakelint"
  turn Edit "$REPO/a.ts"
  run pm_stop
  [ "$status" -eq 0 ]
  [ "$(cat "$CALLS")" = "$REPO|venv --check $REPO/a.ts" ]
}

@test "probe/run wraps the bin in the manager's run command" {
  use_bin_lookups
  touch "$REPO/exec.lock"
  turn Edit "$REPO/a.ts"
  run pm_stop
  [ "$status" -eq 0 ]
  [ "$(cat "$CALLS")" = "$REPO|pm run fakelint --check $REPO/a.ts" ]
}

@test "a failing probe falls through to a skip" {
  use_bin_lookups
  touch "$REPO/exec.lock" "$REPO/nopm"
  turn Edit "$REPO/a.ts"
  run pm_stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP fakelint (1 file) (fakelint not installed)"* ]]
  [ ! -e "$CALLS" ]
}

@test "a project-local bin wins over a lookup" {
  use_bin_lookups
  touch "$REPO/exec.lock"
  printf '#!/usr/bin/env bash\necho "$PWD|local $*" >>"%s"\n' "$CALLS" >"$REPO/node_modules/.bin/fakelint"
  chmod +x "$REPO/node_modules/.bin/fakelint"
  turn Edit "$REPO/a.ts"
  run pm_stop
  [ "$(cat "$CALLS")" = "$REPO|local --check $REPO/a.ts" ]
}

@test "disabled_file_checks in the overlay turns a check off" {
  printf 'disabled_file_checks: [fakelint]\n' >"$FAKE_HOME/.claude/claude-kit.local.yml"
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

# one_check <extra yaml lines>: a kit.yml with fakelint plus the given keys.
one_check() {
  printf 'file_checks:\n  - name: fakelint\n    ext: [ts]\n    signal_files: [.fakelintrc]\n    bin: fakelint\n    cmd: "{bin} {files}"\n%s\n' \
    "$1" >"$FAKE_HOME/.claude/kit.yml"
}

@test "needs_files: runs from the signal dir only when a needed file is at or above it" {
  one_check '    needs_files: [.needed]'
  mkdir -p "$REPO/mod"
  touch "$REPO/mod/.fakelintrc"
  echo x >"$REPO/mod/c.ts"
  turn Edit "$REPO/mod/c.ts"
  run stop
  [ ! -e "$CALLS" ]
  touch "$REPO/.needed"
  run stop
  [ "$(cat "$CALLS")" = "$REPO/mod|$REPO/mod/c.ts" ]
}

@test "exclude_toml drops files matching the project's exclude regexes" {
  one_check '    exclude_toml: "pyproject.toml .tool.fake.exclude"'
  printf '[tool.fake]\nexclude = ["^migrations/", "_gen\\\\.ts$"]\n' >"$REPO/pyproject.toml"
  mkdir -p "$REPO/migrations"
  echo x >"$REPO/migrations/m.ts"
  echo x >"$REPO/api_gen.ts"
  turn Edit "$REPO/migrations/m.ts" "$REPO/api_gen.ts" "$REPO/a.ts"
  run stop
  [ "$(cat "$CALLS")" = "$REPO|$REPO/a.ts" ]
}

@test "exclude_toml takes a single-string exclude too" {
  one_check '    exclude_toml: "pyproject.toml .tool.fake.exclude"'
  printf '[tool.fake]\nexclude = "^a\\\\.ts$"\n' >"$REPO/pyproject.toml"
  turn Edit "$REPO/a.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "local_only skips a bin found only on PATH" {
  one_check '    local_only: true'
  mkdir -p "$BATS_TEST_TMPDIR/path"
  mv "$REPO/node_modules/.bin/fakelint" "$BATS_TEST_TMPDIR/path/"
  turn Edit "$REPO/a.ts"
  PATH="$BATS_TEST_TMPDIR/path:$PATH" run stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP fakelint (1 file) (fakelint not in the project environment)"* ]]
  [ ! -e "$CALLS" ]
}

@test "without local_only a bin on PATH runs" {
  one_check ''
  mkdir -p "$BATS_TEST_TMPDIR/path"
  mv "$REPO/node_modules/.bin/fakelint" "$BATS_TEST_TMPDIR/path/"
  turn Edit "$REPO/a.ts"
  PATH="$BATS_TEST_TMPDIR/path:$PATH" run stop
  [ -e "$CALLS" ]
}

@test "a file no check claims runs nothing" {
  turn Write "$REPO/notes.md"
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

@test "a file without the signal above it runs nothing" {
  rm "$REPO/.fakelintrc"
  turn Edit "$REPO/a.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "a missing binary is skipped, not failed" {
  rm "$REPO/node_modules/.bin/fakelint"
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP fakelint (1 file) (fakelint not installed)"* ]]
}

@test "a deleted file is not checked" {
  turn Edit "$REPO/gone.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "an edit outside the repo checks nothing" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  echo x >"$BATS_TEST_TMPDIR/elsewhere/x.ts"
  turn Write "$BATS_TEST_TMPDIR/elsewhere/x.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "edits committed in the turn skip the checks" {
  turn Edit "$REPO/a.ts"
  # The hook's HOME: a developer's global excludes must not hide node_modules.
  HOME="$FAKE_HOME" git -C "$REPO" add -A
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q -m edit
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}

@test "a turn without edit tools skips the checks" {
  turn Read "$REPO/a.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "an edit in an earlier turn does not count" {
  turn Edit "$REPO/a.ts"
  turn Read "$REPO/a.ts"
  run stop
  [ ! -e "$CALLS" ]
}

@test "a meta user entry does not start a new turn" {
  turn Edit "$REPO/a.ts"
  jq -nc '{type:"user", isMeta:true, message:{content:"skill loaded"}}' >>"$TRANSCRIPT"
  run stop
  [ -e "$CALLS" ]
}

@test "outside a git worktree exits clean" {
  REPO="$BATS_TEST_TMPDIR/plain"
  mkdir -p "$REPO"
  echo x >"$REPO/a.ts"
  turn Edit "$REPO/a.ts"
  run stop
  [ "$status" -eq 0 ]
  [ ! -e "$CALLS" ]
}
