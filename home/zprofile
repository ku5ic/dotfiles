# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1

# PATH, highest priority first. HOMEBREW_PREFIX is set by the shellenv eval above;
# using it instead of `brew --prefix` keeps this block from spawning a brew process
# per entry. $HOMEBREW_PREFIX/bin is already on PATH via the same eval.
path=(
  "$HOME/.local/bin"
  "$HOME/.claude/plugins/marketplaces/ku5ic/bin"
  "$HOME/.dotfiles/scripts"
  "$HOMEBREW_PREFIX/opt/openjdk/bin"
  "$HOMEBREW_PREFIX/opt/ncurses/bin"
  "$HOMEBREW_PREFIX/opt/openssl@3/bin"
  "${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  "$HOMEBREW_PREFIX/opt/rustup/bin"
  $path
)

# Dotfiles and claude-kit
export DOTFILES_DIR="$HOME/.dotfiles"
export CLAUDE_KIT_PERSONAL="$DOTFILES_DIR/claude"

# Node
export UV_THREADPOOL_SIZE=4

# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
