# dotfiles
export DOTFILES_DIR="$HOME/.dotfiles"

# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# Custom scripts
source "$DOTFILES_DIR/scripts/brew.sh"
source "$DOTFILES_DIR/scripts/2e.sh"
source "$DOTFILES_DIR/scripts/jira.sh"
source "$DOTFILES_DIR/scripts/misc.sh"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
