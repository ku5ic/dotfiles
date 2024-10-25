# Ruby
export DISABLE_SPRING=true

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# Custom scripts
source ~/.dotfiles/scripts/brew.sh
source ~/.dotfiles/scripts/2e.sh
source ~/.dotfiles/scripts/jira.sh
source ~/.dotfiles/scripts/misc.sh

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
