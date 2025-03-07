#!/usr/bin/env bash

# Check if exactly one argument is provided
if [ $# -ne 1 ]; then
  echo -e "\e[31mPlease provide the tag name and try again.\e[0m\n\n\tUsage: retag <tag_name>\n"
  exit 1
fi

# Assign the first argument to the tag variable
tag="$1"

# Force create the tag and push it to the origin
git tag -f "$tag"
git push -f origin "$tag"

