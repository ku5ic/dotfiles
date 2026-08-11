#!/usr/bin/env bash
# Shared helpers for ~/.claude/hooks/*.sh. Each hook sets HOOK_NAME and
# sources this file for strict mode plus a fail-open ERR trap (logs to
# stderr, exits 0, instead of blocking a legitimate tool call on a hook bug).

# Idempotency guard: guard-dispatch.sh sources this directly, then sources
# guard-edit.sh/guard-skills.sh/guard-tone.sh which each source it again for
# standalone use - without this, the second sourcing reruns the `readonly
# BANNED_TELL_REGEX` below and errors.
[[ -n "${_CLAUDE_HOOKS_LIB_SOURCED:-}" ]] && return
_CLAUDE_HOOKS_LIB_SOURCED=1

set -euo pipefail
trap 'echo "${HOOK_NAME:-hook}: unexpected error, failing open" >&2; exit 0' ERR

# Reads stdin into the global $payload; each hook reads stdin exactly once.
read_payload() {
  payload="$(cat)"
}

# Fails open (allow) if jq is missing - without it a hook cannot safely
# evaluate policy.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "${HOOK_NAME:-hook}: jq not found, skipping checks" >&2
    exit 0
  fi
}

extract_path() {
  printf '%s' "$payload" | jq -r '
    .tool_input.file_path
    // .tool_input.path
    // .tool_input.target_file
    // empty
  '
}

extract_command() {
  printf '%s' "$payload" | jq -r '.tool_input.command // empty'
}

# $1 = human-readable reason, $2 = optional rule slug. Hooks override this
# to add context (e.g. the offending command or path).
block() {
  echo "Blocked by ${HOOK_NAME:-hook}: $1" >&2
  exit 2
}

# Banned AI-tell opener/closer phrases (CLAUDE.md Voice section), anchored to
# line start so mid-sentence uses ("this is certainly true") aren't flagged.
# Shared by guard-tone.sh (files) and guard-response.sh (chat) so the two
# enforcement paths can't drift apart.
# shellcheck disable=SC2034
readonly BANNED_TELL_REGEX='^(certainly|absolutely|of course|sure)[!,.]|^(great question|i hope this helps|let.s dive in|happy to help|in conclusion|to summarize|in summary)([[:space:]]|[!,.]|$)'

# Longest run of consecutive non-blank, non-list/heading/blockquote/table
# lines in $1, outside fenced code blocks - a deterministic stand-in for
# adhd-output.md rule 8 (no walls of text); the rest of that rule needs
# judgment a hook can't make.
longest_prose_run() {
  printf '%s\n' "$1" | awk '
    /^```/ { infence = !infence; next }
    infence { next }
    NF == 0 { run = 0; next }
    /^[[:space:]]*([0-9]+[.)]|[-*+][[:space:]]|#{1,6}[[:space:]]|>|\|)/ { run = 0; next }
    { run++; if (run > best) best = run }
    END { print best + 0 }
  '
}
