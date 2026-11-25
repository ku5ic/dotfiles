#!/usr/bin/env bats
# Tests for ~/.dotfiles/scripts/claude_memory_check.sh.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/claude_memory_check.sh"
  MEMORY="$BATS_TEST_TMPDIR/memory"
  mkdir -p "$MEMORY/general" "$MEMORY/app" "$MEMORY/.git"
  printf '# claude-memory\n' >"$MEMORY/README.md"
  : >"$MEMORY/MEMORY.md"
  memory general/one
  memory app/two
}

# memory <folder>/<slug>: a valid memory file plus its index line
memory() {
  memory_file "$1"
  printf -- '- [Title](%s.md) - hook\n' "$1" >>"$MEMORY/MEMORY.md"
}

memory_file() {
  printf -- '---\nname: %s\ndescription: a fact\n---\n\nFact.\n' "${1##*/}" >"$MEMORY/$1.md"
}

check() {
  run bash "$SCRIPT" "$MEMORY"
}

@test "a valid directory passes with no output" {
  check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a memory missing from the index is reported" {
  memory_file general/three
  check
  [ "$status" -eq 1 ]
  [ "$output" = "general/three.md: not in MEMORY.md" ]
}

@test "a memory indexed twice is reported" {
  printf -- '- [Again](general/one.md) - hook\n' >>"$MEMORY/MEMORY.md"
  check
  [ "$status" -eq 1 ]
  [ "$output" = "general/one.md: 2 lines in MEMORY.md" ]
}

@test "an index link to a missing file is reported" {
  printf -- '- [Gone](general/gone.md) - hook\n' >>"$MEMORY/MEMORY.md"
  check
  [ "$status" -eq 1 ]
  [ "$output" = "MEMORY.md: general/gone.md does not exist" ]
}

@test "a memory at the root is reported" {
  memory stray
  check
  [ "$status" -eq 1 ]
  [ "$output" = "stray.md: not in a folder" ]
}

@test "the same slug in two folders is reported" {
  memory app/one
  check
  [ "$status" -eq 1 ]
  [ "$output" = "one.md: in more than one folder" ]
}

@test "a name that differs from the file name is reported" {
  printf -- '---\nname: other\ndescription: a fact\n---\n' >"$MEMORY/general/one.md"
  check
  [ "$status" -eq 1 ]
  [ "$output" = "general/one.md: name is not 'one'" ]
}

@test "leftover conflict markers are reported" {
  printf '<<<<<<< Updated upstream\n' >>"$MEMORY/general/one.md"
  check
  [ "$status" -eq 1 ]
  [ "$output" = "general/one.md: conflict markers" ]
}

@test "conflict markers in the index are reported" {
  printf '<<<<<<< Updated upstream\n' >>"$MEMORY/MEMORY.md"
  check
  [ "$status" -eq 1 ]
  [ "$output" = "MEMORY.md: conflict markers" ]
}

@test "an index over the line limit is reported" {
  for ((i = 0; i < 200; i++)); do printf '\n' >>"$MEMORY/MEMORY.md"; done
  check
  [ "$status" -eq 1 ]
  [ "$output" = "MEMORY.md: 202 lines, over 200" ]
}

@test "an index over the byte limit is reported" {
  printf '%025000d\n' 0 >>"$MEMORY/MEMORY.md"
  check
  [ "$status" -eq 1 ]
  [[ "$output" == "MEMORY.md: "*" bytes, over 25000" ]]
}

@test "a missing directory is an error" {
  run bash "$SCRIPT" "$BATS_TEST_TMPDIR/nope"
  [ "$status" -eq 2 ]
}
