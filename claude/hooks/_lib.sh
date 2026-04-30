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

# Blocks the tool call with a stderr reason and exit code 2.
# Hooks override this to add context (e.g. the offending command or path).
block() {
  echo "Blocked by ${HOOK_NAME:-hook}: $1" >&2
  exit 2
}

# Emits a warning to stderr and continues. Use for soft signals.
warn() {
  echo "${HOOK_NAME:-hook}: $1" >&2
}
