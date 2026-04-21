# ku5ic's Dotfiles

Personal macOS dotfiles for a development environment centered around Neovim, tmux, and zsh. Managed as a git repo at `~/.dotfiles` with symlinks into `$HOME`, `~/.config`, and `~/.claude/`.

## What's included

- **Neovim** - LSP, Treesitter, Copilot, lazy.nvim plugin manager
- **zsh** - Starship prompt, syntax highlighting, autosuggestions, vi mode
- **tmux** - Catppuccin theme, tmuxinator session layouts
- **WezTerm** - Terminal config with FiraCode Nerd Font
- **macOS defaults** - Sane system defaults for development use
- **Homebrew** - CLI tools and GUI apps via Brewfile
- **scripts** - Shell utilities on `$PATH` (branch naming, git helpers, etc.)

## Prerequisites

macOS with Xcode command line tools:

```bash
sudo softwareupdate -i -a
xcode-select --install
```

## Installation

```bash
git clone git@github.com:ku5ic/dotfiles.git ~/.dotfiles
source ~/.dotfiles/install.sh
```

This pulls the repo, installs Homebrew, installs zsh and bash, sets zsh as the login shell, runs `brew bundle` from the `Brewfile`, creates all symlinks, makes scripts and hooks executable, and sets up Node, Ruby, and Python via asdf.

## Updating

To re-run the full installer (pulls the repo and refreshes Homebrew packages, symlinks, permissions, and asdf runtimes):

```bash
source ~/.dotfiles/install.sh
```

To update Homebrew packages:

```bash
brew_all
```

To add or remove packages, edit the `Brewfile` and run:

```bash
brew bundle --file="$DOTFILES_DIR/Brewfile"
brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" --force
```

## Structure

See [CLAUDE.md](CLAUDE.md) for a detailed breakdown of the repository structure and Neovim architecture.
