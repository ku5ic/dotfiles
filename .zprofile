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

# github
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"

# PATH
export PATH="$(brew --prefix rustup)/bin:$PATH"
export PATH="$(brew --prefix)/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$(brew --prefix)/opt/openssl@3/bin:$PATH"
export PATH="$(brew --prefix)/opt/ncurses/bin:$PATH"
export PATH="$(brew --prefix)/opt/openjdk/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH="$HOME/.claude/bin/:$PATH"
export PATH
