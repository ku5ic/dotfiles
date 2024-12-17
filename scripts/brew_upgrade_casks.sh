#!/usr/bin/env bash

# Capture the output of brew outdated into a variable
output=$(brew outdated --cask --greedy --verbose)

# Check if there is any output
if [[ -z "$output" ]]; then
  echo "No outdated casks found. Exiting."
  return 0
else
  # Display the output to the user
  echo "$output"

  # Prompt user to proceed with the second command
  echo -n "Do you want to run 'brew upgrade --cask --greedy'? (y/n): "
  read response

  # Check the user's response
  if [[ "$response" == "y" || "$response" == "Y" ]]; then
    brew upgrade --cask --greedy
  else
    echo "Skipping the upgrade command."
  fi
fi
