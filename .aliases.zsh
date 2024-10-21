# General Navigation and File Management
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

# System Management
alias df='df -h'               # Shows disk usage in human-readable format
alias du='du -h'               # Displays directory size in human-readable format
alias free='vm_stat | awk '\''/free/ {print $3/256" MB"}'\'''  # Shows free memory in macOS (macOS uses `vm_stat`)
alias psu='ps aux | sort -nrk 3,3 | head'  # Shows top CPU-consuming processes (macOS `ps` doesn't support `--sort`)

# Networking
alias ping='ping -c 5'         # Pings a host 5 times by default
alias wget='wget -c'           # Enables download resume for `wget` (if `wget` is installed, as it's not default in macOS)
alias curl='curl -O'           # Saves files with the same name as the URL

# Safety Aliases
alias cp='cp -i'               # Prompts before overwriting files during copy operations
alias mv='mv -i'               # Prompts before overwriting files during move operations
alias rm='rm -i'               # Prompts before removing files, preventing accidental deletion

# File Management Aliases
alias rm='rm -i'               # Prompt before deletion
alias cp='cp -i'               # Prompt before overwriting files
alias mv='mv -i'               # Prompt before overwriting files
alias tree='tree -C'           # Quick tree listing
alias copy_path='pwd | pbcopy' # Copy current path to clipboard (macOS specific)

# Miscellaneous
alias cls='clear'              # Clears the terminal screen
alias grep='grep --color=auto' # Adds color to `grep` output to highlight matches
alias chmod='chmod --preserve-root'  # Prevents `chmod -R /` from affecting the root directory (added safety)
alias mux=tmuxinator # tmuxinator alias
alias brewall="brew update; brew upgrade; brew upgrade --cask; brew cleanup --prune=all; brew autoremove; brew doctor;" # Update all brew packages
alias bat="bat --style=numbers --color=always --theme=TwoDark" # bat alias with theme

# Set up your preferred editor (e.g., Neovim or Vim)
alias vim='nvim'
alias vi='nvim'
