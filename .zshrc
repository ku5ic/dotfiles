# Prompt
eval "$(starship init zsh)"

# Zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

unsetopt correct_all        # disable autocorrect
setopt correct              # enable autocorrect
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
--tmux bottom,80%
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

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

export CLICOLOR=1
export LANG=en_US.UTF-8
# You don't strictly need this collation, but most technical people
# probably want C collation for sane results
export LC_COLLATE=C

# PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
export PATH="$(brew --prefix)/opt/openssl@3/bin:$PATH"
export PATH="$(brew --prefix)/opt/ncurses/bin:$PATH"
export PATH="$(brew --prefix)/opt/openjdk/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# FastFetch, Fast, highly customisable system info script
# fastfetch
