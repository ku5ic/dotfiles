#!/usr/bin/env bash
set -euo pipefail

output=$(brew outdated --cask --greedy --verbose)

if [[ -z "$output" ]]; then
  echo "No outdated casks found. Exiting."
  exit 0
fi

echo "$output"

brew upgrade --cask --greedy
