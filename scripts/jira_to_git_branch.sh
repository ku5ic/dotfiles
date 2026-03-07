#!/usr/bin/env bash

# Usage: jira_to_git_branch <branch_type> <story_id> <story_title>

branch_type="$1"
story_id=$(echo "$2" | tr '[:lower:]' '[:upper:]')
story_title=$(echo "$3" | tr '[:upper:]' '[:lower:]')

case "$branch_type" in
  feature|bugfix|hotfix) ;;
  *)
    echo "Invalid branch type. Allowed types are: feature, bugfix, hotfix."
    exit 1  # was: return 1, which only works when sourced
    ;;
esac

# Normalize title: lowercase, spaces to underscores, strip non-alphanumeric
story_title=$(echo "$story_title" \
  | sed 's/ /_/g' \
  | sed 's/__*/_/g' \
  | sed 's/[^a-zA-Z0-9_]//g' \
  | sed 's/_*$//')

branch_name="ku5ic/${branch_type}/${story_id}/${story_title}"

git checkout -b "$branch_name"
