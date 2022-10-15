export PATH="/opt/homebrew/bin:$PATH"
export PATH="$(yarn global bin):$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH

# export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
# export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"
# export PIPENV_VENV_IN_PROJECT=1
# eval "$(pipenv --completion)"
# eval "$(pyenv init -)"
# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
# alias brew="env PATH=${PATH//$(pyenv root)\/shims:/} brew"

pyclean () {
  find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
}

# Node
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# create_git_branch_from_jira() {
#   declare -l story_type
#   declare -u stroy_id
#   declare -l story_title
#   story_type="$1"
#   story_id="$2"
#   story_title="$3"
#   story_title="${story_title// /_}"
#   story_title="${story_title//-/}"

#   git checkout -b  "${story_type}/${story_id}_${story_title/ /_}"
# }

tmux_2e-systems_eeBook() {
   tmuxinator start 2e-eebook project=eeBook/eebkgweb -n core
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-aee-custom  -n aee
   tmuxinator start 2e-eebook project=eeBook/eebkgweb-bwa-custom -n bwa
}

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
