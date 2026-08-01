#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit. Runs guard-edit's, guard-skills'
# and guard-tone's checks in one process against one payload read, instead of
# three separate hook processes each re-parsing the same payload. Mirrors
# format-dispatch.sh's role on the PostToolUse side.
#
# Order matches the previous settings.json registration order: edit-safety,
# then skills-gate, then tone. A tool call that violates more than one check
# now surfaces only the first violation's message (deterministic, by this
# order) instead of one message per hook - an accepted, minor behavior change:
# the call is still correctly blocked either way.
HOOK_NAME="guard-dispatch.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

# shellcheck source=guard-edit.sh
source "$(dirname "$0")/guard-edit.sh"
# shellcheck source=guard-skills.sh
source "$(dirname "$0")/guard-skills.sh"
# shellcheck source=guard-tone.sh
source "$(dirname "$0")/guard-tone.sh"

# _lib.sh's own ERR trap (set above, at file scope) is process-wide: left in
# place, an unexpected error inside ANY one check's function would fail open
# the entire dispatcher (skipping the remaining checks), not just that one -
# a real isolation loss versus today's three-separate-processes behavior,
# where each hook's own fail-open is independent of the others. Clear it here
# and give each check its own fresh, self-contained errexit+errtrace+trap
# inside its own subshell instead - restoring the original per-hook isolation
# instead of merely approximating it. Verified empirically (three cases: a
# clean check, a check hitting an unexpected internal error, and a check that
# actually blocks) before writing this - see the plan's own test notes.
trap - ERR

run_dispatch_check() {
  local fn="$1" name="$2" rc=0
  (
    set -e
    set -o errtrace
    trap "echo '${name}: unexpected error, failing open' >&2; exit 0" ERR
    "$fn"
  )
  rc=$?
  # Deliberately an `if`, not a bare `((rc != 0)) && exit`: under `set -e`, a
  # standalone `((...))` that evaluates false returns its own nonzero exit
  # status and IS itself subject to errexit, which would silently terminate
  # the dispatcher on every "no violation" pass - confirmed by hitting this
  # exact bug while drafting this design. The condition of an `if` is
  # exempt from errexit regardless of its truth value.
  if ((rc != 0)); then
    exit "$rc"
  fi
}

run_dispatch_check run_guard_edit guard-edit.sh
run_dispatch_check run_guard_skills guard-skills.sh
run_dispatch_check run_guard_tone guard-tone.sh

exit 0
