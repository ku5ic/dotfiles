#!/usr/bin/env bash
set -euo pipefail

MANIFEST="$HOME/.claude/plugins/installed_plugins.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "No installed plugins manifest found at $MANIFEST"
  exit 1
fi

plugins=$(jq -r '.plugins | keys[]' "$MANIFEST")

if [[ -z "$plugins" ]]; then
  echo "No installed plugins found."
  exit 0
fi

echo "Updating Claude plugins:"
echo "$plugins" | sed 's/^/  /'
echo

failed=()

while IFS= read -r plugin; do
  echo "-> $plugin"
  if ! claude plugin update "$plugin"; then
    failed+=("$plugin")
  fi
done <<<"$plugins"

echo

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Failed to update:"
  printf '  %s\n' "${failed[@]}"
  exit 1
else
  echo "All plugins updated. Restart Claude Code to apply changes."
fi
