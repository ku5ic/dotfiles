#!/usr/bin/env bats
# Tests for `bin/kit explain`: it shows a guard's or the Stop hook's
# decision and evidence, and logs, blocks, and runs nothing.

load helper

setup() {
  KIT="$BATS_TEST_DIRNAME/../bin/kit"
  kit_test_home
  export HOME="$FAKE_HOME" CLAUDE_CONFIG_DIR="$FAKE_HOME/.claude"
  REPO="$BATS_TEST_TMPDIR/repo"
  git init -q -b main "$REPO"
  REPO="$(cd -P "$REPO" && pwd)"
  cd "$REPO"
}

@test "bash: shows the parse and the block with its rule, and logs nothing" {
  run "$KIT" explain bash 'cd /tmp && echo x | git push --force origin main'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"echo" "x"  |  "git" "push" "--force" "origin" "main"'* ]]
  [[ "$output" == *"guard-bash: block  git-force-push"* ]]
  [ ! -e "$FAKE_HOME/.claude/logs/guards.jsonl" ]
}

@test "bash: an ordinary command passes; a lone kit script is allowed" {
  run "$KIT" explain bash 'git status'
  [[ "$output" == *"guard-bash: pass"* ]]
  run "$KIT" explain bash 'scratch-dir.sh'
  [[ "$output" == *"guard-bash: allow"* ]]
}

@test "edit: a credential read blocks, a plain write passes" {
  run "$KIT" explain edit "$HOME/.ssh/id_rsa" Read
  [[ "$output" == *"guard-edit: block  sensitive-read"* ]]
  run "$KIT" explain edit "$REPO/notes.md"
  [[ "$output" == *"guard-edit: pass"* ]]
}

@test "stop: names what claims a file, where it runs, and the command" {
  touch .shellcheckrc
  echo 'echo hi' >run.sh
  echo x >notes.md
  run "$KIT" explain stop run.sh notes.md
  [ "$status" -eq 0 ]
  [[ "$output" == *"shellcheck  (config .shellcheckrc)"* ]]
  [[ "$output" == *"file     run.sh"* ]]
  [[ "$output" == *"unclaimed  notes.md"* ]]
}

@test "stop: with no files, uses the working tree's changes" {
  touch .shellcheckrc
  echo 'echo hi' >run.sh
  run "$KIT" explain stop
  [[ "$output" == *"file     run.sh"* ]]
}
