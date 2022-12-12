# PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$(yarn global bin):$PATH"
export PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH

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
   tmuxinator start 2e-eebook project=eeBook/eebkgweb -n core
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-aee-custom  -n aee
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-bwa-custom -n bwa
   tmuxinator start 2e-eebook project=eePay/eepayweb -n eePayweb
}

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
