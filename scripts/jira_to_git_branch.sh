#!/usr/bin/env bash

# Convert story_id to uppercase and story_title to lowercase
story_id=$(echo "$2" | tr '[:lower:]' '[:upper:]')
story_title=$(echo "$3" | tr '[:upper:]' '[:lower:]')

# Assign input parameters to variables
branch_type="$1"

# Validate branch type
case "$branch_type" in
  feature|bugfix|hotfix)
    ;;
  *)
    echo "Invalid branch type. Allowed types are: feature, bugfix, hotfix."
    return 1
    ;;
esac

# Format story_title: replace spaces with underscores, remove hyphens, and non-alphanumeric characters
story_title="${story_title// /_}"             # Replace spaces with underscores
story_title="${story_title/__/ /_}"           # Replace double underscores with a single underscore
story_title="${story_title//-/}"              # Remove hyphens
story_title="${story_title//[^a-zA-Z0-9_]/}"  # Remove non-alphanumeric characters

# Construct branch name
branch_name="${branch_type}/${story_id}/${story_title}"
branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9]*$//')

# Create a new git branch with the formatted story_id and story_title
git checkout -b "${branch_name}"
