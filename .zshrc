# Prompt
eval "$(starship init zsh)"

# Zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# setopt correct              # enable autocorrect for command names
setopt correct_all          # autocorrect for all arguments (commands and their arguments)
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks   # remove superfluous blanks from history items
setopt inc_append_history   # save history entries as soon as they are entered
setopt share_history        # share history between different instances of the shell
setopt auto_list            # automatically list choices on ambiguous completion
setopt auto_menu            # automatically use menu completion
setopt always_to_end        # move cursor to end if word had one match

zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:*' completer _expand _complete _correct _approximate # enable approximate matches for completion
zstyle ':completion:*' matcher-list 'r:|[._-]=*' # match dashes, underscores and dots interchangeably
zstyle ':completion:*:corrections' ignored-patterns '.*' '_*' # ignore files starting with . or _ for corrections
zstyle ':completion:*:functions' ignored-patterns '.*' '_*' # ignore files starting with . or _ for functions
zstyle ':completion:*:commands' ignored-patterns '.*' '_*' # ignore files starting with . or _ for commands

if type brew &>/dev/null; then
  FPATH=${ASDF_DATA_DIR:-$HOME/.asdf}/completions:$FPATH
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit && compinit
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
export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --theme=TwoDark {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
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

# FastFetch, Fast, highly customisable system info script
# fastfetch
