#!/usr/bin/env bats
# Tests for ~/.dotfiles/claude/bin/statusline.sh.
#
# statusline.sh reads the statusLine JSON payload from stdin and renders a
# two-row status. Each test fakes $HOME so the git-status cache never lands
# in the real ~/.claude/cache, and builds a throwaway git repo for the
# branch/counts assertions so real repo state never leaks in either.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../claude/bin/statusline.sh"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FAKE_HOME" "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name "Test"
}

# make_payload <dir> <session_id> <ctx_pct> [effort_level] [five_h_pct]
make_payload() {
  local dir="$1" session="$2" ctx="$3" effort="${4:-}" five_h="${5:-}"
  jq -n \
    --arg dir "$dir" --arg session "$session" --argjson ctx "$ctx" \
    --arg effort "$effort" --arg five_h "$five_h" '
    {
      model: {display_name: "Opus"},
      workspace: {current_dir: $dir},
      session_id: $session,
      context_window: {used_percentage: $ctx},
      cost: {total_cost_usd: 1, total_duration_ms: 1000}
    }
    + (if $effort != "" then {effort: {level: $effort}} else {} end)
    + (if $five_h != "" then {rate_limits: {five_hour: {used_percentage: ($five_h | tonumber)}}} else {} end)
  '
}

run_statusline() {
  printf '%s' "$1" | HOME="$FAKE_HOME" bash "$SCRIPT"
}

# with_agent <payload> <jq-object>  merges agent identity keys into a payload.
# make_payload omits them because a plain interactive session has none; only
# a main thread running as a named agent gets them.
with_agent() {
  jq -c ". + $2" <<<"$1"
}

# backdate_mtime <file> <seconds_ago>
# Sets file's mtime to now minus <seconds_ago>, so TTL-boundary tests can hit
# the exact edge deterministically instead of sleeping past it (which is
# flaky). Tries BSD `date -v` (macOS) first, falls back to GNU `date -d`
# (Linux CI) - the same dual-platform shape statusline.sh itself uses for
# `stat -c` / `stat -f`.
backdate_mtime() {
  local file="$1" secs="$2" ts
  ts="$(date -v-"${secs}"S +%Y%m%d%H%M.%S 2>/dev/null || date -d "-${secs} seconds" +%Y%m%d%H%M.%S)"
  touch -t "$ts" "$file"
}

@test "renders model name, dir basename, and context percentage" {
  run run_statusline "$(make_payload "$REPO" t1 50)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Opus"* ]]
  [[ "$output" == *"$(basename "$REPO")"* ]]
  [[ "$output" == *"50%"* ]]
}

@test "context bar renders green below the yellow threshold" {
  run run_statusline "$(make_payload "$REPO" t2 50)"
  [[ "$output" == *$'\033[32m'* ]]
}

@test "context bar renders yellow at the yellow threshold" {
  run run_statusline "$(make_payload "$REPO" t3 75)"
  [[ "$output" == *$'\033[33m'* ]]
}

@test "context bar renders red at the red threshold" {
  run run_statusline "$(make_payload "$REPO" t4 95)"
  [[ "$output" == *$'\033[31m'* ]]
}

@test "context bar stays green just below the yellow threshold" {
  run run_statusline "$(make_payload "$REPO" t4a 69)"
  [[ "$output" == *$'\033[32m'* ]]
}

@test "context bar turns yellow exactly at the yellow threshold" {
  run run_statusline "$(make_payload "$REPO" t4b 70)"
  [[ "$output" == *$'\033[33m'* ]]
}

@test "context bar stays yellow just below the red threshold" {
  run run_statusline "$(make_payload "$REPO" t4c 89)"
  [[ "$output" == *$'\033[33m'* ]]
}

@test "context bar turns red exactly at the red threshold" {
  run run_statusline "$(make_payload "$REPO" t4d 90)"
  [[ "$output" == *$'\033[31m'* ]]
}

@test "negative context percentage clamps to zero and renders green" {
  run run_statusline "$(make_payload "$REPO" t4e -15)"
  [[ "$output" == *"0%"* ]]
  [[ "$output" == *$'\033[32m'* ]]
}

@test "context percentage above 100 clamps to 100 and renders red" {
  run run_statusline "$(make_payload "$REPO" t4f 150)"
  [[ "$output" == *"100%"* ]]
  [[ "$output" == *$'\033[31m'* ]]
}

@test "agent name renders beside the model when present" {
  run run_statusline "$(with_agent "$(make_payload "$REPO" t4g 50)" '{agent:{name:"scout"}}')"
  [ "$status" -eq 0 ]
  [[ "$output" == "Opus (scout)  $(basename "$REPO")"* ]]
}

@test "agent name falls back to agent_type when the agent key is absent" {
  run run_statusline "$(with_agent "$(make_payload "$REPO" t4h 50)" '{agent_type:"reviewer"}')"
  [[ "$output" == "Opus (reviewer)"* ]]
}

@test "agent key wins over agent_type when both are present" {
  run run_statusline "$(with_agent "$(make_payload "$REPO" t4i 50)" '{agent:{name:"scout"},agent_type:"reviewer"}')"
  [[ "$output" == "Opus (scout)"* ]]
  [[ "$output" != *"reviewer"* ]]
}

@test "agent segment is omitted for a plain interactive session" {
  run run_statusline "$(make_payload "$REPO" t4j 50)"
  [[ "$output" == "Opus  $(basename "$REPO")"* ]]
  [[ "$output" != *"("* ]]
}

@test "effort segment renders when present" {
  run run_statusline "$(make_payload "$REPO" t5 50 high)"
  [[ "$output" == *"effort:high"* ]]
}

@test "effort segment is omitted when absent" {
  run run_statusline "$(make_payload "$REPO" t6 50)"
  [[ "$output" != *"effort:"* ]]
}

@test "5h segment renders when present" {
  run run_statusline "$(make_payload "$REPO" t7 50 "" 12.7)"
  [[ "$output" == *"5h:12%"* ]]
}

@test "5h segment is omitted when absent" {
  run run_statusline "$(make_payload "$REPO" t8 50)"
  [[ "$output" != *"5h:"* ]]
}

@test "git segment shows branch and staged/modified counts" {
  printf 'one' >"$REPO/a.txt"
  git -C "$REPO" add a.txt
  git -C "$REPO" commit -qm init
  printf 'two' >"$REPO/b.txt"
  git -C "$REPO" add b.txt
  printf 'changed' >>"$REPO/a.txt"
  run run_statusline "$(make_payload "$REPO" t9 50)"
  [[ "$output" == *"main +1 ~1"* ]]
}

@test "git segment is omitted outside a git repo" {
  local non_git="$BATS_TEST_TMPDIR/plain"
  mkdir -p "$non_git"
  run run_statusline "$(make_payload "$non_git" t10 50)"
  [ "$(printf '%s' "$output" | head -1)" = "Opus  plain" ]
}

@test "git status cache is reused within the TTL" {
  printf 'one' >"$REPO/a.txt"
  git -C "$REPO" add a.txt
  git -C "$REPO" commit -qm init
  printf 'x' >>"$REPO/a.txt"
  run run_statusline "$(make_payload "$REPO" tcache1 50)"
  [[ "$output" == *"~1"* ]]

  printf 'two' >"$REPO/b.txt"
  git -C "$REPO" add b.txt
  git -C "$REPO" commit -qm second
  printf 'y' >>"$REPO/b.txt"
  run run_statusline "$(make_payload "$REPO" tcache1 50)"
  [[ "$output" == *"~1"* ]]
}

@test "git status cache regenerates after the TTL expires" {
  printf 'one' >"$REPO/a.txt"
  git -C "$REPO" add a.txt
  git -C "$REPO" commit -qm init
  printf 'x' >>"$REPO/a.txt"
  run run_statusline "$(make_payload "$REPO" tcache2 50)"
  [[ "$output" == *"~1"* ]]

  printf 'two' >"$REPO/b.txt"
  git -C "$REPO" add b.txt
  git -C "$REPO" commit -qm second
  printf 'y' >>"$REPO/b.txt"
  sleep 6
  run run_statusline "$(make_payload "$REPO" tcache2 50)"
  [[ "$output" == *"~2"* ]]
}

@test "git status cache regenerates exactly at the TTL boundary (age == CACHE_TTL)" {
  printf 'one' >"$REPO/a.txt"
  git -C "$REPO" add a.txt
  git -C "$REPO" commit -qm init
  printf 'x' >>"$REPO/a.txt"
  run run_statusline "$(make_payload "$REPO" tboundary1 50)"
  [[ "$output" == *"~1"* ]]

  printf 'two' >"$REPO/b.txt"
  git -C "$REPO" add b.txt
  git -C "$REPO" commit -qm second
  printf 'y' >>"$REPO/b.txt"
  # CACHE_TTL in statusline.sh is 5; backdating the cache file's mtime by
  # exactly 5 seconds hits the `>=` boundary deterministically, no sleep.
  backdate_mtime "$FAKE_HOME/.claude/cache/statusline/git-tboundary1" 5
  run run_statusline "$(make_payload "$REPO" tboundary1 50)"
  [[ "$output" == *"~2"* ]]
}

@test "git status cache is reused comfortably under the TTL boundary" {
  printf 'one' >"$REPO/a.txt"
  git -C "$REPO" add a.txt
  git -C "$REPO" commit -qm init
  printf 'x' >>"$REPO/a.txt"
  run run_statusline "$(make_payload "$REPO" tboundary2 50)"
  [[ "$output" == *"~1"* ]]

  printf 'two' >"$REPO/b.txt"
  git -C "$REPO" add b.txt
  git -C "$REPO" commit -qm second
  printf 'y' >>"$REPO/b.txt"
  # Backdating by 2 (not CACHE_TTL - 1 = 4) leaves real margin against the
  # git/subprocess overhead between this backdate and statusline.sh's own
  # `date +%s` read - on a loaded CI runner that overhead can eat a full
  # second, and a 4s backdate had already crossed the 5s TTL by the time
  # `now` was read, flaking this test intermittently.
  backdate_mtime "$FAKE_HOME/.claude/cache/statusline/git-tboundary2" 2
  run run_statusline "$(make_payload "$REPO" tboundary2 50)"
  [[ "$output" == *"~1"* ]]
}

@test "missing jq prints a notice instead of erroring or blanking" {
  # A PATH with nothing at all also hides `cat`, which the script needs to
  # read its own stdin before it ever gets to the jq check - so build a
  # minimal stub PATH that has `cat` (via symlink to the real binary) but
  # not jq, rather than an empty PATH.
  local stub_dir="$BATS_TEST_TMPDIR/stub_no_jq"
  mkdir -p "$stub_dir"
  ln -s "$(command -v cat)" "$stub_dir/cat"
  local bash_bin
  bash_bin="$(command -v bash)"
  run env PATH="$stub_dir" HOME="$FAKE_HOME" "$bash_bin" "$SCRIPT" <<<'{}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"jq not found"* ]]
}
