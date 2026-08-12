# dotfiles
export DOTFILES_DIR="$HOME/.dotfiles"

# Node
export UV_THREADPOOL_SIZE=4

# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1

# PATH. HOMEBREW_PREFIX is set by the shellenv eval above; using it instead of
# `brew --prefix` keeps this block from spawning a brew process per entry.
# $HOMEBREW_PREFIX/bin is already on PATH via the shellenv eval above.
export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/openssl@3/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/ncurses/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH="$HOME/.claude/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
