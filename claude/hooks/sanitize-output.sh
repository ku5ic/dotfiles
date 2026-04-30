#!/usr/bin/env bash
# PostToolUse hook for Write, Edit, MultiEdit.
# Strips typographic punctuation (em dashes, smart quotes, etc.) from written files.
HOOK_NAME="sanitize-output.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

path="$(extract_path)"
[[ -z "$path" || ! -f "$path" ]] && exit 0

file "$path" 2>/dev/null | grep -qiE 'text|json|xml|html|empty' || exit 0

case "$path" in
  *.po|*.pot|*.svg|*.html.j2) exit 0 ;;
esac

LC_ALL=C sed -i '' \
  -e 's/\xE2\x80\x94/-/g' \
  -e 's/\xE2\x80\x93/-/g' \
  -e 's/\xE2\x80\x9C/"/g' \
  -e 's/\xE2\x80\x9D/"/g' \
  -e 's/\xE2\x80\x98/'\''/g' \
  -e 's/\xE2\x80\x99/'\''/g' \
  -e 's/\xE2\x80\xA6/.../g' \
  -e 's/\xE2\x86\x92/->/g' \
  -e 's/\xE2\x86\x90/<-/g' \
  -e 's/\xE2\x87\x92/=>/g' \
  "$path" || true

exit 0
