# Define the environment variable ZPLUG_HOME
export ZPLUG_HOME=/usr/local/opt/zplug

# Loads zplug
source $ZPLUG_HOME/init.zsh

# Clear packages
zplug clear

# Packages
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "oz/safe-paste"
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Theme
zplug denysdovhan/spaceship-prompt, use:spaceship.zsh, from:github, as:theme
SPACESHIP_VI_MODE_SHOW=false

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

export CLICOLOR=1

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export PATH="/Users/$HOME/.rbenv/bin:$PATH"
export PATH="/Users/$HOME/.local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

export HOMEBREW_GITHUB_API_TOKEN=4070edd134a475df161bc5be0f5246198c17ffe6

export TERM="xterm-256color"
alias tmux="env TERM=xterm-256color tmux"

# Zsh history & completions
HISTSIZE=5000             # How many lines of history to keep in memory
HISTFILE=~/.zsh_history   # Where to save history to disk
SAVEHIST=5000             # Number of history entries to save to disk
setopt appendhistory      # Append history to the history file (no overwriting)
setopt sharehistory       # Share history across terminals
setopt incappendhistory   # Immediately append to the history file, not just when a term is killed

bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

autoload -U compinit && compinit

fpath=(/usr/local/share/zsh-completions $fpath)

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

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

ssh-add -K ~/.ssh/id_rsa &> /dev/null
ssh-add -A &> /dev/null
