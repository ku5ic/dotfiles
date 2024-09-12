# General Navigation and File Management
alias ls='ls --color=auto'     # Adds color to `ls` output for easy differentiation of file types
alias ll='ls -lah'             # Lists all files, with detailed info and human-readable file sizes
alias l='ls -CF'               # Lists files in columns, appends '/' to directories
alias ..='cd ..'               # Moves up one directory level
alias ...='cd ../..'           # Moves up two directory levels
alias ~='cd ~'                 # Quick shortcut to navigate to the home directory

# Git Shortcuts
alias gst='git status'         # Shows the status of the current Git repository
alias gco='git checkout'       # Switches to another Git branch
alias gcm='git commit -m'      # Commits changes with a message
alias gp='git push'            # Pushes committed changes to the remote repository
alias gl='git pull'            # Pulls the latest changes from the remote repository

# System Management
alias df='df -h'               # Shows disk usage in human-readable format
alias du='du -h'               # Displays directory size in human-readable format
alias free='free -m'           # Displays system memory usage in megabytes
alias psu='ps aux --sort=-%cpu | head'  # Shows the top CPU-consuming processes
alias top='htop'               # Replaces `top` with `htop` for a more interactive process viewer (if `htop` is installed)

# Networking
alias ping='ping -c 5'         # Pings a host 5 times by default
alias wget='wget -c'           # Enables download resume for `wget`
alias curl='curl -O'           # Saves files with the same name as the URL

# Safety Aliases
alias cp='cp -i'               # Prompts before overwriting files during copy operations
alias mv='mv -i'               # Prompts before overwriting files during move operations
alias rm='rm -i'               # Prompts before removing files, preventing accidental deletion

# Miscellaneous
alias cls='clear'              # Clears the terminal screen
alias grep='grep --color=auto' # Adds color to `grep` output to highlight matches
alias chmod='chmod --preserve-root'  # Prevents `chmod -R /` from affecting the root directory (added safety)
alias mux=tmuxinator # tmuxinator alias
alias brewall="brew update; brew upgrade; brew upgrade --cask; brew cleanup --prune=all; brew autoremove; brew doctor;" # Update all brew packages
alias bat="bat --style=numbers --color=always --theme=TwoDark" # bat alias with theme
