#!/usr/bin/env bats
# Tests for ~/.dotfiles/scripts/tmux_thumb_upcase_handler.sh.
#
# The script hardcodes /usr/bin/open, so TMUX_THUMB_DRY_RUN=1 makes it print
# the launch target instead. Every test runs from a scratch cwd with no tmux
# pane, so file resolution only ever sees files the test creates.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/tmux_thumb_upcase_handler.sh"
  cd "$BATS_TEST_TMPDIR"
}

handle() {
  TMUX_THUMB_DRY_RUN=1 TMUX= "$SCRIPT" "$@"
}

@test "scheme-less host with a path opens as https" {
  run handle 'github.com/foo/bar'
  [ "$status" -eq 0 ]
  [ "$output" = 'https://github.com/foo/bar' ]
}

@test "bare dotted host opens as https" {
  run handle 'www.example.com'
  [ "$status" -eq 0 ]
  [ "$output" = 'https://www.example.com' ]
}

@test "port, query and fragment survive the https prefix" {
  run handle 'example.com:8080/a?b=1#c'
  [ "$status" -eq 0 ]
  [ "$output" = 'https://example.com:8080/a?b=1#c' ]
}

@test "trailing prose punctuation is stripped before the https prefix" {
  run handle '(github.com/x/y).'
  [ "$status" -eq 0 ]
  [ "$output" = 'https://github.com/x/y' ]
}

@test "an existing file beats the domain reading of the same string" {
  touch 'example.com'
  run handle 'example.com'
  [ "$status" -eq 0 ]
  [ "$output" = 'example.com' ]
}

@test "a relative path with no dotted host is left alone" {
  run handle 'src/foo.ts'
  [ "$status" -eq 0 ]
  [ "$output" = 'src/foo.ts' ]
}

@test "an explicit scheme is passed through untouched" {
  run handle 'https://a.com/b'
  [ "$status" -eq 0 ]
  [ "$output" = 'https://a.com/b' ]
}

@test "--print still copies the trimmed target without launching" {
  run handle --print '(github.com/x/y).'
  [ "$status" -eq 0 ]
  [ "$output" = 'github.com/x/y' ]
}
