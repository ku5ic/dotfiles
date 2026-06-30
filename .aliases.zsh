# General Navigation and File Management
alias ls='ls --color'          # enable colorized output for `ls` (if supported)
alias ll='ls -lh'              # Human-readable long listing (with file sizes)
alias la='ls -lha'             # Human-readable listing including hidden files
alias l='ls -CF'               # Lists files in columns, appends '/' to directories
alias ..='cd ..'               # Moves up one directory level
alias ...='cd ../..'           # Moves up two directory levels
alias ~='cd ~'                 # Quick shortcut to navigate to the home directory
alias mkcd='foo(){ mkdir -p "$1" && cd "$1"; }; foo' # Make a new directory and immediately navigate into it

# Git Shortcuts
alias gst='git status'         # Check the status of the git repository
alias ga='git add'             # Add changes to the staging area
alias gc='git commit'          # Commit changes
alias gp='git push'            # Push changes to the remote repository
alias gl='git log --oneline --graph --decorate' # View a simplified git log with graph and decorations
alias gco='git checkout'       # Check out a branch
alias gb='git branch'          # List branches
alias gd='git diff'            # View differences between commits, branches, etc.
alias gcm='git checkout main'  # Check out the main branch
alias gscf='git diff --name-only --diff-filter=U --relative' # Show conflicted files in a merge
alias lg='lazygit'             # Open lazygit

# Git Submodule Shortcuts
alias gsmi='git submodule update --init --recursive'                                                              # Initialize and update all submodules (run after cloning a repo with submodules)
alias gsmst='git submodule foreach "git stash"'                                                                   # Stash working-tree changes inside each submodule (git stash cannot stash gitlink pointer changes -- use gsmwip for that)
alias gsmstp='git submodule foreach "git stash pop"'                                                              # Pop stash inside each submodule
alias gsmup='git submodule foreach "git fetch && git checkout \$(git symbolic-ref refs/remotes/origin/HEAD | cut -d/ -f4) && git pull"'  # Checkout each submodule's default branch and pull; requires origin/HEAD to be set (run: git remote set-head origin --auto)
alias gsmwip='git add -u && git commit -m "wip: submodule pointer updates"'                                       # Save staged submodule pointer changes as a WIP commit (workaround: git stash cannot stash gitlinks)
alias gsmwippop='git reset --soft HEAD~1'                                                                         # Restore the last WIP submodule commit back to staged state
alias update_submodules='git submodule update --init --recursive && git submodule foreach "git fetch && git checkout \$(git symbolic-ref refs/remotes/origin/HEAD | cut -d/ -f4) && git pull"' # Update all submodules to their latest commit on their default branch

# System Management
alias df='df -h'               # Shows disk usage in human-readable format
alias du='du -h'               # Displays directory size in human-readable format
alias free='vm_stat | awk '\''/free/ {print $3/256" MB"}'\'''  # Shows free memory in macOS (macOS uses `vm_stat`)
alias psu='ps aux | sort -nrk 3,3 | head'  # Shows top CPU-consuming processes (macOS `ps` doesn't support `--sort`)

# Networking
alias ping='ping -c 5'         # Pings a host 5 times by default
alias wget='wget -c'           # Enables download resume for `wget` (if `wget` is installed, as it's not default in macOS)
alias curl='curl -O'           # Saves files with the same name as the URL

# File Management Aliases
alias rm='rm -i'               # Prompt before deletion
alias cp='cp -i'               # Prompt before overwriting files
alias mv='mv -i'               # Prompt before overwriting files
alias tree='tree -C'           # Quick tree listing
alias copy_path='pwd | pbcopy' # Copy current path to clipboard (macOS specific)

# Miscellaneous
alias cls='clear'              # Clears the terminal screen
alias grep='grep --color=auto' # Adds color to `grep` output to highlight matches
alias mux='tmuxinator'
# uptmux <session-name>: host an upterm pair-programming session backed by a named tmux session.
# Clients are forced into 'tmux attach -t <name>' so both parties share the same pane.
# Switch to the "upterm" window inside the session to see the SSH sharing link at any time.
uptmux() {
  local session="${1:?usage: uptmux <session-name>}"
  tmux new-session -d -s "$session" 2>/dev/null || true
  if ! tmux list-windows -t "$session" -F "#{window_name}" 2>/dev/null | grep -q "^upterm$"; then
    tmux new-window -t "${session}:" -n upterm \
      "until upterm session list | grep -q ssh; do sleep 0.3; done; upterm session list; printf '\nPress enter to close...' && read -r"
  fi
  upterm host --force-command "tmux attach -t $session" -- tmux new-session -A -s "$session"
}
alias brew_all="brew update; brew upgrade; brew upgrade --cask; brew cleanup --prune=all; brew autoremove; brew doctor; brew_upgrade_casks" # Update all brew packages
alias brew_reset='brew update-reset "$(brew --repository)"' # Reset Homebrew to a clean state
alias brew_clean='brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" --force' # Clean up Homebrew packages not listed in the Brewfile
alias brew_install='brew bundle --file="$DOTFILES_DIR/Brewfile"' # Install Homebrew packages from the Brewfile
alias bat="bat --style=numbers --color=always --theme=TwoDark" # bat alias with theme
alias dotfiles="cd $DOTFILES_DIR" # Navigate to the dotfiles directory

# Set up your preferred editor (e.g., Neovim or Vim)
alias vim='nvim'
alias vi='nvim'

# Override the default `tree` command to remove color codes for better readability in terminals that don't support them
function tree() { command tree -n "$@" | sed 's/\x1b\[[0-9;]*m//g'; }

#
# Load custom completion helpers written as .sh files
for completion_script in "$DOTFILES_DIR/completions/"*.sh; do
  [[ -f "$completion_script" ]] || continue
  source "$completion_script"
done

# Automatically create aliases for executable scripts
for script in "$DOTFILES_DIR/scripts"/*.sh; do
  [[ -x "$script" ]] || continue

  alias_name=$(basename "$script" .sh)
  alias "$alias_name"="$script"

  completion_fn="_${alias_name}"

  if (( $+functions[$completion_fn] )); then
    compdef "$completion_fn" "$alias_name"
  fi
done
