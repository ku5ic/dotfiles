# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

pyclean () {
  find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
}

jira_to_git_branch() {
  declare -u stroy_id
  declare -l story_title
  story_id="$1"
  story_title="$2"
  story_title="${story_title// /_}"
  story_title="${story_title//-/}"

  git checkout -b  "${story_id}/${story_title/ /_}"
}

2e_projects_tmux() {
   tmuxinator start 2e-eebook project=eeBook/eebkgweb -n eeBook &&
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-aee-custom  -n eeBook-aee &&
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-bwa-custom -n eeBook-bwa &&
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-eed-custom  -n eeBook-eed &&
   tmuxinator start 2e-eebook project=eePay/eepayweb -n eePayweb &&
   tmuxinator start 2e-eebook project=mobile/eepxa-app -n eepxa-app &&
   tmuxinator start 2e-eebook project=eeOpaque/eeopqfecli -n eeOpaque
}

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}

fix_node_openssl() {
  export NODE_OPTIONS=--openssl-legacy-provider
}

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
