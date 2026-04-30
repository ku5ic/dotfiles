#!/usr/bin/env bash
set -euo pipefail

output=$(brew outdated --cask --greedy --verbose)

if [[ -z "$output" ]]; then
  echo "No outdated casks found. Exiting."
  exit 0
fi

echo "$output"

printf 'Do you want to run "brew upgrade --cask --greedy"? (y/n): '
read -r response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
  brew upgrade --cask --greedy
else
  echo "Skipping the upgrade command."
fi
