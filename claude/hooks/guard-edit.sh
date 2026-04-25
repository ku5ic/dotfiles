#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit.
# Blocks writes to risky paths regardless of permission rules.
set -euo pipefail

payload="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

path="$(printf '%s' "$payload" | jq -r '
  .tool_input.file_path
  // .tool_input.path
  // .tool_input.target_file
  // empty
')"

[[ -z "$path" ]] && exit 0

block() {
  echo "Blocked by guard-edit.sh: $1" >&2
  echo "Path: $path" >&2
  exit 2
}

case "$(basename "$path")" in
  package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb|Gemfile.lock|Cargo.lock|composer.lock|poetry.lock|uv.lock|requirements.txt.lock)
    block "lockfile edit. Use the package manager."
    ;;
esac

[[ "$path" =~ /\.git/ ]] && block "edit inside .git/"

case "$path" in
  $HOME/.zshrc|$HOME/.zprofile|$HOME/.bashrc|$HOME/.bash_profile|$HOME/.profile)
    block "direct edit to a shell rc file. Use the dotfiles repo."
    ;;
esac

if [[ "$path" =~ \.github/workflows/.*\.ya?ml$ ]]; then
  echo "guard-edit: editing CI workflow $path" >&2
fi

exit 0
