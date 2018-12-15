# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="bullet-train"
COMPLETION_WAITING_DOTS="true"

plugins=(git colorize)

autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export PATH="/Users/$HOME/.rbenv/shims:$PATH"
export PATH="/Users/$HOME/.pyenv:$PATH"
export PATH="/Users/$HOME/.local/bin:$PATH"

export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/mysql@5.7/lib"
export CPPFLAGS="-I/usr/local/opt/mysql@5.7/include"
export PKG_CONFIG_PATH="/usr/local/opt/mysql@5.7/lib/pkgconfig"

export PATH="/usr/local/opt/ruby/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"

export HOMEBREW_GITHUB_API_TOKEN=4070edd134a475df161bc5be0f5246198c17ffe6

export TERM="xterm-256color"
alias tmux="env TERM=xterm-256color tmux"

eval "$(rbenv init - --no-rehash zsh)"
eval "$(pyenv init -)"

#if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Always load tmux
#if [[ ! $TERM =~ screen ]]; then
    #exec tmux
#fi

# nvm settings
export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"

# RVM settings
# if [[ -s ~/.rvm/scripts/rvm ]] ; then
#   RPS1="%{$fg[yellow]%}rvm:%{$reset_color%}%{$fg[red]%}\$(~/.rvm/bin/rvm-prompt)%{$reset_color%} $EPS1"
# else
#   if which rbenv &> /dev/null; then
#     RPS1="%{$fg[yellow]%}rbenv:%{$reset_color%}%{$fg[red]%}\$(rbenv version | sed -e 's/ (set.*$//')%{$reset_color%} $EPS1"
#   fi
# fi

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

ssh-add -K ~/.ssh/id_rsa &> /dev/null
ssh-add -A &> /dev/null
