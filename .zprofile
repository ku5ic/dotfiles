# dotfiles
export DOTFILES_DIR="$HOME/.dotfiles"

# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
HOMEBREW_NO_ENV_HINTS=1

# PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$(brew --prefix)/opt/openssl@3/bin:$PATH"
export PATH="$(brew --prefix)/opt/ncurses/bin:$PATH"
export PATH="$(brew --prefix)/opt/openjdk/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH

pyclean () {
  find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
}

fix_chromedriver() {
  xattr -d com.apple.quarantine $(which chromedriver)
}

fix_node_openssl() {
  export NODE_OPTIONS=--openssl-legacy-provider
}
