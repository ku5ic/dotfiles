# Prompt
eval "$(starship init zsh)"

export CLICOLOR=1

# Zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# Zsh history & completions
# autoload -Uz compinit
# if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump) ]; then
#   compinit
#   echo "Initializing Completions..."
# else
#   compinit -C
# fi

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks   # remove superfluous blanks from history items
setopt inc_append_history   # save history entries as soon as they are entered
setopt share_history        # share history between different instances of the shell
setopt correct_all          # autocorrect commands
setopt auto_list            # automatically list choices on ambiguous completion
setopt auto_menu            # automatically use menu completion
setopt always_to_end        # move cursor to end if word had one match

zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:*' completer _expand _complete _correct _approximate # enable approximate matches for completion

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# Enable vi mode
bindkey -v

# bindkey '^[[H' beginning-of-line
# bindkey '^[[F' end-of-line
# bindkey '^[[3~' delete-char
# bindkey '^[b' backward-word
# bindkey '^[f' forward-word
# bindkey '^[d' kill-word
# bindkey '^[^?' backward-kill-word
# bindkey "\e[3~" delete-char

# aliases
source ~/.aliases.zsh

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

ssh-add -K ~/.ssh/id_rsa &> /dev/null
ssh-add -A &> /dev/null

# fzf
export FZF_DEFAULT_OPTS="
--layout=reverse
--info=inline
--height=80%
--multi
--preview-window=:hidden
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --theme=TwoDark {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
--bind '?:toggle-preview'
"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules/*" --glob "!vendor/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 1Password-cli completions
eval "$(op completion zsh)"; compdef _op op

export LANG=en_US.UTF-8
# You don't strictly need this collation, but most technical people
# probably want C collation for sane results
export LC_COLLATE=C

# PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$(yarn global bin):$PATH"
export PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="~/.nvm/versions/node/v16.15.0/bin:$PATH"
export PATH="/opt/homebrew/opt/ncurses/bin:$PATH"
export PATH

# rbenv
eval "$(rbenv init - zsh)"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# groovy
export GROOVY_HOME=/opt/homebrew/opt/groovy/libexec

# Node
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
