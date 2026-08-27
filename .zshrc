# Prompt
eval "$(starship init zsh)"

# direnv
eval "$(direnv hook zsh)"

# zoxide
eval "$(zoxide init zsh)"

# Zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

setopt correct              # autocorrect command names only
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks   # remove superfluous blanks from history items
setopt inc_append_history   # save history entries as soon as they are entered
setopt share_history        # share history between different instances of the shell
setopt auto_list            # automatically list choices on ambiguous completion
setopt auto_menu            # automatically use menu completion
setopt always_to_end        # move cursor to end if word had one match


zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:*' completer _complete # enable completion for commands, functions, and aliases
zstyle ':completion:*' matcher-list 'r:|[._-]=*' # match dashes, underscores and dots interchangeably
zstyle ':completion:*:corrections' ignored-patterns '.*' '_*' # ignore files starting with . or _ for corrections
zstyle ':completion:*:functions' ignored-patterns '.*' '_*' # functions starting with . or _ are usually private and not useful to complete
zstyle ':completion:*:commands' ignored-patterns '.*' '_*' # commands starting with . or _ are usually private and not useful to complete

# Completion functions
fpath=("$DOTFILES_DIR/completions" $fpath) # custom completions from the dotfiles repo
fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath) # asdf completions

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
fi

# Unexport: an inherited FPATH grows in nested shells, which invalidates .zcompdump
# and makes compinit rebuild it every time.
typeset +x FPATH

autoload -Uz compinit
compinit

setopt completealiases # enable completion for aliases

# Enable vi mode
bindkey -v

# aliases
source ~/.aliases.zsh

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# fzf
export FZF_DEFAULT_OPTS="\
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
--color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 \
--color=selected-bg:#51576d \
--multi
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --theme=TwoDark {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules/*" --glob "!vendor/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

eval "$(fzf --zsh)"

# atuin (after vi mode and fzf: both rebind Ctrl+R and would win if loaded first)
eval "$(atuin init zsh)"

# 1Password-cli completions
eval "$(op completion zsh)"; compdef _op op

# Editor: nvim for interactive shells, no-op for scripts and background contexts
if [[ -o interactive ]]; then
  export EDITOR='nvim'
  export VISUAL='nvim'
else
  export EDITOR='true'
  export VISUAL='true'
  export GIT_EDITOR='true'
fi

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE
PROMPT_EOL_MARK=""

export CLICOLOR=1
export LANG=en_US.UTF-8
# You don't strictly need this collation, but most technical people
# probably want C collation for sane results
export LC_COLLATE=C
