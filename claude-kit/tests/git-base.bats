#!/usr/bin/env bats
# Characterization tests for bin/git-base.sh: pins which base it picks at
# each step of its detection order.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../bin/git-base.sh"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset CLAUDE_CONFIG_DIR
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
}

# Bare origin with one commit on main, cloned to $BATS_TEST_TMPDIR/work.
# The clone sets origin/HEAD.
make_clone() {
  local seed="$BATS_TEST_TMPDIR/seed" origin="$BATS_TEST_TMPDIR/origin.git"
  git init -q -b main "$seed"
  git -C "$seed" commit -q --allow-empty -m init
  git clone -q --bare "$seed" "$origin"
  git clone -q "$origin" "$BATS_TEST_TMPDIR/work"
}

@test "an upstream other than this branch's own name wins" {
  make_clone
  cd "$BATS_TEST_TMPDIR/work"
  git switch -q -c feat --track origin/main

  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "origin/main" ]
}

@test "with no upstream, origin/HEAD is used" {
  make_clone
  cd "$BATS_TEST_TMPDIR/work"
  git switch -q -c feat --no-track

  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "origin/main" ]
}

@test "with no remote, a local main is used" {
  git init -q -b main "$BATS_TEST_TMPDIR/local"
  cd "$BATS_TEST_TMPDIR/local"
  git commit -q --allow-empty -m init
  git switch -q -c feat

  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "an explicit ref that resolves wins over everything" {
  make_clone
  cd "$BATS_TEST_TMPDIR/work"
  git switch -q -c feat --track origin/main
  git branch -q other

  run "$SCRIPT" other
  [ "$status" -eq 0 ]
  [ "$output" = "other" ]
}

@test "nothing resolvable exits 1" {
  git init -q -b feat "$BATS_TEST_TMPDIR/empty"
  cd "$BATS_TEST_TMPDIR/empty"
  git commit -q --allow-empty -m init

  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
