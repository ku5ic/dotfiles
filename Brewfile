# frozen_string_literal: true

tap 'devdotfast/tap', trusted: { formula: ['diffr'] }
tap 'jesseduffield/lazygit', trusted: true
tap 'owenthereal/upterm', trusted: true

# Shell and terminal
brew 'atuin'                       # shell history sync and search backed by SQLite
brew 'bash'                        # newer bash than the macOS bundled 3.2
brew 'direnv'                      # per-directory environment variable loader
brew 'fastfetch'                   # system info display run on terminal launch
brew 'fzf'                         # fuzzy finder, integrated into shell history and Neovim Telescope
brew 'less'                        # current GNU less from Homebrew for pager features
brew 'ncurses'                     # terminal UI library used by tools like nvim and tmux
brew 'reattach-to-user-namespace'  # tmux helper that fixes pasteboard access on macOS
brew 'starship'                    # cross-shell prompt configured via config/starship.toml
brew 'tmuxinator'                  # tmux session manager driven by .tmuxinator configs
brew 'tpm'                         # tmux plugin manager loaded from .tmux.conf
brew 'zoxide'                      # directory jumper that learns frequently visited paths
brew 'zsh'                         # modern zsh from Homebrew, set as the login shell
brew 'zsh-autosuggestions'         # inline command suggestions sourced from history
brew 'zsh-completions'             # extra completion definitions loaded by zsh
brew 'zsh-syntax-highlighting'     # live command-line syntax coloring

# Search, files and text
brew 'bat'        # syntax-highlighted cat replacement, aliased as the default file viewer
brew 'coreutils'  # the GNU core utilities, overriding the BSD versions on macOS
brew 'eza'        # modern ls replacement with color and git status
brew 'fd'         # simpler find replacement, used as the file backend by Telescope and fzf
brew 'gnu-sed'    # the GNU sed, for portable script behavior across macOS and Linux
brew 'grep'       # the GNU grep, matching Linux flag behavior on macOS
brew 'moreutils'  # sponge, ts, vipe and other shell pipeline utilities missing from coreutils
brew 'pandoc'     # document converter for markdown workflows
brew 'ripgrep'    # fast recursive grep, default search backend in Neovim and shell
brew 'sd'         # intuitive find-and-replace CLI, a safer modern sed for scripted substitutions
brew 'tree'       # directory listing tool
brew 'watchexec'  # filesystem-driven command runner

# System monitoring
brew 'bandwhich'  # per-process network bandwidth monitor, completes procs/dust with the network layer
brew 'dust'       # disk usage explorer with a tree view
brew 'procs'      # modern ps replacement with tree and color output

# Git and code review
brew 'devdotfast/tap/diffr'  # structural diff viewer behind the /diffr pane, coexists with difftastic
brew 'difftastic'            # structural diff tool wired in as GIT_EXTERNAL_DIFF
brew 'gh'                    # the GitHub CLI for PR, issue, and repo workflows
brew 'git'                   # version control, kept current independent of the Xcode Command Line Tools
brew 'git-absorb'            # auto-generate fixup commits that absorb staged hunks into the right prior commit
brew 'git-delta'             # diff pager with syntax highlighting, set as core.pager
brew 'lazygit'               # terminal git UI bound to the lg alias
brew 'tig'                   # terminal git history browser

# Code analysis and architecture
brew 'adr-tools'        # architecture decision records
brew 'ast-grep'         # structural code search and rewrite, complements ripgrep for syntax-level matches
brew 'ctags'            # tag generator for code navigation
brew 'git-quick-stats'  # contributor and churn stats per area, for finding who to ask
brew 'hyperfine'        # command-line benchmarking tool
brew 'scc'              # per-file size and complexity counter, ranks hotspots alongside tokei
brew 'structurizr'      # architecture models as code (C4) with a local preview server, pulls in openjdk
brew 'tokei'            # source code line counter by language

# Linters, formatters and tests
brew 'actionlint'  # linter for GitHub Actions workflow files
brew 'bats-core'   # bash test framework used by tests/guard-bash.bats
brew 'shellcheck'  # static analysis for shell scripts, used by claude-kit's format-dispatch hook and run-checks
brew 'shfmt'       # formatter for shell scripts
brew 'stylua'      # formatter for Lua code

# Languages, runtimes and build
brew 'asdf'     # runtime version manager driving Node, Ruby, Python via .tool-versions
brew 'openssl'  # the TLS toolkit linked against by asdf-built Rubies, Pythons, and other compiled deps
brew 'pnpm'     # fast disk-efficient JavaScript package manager
brew 'uv'       # fast Python package and virtualenv manager
brew 'yarn'     # package manager for Node projects that lock with yarn

# Data formats (JSON, YAML, CSV)
brew 'gron'  # flattens JSON into greppable path=value lines, faster than writing jq paths blind
brew 'jc'    # converts CLI output to JSON for piping into jq
brew 'jq'    # processes JSON in shell pipelines
brew 'qsv'   # fast CSV/TSV toolkit (select, join, stats), the CSV counterpart to jq and yq
brew 'yq'    # processes YAML and TOML with jq-compatible syntax

# Containers, cloud and infra
brew 'awscli'          # the AWS CLI for managing cloud resources
brew 'caddy'           # reverse proxy with automatic HTTPS, used by the ZanaPhysio deploy stack
brew 'doctl'           # the DigitalOcean CLI, used to bootstrap and inspect the ZanaPhysio droplet
brew 'kind'            # runs local Kubernetes clusters in Docker for testing manifests and charts
brew 'kubernetes-cli'  # kubectl, the Kubernetes cluster CLI
brew 'opentofu'        # infrastructure-as-code CLI (tofu), used to provision the ZanaPhysio droplet
brew 'tilt'            # tilt.dev local dev environment for Kubernetes, used by Tiltfile and Tiltfile.lock

# Databases
brew 'pgcli'          # the PostgreSQL CLI with autocompletion and syntax highlighting
brew 'postgresql@18'  # local PostgreSQL server for development databases
brew 'redis'          # in-memory data store for local development

# Network and HTTP
brew 'httpie'       # human-friendly HTTP client for API testing
brew 'mkcert'       # locally trusted dev certificate generator
brew 'ssh-copy-id'  # helper for installing public keys onto remote hosts
brew 'wget'         # downloader for HTTP and FTP in scripts

# Security and secrets
brew 'gitleaks'    # secret scanner for git repositories
brew 'gnupg'       # cryptography and signing tool for SSH and Git commit verification
brew 'trufflehog'  # deep secrets scanner for git history, broader credential coverage than gitleaks
brew 'ykman'       # authenticator CLI for managing Yubikeys, used by GitHub and 1Password

# Neovim dependencies
brew 'cmake'            # build system required by Neovim plugins with native components
brew 'imagemagick'      # image manipulation library used by Neovim image plugins
brew 'lua'              # interpreter required by Neovim Lua plugins and luarocks-based dependencies
brew 'luarocks'         # package manager for Neovim Lua plugins that need extensions
brew 'lynx'             # text web browser, used by CopilotChat.nvim
brew 'neovim'           # primary editor, configured under config/nvim
brew 'rust'             # toolchain required by Neovim plugins with native components (e.g. blink.cmp)
brew 'tree-sitter-cli'  # parser CLI used by nvim-treesitter to compile grammars on the main branch

# Images and media
brew 'chafa'   # terminal image renderer used by fastfetch and similar tools
brew 'oxipng'  # optimizes PNG assets

# Development
cask 'claude-code@latest'         # the Claude Code CLI pinned to the latest channel
cask 'neovide-app'                # graphical frontend for Neovim
cask 'orbstack'                   # container runtime for local development, replaces Docker Desktop
cask 'owenthereal/upterm/upterm'  # shares terminal sessions securely over the web
cask 'postman'                    # client for building HTTP API requests by hand
cask 'tableplus'                  # macOS GUI for PostgreSQL, MySQL, SQLite, and other databases
cask 'visual-studio-code'         # secondary editor for tasks Neovim is not used for
cask 'wezterm'                    # primary terminal emulator, configured under config/wezterm

# Browsers
cask 'firefox@developer-edition'  # primary browser for web development with built-in devtools features
cask 'google-chrome'              # browser for web development

# Design
cask 'affinity'  # design suite (photo, designer, publisher) for creative work and asset editing
cask 'figma'     # design tool for UI work

# Productivity and writing
cask 'boop'       # scratchpad for ad-hoc text transformations
cask 'claude'     # the Claude desktop app
cask 'cleanshot'  # screenshot and screen recording tool
cask 'typora'     # markdown editor with live preview

# Security
cask '1password'      # password manager desktop app
cask '1password-cli'  # the 1Password CLI for shell and SSH agent integration
cask 'adguard'        # system-wide ad and tracker blocker

# Communication
cask 'slack'  # team chat client
cask 'zoom'   # video conferencing client

# Media
cask 'spotify'       # music player
cask 'transmission'  # client for BitTorrent downloads
cask 'vlc'           # media player

# System utilities
cask 'fliqlo'          # flip clock screensaver
cask 'onyx'            # system maintenance utility for macOS
cask 'the-unarchiver'  # archive extraction utility
cask 'rectangle-pro'   # window management utility with keyboard shortcuts and snapping

# Fonts
cask 'font-fira-code-nerd-font' # the Nerd Font used by WezTerm and Neovim

# Mac App Store
mas '1Password for Safari', id: 1_569_813_296  # the 1Password browser extension for Safari
mas 'Keynote', id: 361_285_480                 # presentation editor
mas 'Numbers', id: 361_304_891                 # spreadsheet editor
mas 'Pages', id: 361_309_726                   # document editor
mas 'Speedtest', id: 1_153_157_709             # network speed test utility
mas 'iMovie', id: 408_981_434                  # video editor
