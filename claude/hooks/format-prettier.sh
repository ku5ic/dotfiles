#!/usr/bin/env bash
HOOK_NAME="format-prettier.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"
[[ -z "$path" || ! -f "$path" ]] && exit 0

case "$path" in
*.js | *.jsx | *.ts | *.tsx | *.css | *.json | *.md) ;;
*) exit 0 ;;
esac

command -v prettier >/dev/null 2>&1 || exit 0

prettier --write "$path" >/dev/null
exit 0
