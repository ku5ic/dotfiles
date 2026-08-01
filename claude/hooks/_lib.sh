#!/usr/bin/env bash
# Shared helpers for ~/.claude/hooks/*.sh.
#
# Each hook sets HOOK_NAME (typically the script's basename) and sources this
# file. The shared prologue applies strict mode and a fail-open ERR trap so a
# hook bug never blocks legitimate tool calls; it logs to stderr instead.
#
# Usage:
#
#   #!/usr/bin/env bash
#   HOOK_NAME="guard-foo.sh"
#   # shellcheck source=_lib.sh
#   source "$(dirname "$0")/_lib.sh"
#
#   read_payload
#   require_jq
#   cmd="$(extract_command)"
#   [[ -z "$cmd" ]] && exit 0
#   ... policy ...
#
# block() and warn() prefix output with HOOK_NAME. Hooks that want richer
# block messages (showing the offending command/path) override block() after
# sourcing.
#
# Idempotency guard: guard-dispatch.sh sources this file once directly, then
# sources guard-edit.sh/guard-skills.sh/guard-tone.sh, each of which also
# sources this file for standalone use. Without this guard the second
# sourcing re-runs `readonly BANNED_TELL_REGEX` below and errors.
[[ -n "${_CLAUDE_HOOKS_LIB_SOURCED:-}" ]] && return
_CLAUDE_HOOKS_LIB_SOURCED=1

set -euo pipefail
trap 'echo "${HOOK_NAME:-hook}: unexpected error, failing open" >&2; exit 0' ERR

# Reads the JSON tool-call payload from stdin into the global $payload.
# Each hook reads stdin exactly once; subsequent reads return empty.
read_payload() {
  payload="$(cat)"
}

# Exits 0 (allow) if jq is not installed. Hooks rely on jq for payload
# parsing; without it, the hook cannot safely evaluate policy.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "${HOOK_NAME:-hook}: jq not found, skipping checks" >&2
    exit 0
  fi
}

# Extracts the file path from common Edit/Write/MultiEdit payload shapes.
extract_path() {
  printf '%s' "$payload" | jq -r '
    .tool_input.file_path
    // .tool_input.path
    // .tool_input.target_file
    // empty
  '
}

# Extracts the command string from a Bash tool-call payload.
extract_command() {
  printf '%s' "$payload" | jq -r '.tool_input.command // empty'
}

# Appends one JSONL line to $HOME/.claude/logs/guard-blocks.jsonl.
# Args: $1 = rule slug, $2 = offending detail (command or path).
# Runs in a subshell with stderr suppressed so a logging failure never
# prevents the block() caller from reaching exit 2.
log_block() {
  local rule="${1:-unknown}" detail="${2:-}"
  (
    local log_dir="$HOME/.claude/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/guard-blocks.jsonl"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s' "${payload:-{}}" | jq -c \
      --arg ts "$ts" \
      --arg hook "${HOOK_NAME:-hook}" \
      --arg rule "$rule" \
      --arg detail "$detail" \
      '{
         ts: $ts,
         hook: $hook,
         rule: $rule,
         detail: $detail,
         session_id: (.session_id // null),
         cwd: (.cwd // null)
       }' >>"$log_file"
    local max_lines=10000
    if (($(wc -l <"$log_file") > max_lines)); then
      local tmp
      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT
      tail -n "$max_lines" "$log_file" >"$tmp"
      mv "$tmp" "$log_file"
    fi
  ) 2>/dev/null || true
}

# Blocks the tool call with a stderr reason and exit code 2.
# $1 = human-readable reason, $2 = optional rule slug for log_block.
# Hooks override this to add context (e.g. the offending command or path).
block() {
  log_block "${2:-unknown}" "${cmd:-}"
  echo "Blocked by ${HOOK_NAME:-hook}: $1" >&2
  exit 2
}

# Emits a warning to stderr and continues. Use for soft signals.
warn() {
  echo "${HOOK_NAME:-hook}: $1" >&2
}

# Banned AI-tell opener/closer phrases (CLAUDE.md's Voice section). Anchored
# to line start so mid-sentence uses ("this is certainly true") are not
# flagged -- only the opener/closer position these phrases appear in as
# filler. Shared by guard-tone.sh (written files) and guard-response.sh
# (chat) so the two enforcement paths cannot silently drift apart.
# shellcheck disable=SC2034
readonly BANNED_TELL_REGEX='^(certainly|absolutely|of course|sure)[!,.]|^(great question|i hope this helps|let.s dive in|happy to help|in conclusion|to summarize|in summary)([[:space:]]|[!,.]|$)'

# Longest run of consecutive "wall of text" lines in $1: non-blank lines that
# are not a list item, heading, blockquote, or table row, outside fenced code
# blocks. Deterministic stand-in for rules/adhd-output.md rule 8 (no walls of
# text) -- the only rule in that file mechanical enough to check safely; the
# rest (front-loading, one idea per bullet, plain language) need judgment a
# hook cannot make.
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
