# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="philips"
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

# export PATH="/Users/$HOME/.rbenv/shims:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOMEBREW_GITHUB_API_TOKEN=4070edd134a475df161bc5be0f5246198c17ffe6

source "$HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh"
export TERM=xterm-256color
alias tmux="env TERM=xterm-256color tmux"

eval "$(rbenv init - --no-rehash zsh)"

#if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Always load tmux
#if [[ ! $TERM =~ screen ]]; then
    #exec tmux
#fi

# nodenv settings
# export PATH="$HOME/.nodenv/bin:$PATH"
# eval "$(nodenv init -)"

# RVM settings
if [[ -s ~/.rvm/scripts/rvm ]] ; then
  RPS1="%{$fg[yellow]%}rvm:%{$reset_color%}%{$fg[red]%}\$(~/.rvm/bin/rvm-prompt)%{$reset_color%} $EPS1"
else
  if which rbenv &> /dev/null; then
    RPS1="%{$fg[yellow]%}rbenv:%{$reset_color%}%{$fg[red]%}\$(rbenv version | sed -e 's/ (set.*$//')%{$reset_color%} $EPS1"
  fi
fi

# Android
# export ANDROID_HOME=${HOME}/Library/Android/sdk
# export PATH=${PATH}:${ANDROID_HOME}/tools
# export PATH=${PATH}:${ANDROID_HOME}/platform-tools

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

ssh-add -K ~/.ssh/id_rsa &> /dev/null
ssh-add -A &> /dev/null
