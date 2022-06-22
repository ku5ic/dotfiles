PATH="/usr/local/bin:$PATH"
PATH="/usr/local/sbin:$PATH"
PATH="/usr/local/opt/python/libexec/bin:$PATH"
PATH="/usr/local/opt/ruby/bin:$PATH"
PATH="/usr/local/opt/ncurses/bin:$PATH"
PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="$(yarn global bin):$PATH"
export PATH

# Ruby
eval "$(rbenv init - --no-rehash)"
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
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh" # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion


create_git_branch_from_jira() {
  declare -l story_type
  declare -u stroy_id
  declare -l story_title
  story_type="$1"
  story_id="$2"
  story_title="$3"
  story_title="${story_title// /_}"
  story_title="${story_title//-/}"

  git checkout -b  "${story_type}/${story_id}_${story_title/ /_}"
}

tmux_gaggleamp() {
  tmuxinator start rails-project workspace=~/Projects/Gaggleamp/Code/Amplify -n Amplify
  tmuxinator start rails-project workspace=~/Projects/Gaggleamp/Code/sso -n sso
  tmuxinator start rails-project workspace=~/Projects/Gaggleamp/Code/Engage -n Engage
}

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}
