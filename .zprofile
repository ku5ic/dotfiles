# Paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/python/libexec/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# Ruby
export MALLOC_ARENA_MAX=2
eval "$(rbenv init - --no-rehash)"

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
