# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

pyclean () {
  find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
}

jira_to_git_branch() {
  # Convert story_id to uppercase and story_title to lowercase
  declare -u story_id
  declare -l story_title

  # Assign input parameters to variables
  branch_type="$1"
  story_id="$2"
  story_title="$3"

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
  story_title="${story_title// /_}"       # Replace spaces with underscores
  story_title="${story_title//-/}"        # Remove hyphens
  story_title="${story_title//[^a-zA-Z0-9_]/}"  # Remove non-alphanumeric characters

  # Construct branch name
  branch_name="${branch_type}/${story_id}/${story_title}"
  branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9]*$//')

  # Create a new git branch with the formatted story_id and story_title
  git checkout -b "${branch_name}"
}

2e_projects_tmux() {
    typeset -A projects=(
        ["eebook"]="eebook/eebkgweb"
        ["eebook-bwa"]="eebook/eebkgweb-bwa-custom"
        ["eebook-eed"]="eebook/eebkgweb-eed-custom"
        ["eepayweb"]="eepay/eepayweb"
        ["eepxa-app"]="mobile/eepxa-app"
        ["eeopaque-fe-cli"]="eeopaque/eeopqfecli"
        ["eeopaque-fe-srv"]="eeopaque/eeopqfesrv"
        ["bti-fe"]="bti/btife"
    )

    for key in "${(@k)projects}"; do
      value=${projects[$key]}
      echo "Key: $key, Value: $value"
      tmuxinator start 2e-eebook project="$value" -n "$key"
    done
}

# Function to perform brew upgrade and prompt for the second command
brew_upgrade_casks() {
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
  }

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}

fix_node_openssl() {
  export NODE_OPTIONS=--openssl-legacy-provider
}

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
