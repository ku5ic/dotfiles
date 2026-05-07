#!/usr/bin/env bash
HOOK_NAME="lint-shell.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"
[[ -z "$path" || ! -f "$path" ]] && exit 0

case "$path" in
*.sh | *.bash) ;;
*) exit 0 ;;
esac

command -v shellcheck >/dev/null 2>&1 || exit 0

shellcheck "$path" >&2 || true
exit 0
