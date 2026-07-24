#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/bin/scratch-rotate.sh.
#
# The script hardcodes its target dir as $HOME/.claude/scratch, so every test
# fakes $HOME to keep it off the real scratch directory. Ages are set with
# backdate_mtime rather than sleeping past a retention window.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../claude/bin/scratch-rotate.sh"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  SCRATCH="$FAKE_HOME/.claude/scratch"
  mkdir -p "$SCRATCH"
}

# backdate_mtime <file> <seconds_ago>
backdate_mtime() {
  local file="$1" secs="$2" ts
  ts="$(date -v-"${secs}"S +%Y%m%d%H%M.%S 2>/dev/null || date -d "-${secs} seconds" +%Y%m%d%H%M.%S)"
  touch -t "$ts" "$file"
}

run_rotate() {
  HOME="$FAKE_HOME" "$SCRIPT" "$@"
}

@test "prunes an .md artifact older than the retention window" {
  : >"$SCRATCH/old.md"
  backdate_mtime "$SCRATCH/old.md" $((40 * 86400))
  run run_rotate 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned 1 artifact(s)"* ]]
  [ ! -e "$SCRATCH/old.md" ]
}

@test "keeps an .md artifact newer than the retention window" {
  : >"$SCRATCH/fresh.md"
  backdate_mtime "$SCRATCH/fresh.md" 3600
  run run_rotate 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned 0 artifact(s)"* ]]
  [ -e "$SCRATCH/fresh.md" ]
}

@test "prunes a .injected- session marker older than 1 day" {
  : >"$SCRATCH/.injected-old"
  backdate_mtime "$SCRATCH/.injected-old" $((2 * 86400))
  run run_rotate
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned 1 session marker(s) older than 1d"* ]]
  [ ! -e "$SCRATCH/.injected-old" ]
}

@test "keeps a .injected- session marker younger than 1 day" {
  : >"$SCRATCH/.injected-fresh"
  backdate_mtime "$SCRATCH/.injected-fresh" 3600
  run run_rotate
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned 0 session marker(s) older than 1d"* ]]
  [ -e "$SCRATCH/.injected-fresh" ]
}

@test "marker retention is fixed at 1 day, independent of the .md days argument" {
  # A 2-day-old marker is pruned even when the .md retention window passed as
  # an argument is generous (100 days) - the two sweeps use unrelated cutoffs.
  : >"$SCRATCH/.injected-old"
  backdate_mtime "$SCRATCH/.injected-old" $((2 * 86400))
  run run_rotate 100
  [ "$status" -eq 0 ]
  [ ! -e "$SCRATCH/.injected-old" ]
}

@test "marker sweep does not descend into subdirectories (maxdepth 1)" {
  mkdir -p "$SCRATCH/sub"
  : >"$SCRATCH/sub/.injected-nested"
  backdate_mtime "$SCRATCH/sub/.injected-nested" $((3 * 86400))
  run run_rotate
  [ "$status" -eq 0 ]
  [ -e "$SCRATCH/sub/.injected-nested" ]
}

@test "both sweeps run together and report independent counts" {
  : >"$SCRATCH/old.md"
  backdate_mtime "$SCRATCH/old.md" $((40 * 86400))
  : >"$SCRATCH/fresh.md"
  backdate_mtime "$SCRATCH/fresh.md" 3600
  : >"$SCRATCH/.injected-old"
  backdate_mtime "$SCRATCH/.injected-old" $((2 * 86400))
  : >"$SCRATCH/.injected-fresh"
  backdate_mtime "$SCRATCH/.injected-fresh" 3600
  run run_rotate 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned 1 artifact(s) older than 30d"* ]]
  [[ "$output" == *"pruned 1 session marker(s) older than 1d"* ]]
  [ ! -e "$SCRATCH/old.md" ]
  [ -e "$SCRATCH/fresh.md" ]
  [ ! -e "$SCRATCH/.injected-old" ]
  [ -e "$SCRATCH/.injected-fresh" ]
}

@test "no scratch dir: exits 0 without error" {
  rm -rf "$SCRATCH"
  run run_rotate
  [ "$status" -eq 0 ]
}
