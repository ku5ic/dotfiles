# Source a cached copy of an init script instead of eval'ing the tool's output on every
# start: after boot each binary's first exec is scanned (~0.5s). The key must change
# when the output can, e.g. the Cellar path, which carries the version.
# Usage: _cached_init <key> <command...>. Flush with: rm -rf ~/.cache/zsh-init
_cached_init() {
  [[ -n $1 ]] || return
  local file=${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init/${1//\//%}.zsh
  if [[ ! -s $file ]]; then
    mkdir -p ${file:h}
    # Temp file plus mv: a shell starting in parallel never sources a half-written file.
    "${@:2}" >| $file.$$ && mv -f $file.$$ $file || { rm -f $file.$$; return 1 }
  fi
  source $file
}

# Environment
export LANG=en_US.UTF-8
export LC_COLLATE=C # C collation for predictable sort order
# LC_ALL overrides every LC_* above; unset it too when inherited (e.g. from a tmux server env).
unset LC_ALL
export CLICOLOR=1

# Editor: nvim for interactive shells, no-op for scripts and background contexts
if [[ -o interactive ]]; then
  export EDITOR='nvim'
  export VISUAL='nvim'
else
  export EDITOR='true'
  export VISUAL='true'
  export GIT_EDITOR='true'
fi

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks   # remove superfluous blanks from history items
setopt inc_append_history   # save history entries as soon as they are entered
setopt share_history        # share history between different instances of the shell

# Options
setopt correct       # autocorrect command names only
setopt auto_list     # automatically list choices on ambiguous completion
setopt auto_menu     # automatically use menu completion
setopt always_to_end # move cursor to end if word had one match
PROMPT_EOL_MARK=""

# Prompt and hooks
_cached_init ${commands[starship]:A} starship init zsh
_cached_init ${commands[direnv]:A} direnv hook zsh
_cached_init ${commands[zoxide]:A} zoxide init zsh

# Plugins
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Completion
zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:*' completer _complete # plain completion only, no approximate or correction completers
zstyle ':completion:*' matcher-list 'r:|[._-]=*' # match dashes, underscores and dots interchangeably
zstyle ':completion:*:corrections' ignored-patterns '.*' '_*' # ignore files starting with . or _ for corrections
zstyle ':completion:*:functions' ignored-patterns '.*' '_*' # functions starting with . or _ are usually private and not useful to complete
zstyle ':completion:*:commands' ignored-patterns '.*' '_*' # commands starting with . or _ are usually private and not useful to complete

fpath=("$DOTFILES_DIR/completions" $fpath) # custom completions from the dotfiles repo
fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath) # asdf completions
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath) # also added by brew shellenv, but only login shells run .zprofile
fi
fpath+=("$HOME/.orbstack/shell/completions/zsh") # same: OrbStack's init in .zprofile is login-only

# Login and non-login shells must see the same fpath, or compinit rebuilds .zcompdump on every switch.
typeset -U fpath

# Unexport: an inherited FPATH grows in nested shells, which invalidates .zcompdump
# and makes compinit rebuild it every time.
typeset +x FPATH

autoload -Uz compinit
compinit
setopt completealiases # enable completion for aliases

# Key bindings
bindkey -v

# Aliases
source ~/.aliases.zsh

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
_cached_init ${commands[fzf]:A} fzf --zsh

# atuin (after vi mode and fzf: both rebind Ctrl+R and would win if loaded first)
_cached_init ${commands[atuin]:A} atuin init zsh

# 1Password-cli completions
_cached_init ${commands[op]:A} op completion zsh && compdef _op op

# Claude-kit. The wrapper script's path never changes, so key on the plugin version.
if [[ -n ${commands[kit]} && $(<${commands[kit]:A:h:h}/.claude-plugin/plugin.json) =~ '"version"[[:space:]]*:[[:space:]]*"([^"]+)"' ]]; then
  _cached_init kit-$match[1] kit completion zsh
fi

# Machine-local overrides, last so they win
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
