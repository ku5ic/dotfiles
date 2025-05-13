#!/usr/bin/env bash

declare -A projects_keys=(
["eebook"]="eebook/eebkgweb"
["eebook-bwa"]="eebook/eebkgweb-bwa-custom"
["eebook-eed"]="eebook/eebkgweb-eed-custom"
["eepayweb"]="eepay/eepayweb"
["eeopaque-fe-cli"]="eeopaque/eeopqfecli"
["eeopaque-fe-srv"]="eeopaque/eeopqfesrv"
["bti-fe"]="bti/btife"
)

# Convert keys to an array to identify the last project
keys=("${!projects_keys[@]}")
last_index=$((${#keys[@]} - 1))

# Loop through each project
for i in "${!keys[@]}"; do
  key="${keys[$i]}"
  project_path="${projects_keys[$key]}"

  echo "Starting tmux session for project: $key, Path: $project_path"

  if [[ $i -lt $last_index ]]; then
    # Start tmuxinator in the background and detach immediately
    nohup tmuxinator start "2e-eebook" "project=${project_path}" -n "${key}"
  else
    # For the last project, run interactively
    tmuxinator start "2e-eebook" "project=${project_path}" -n "${key}"
  fi
done
