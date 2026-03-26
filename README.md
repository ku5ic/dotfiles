# ku5ic's Dotfiles

Personal macOS dotfiles for a development environment centered around
Neovim, tmux, and zsh. Managed as a git repo at `~/.dotfiles` with
symlinks into `$HOME` and `~/.config`.

## What's included

- **Neovim** — LSP, Treesitter, Copilot, lazy.nvim plugin manager
- **zsh** — Starship prompt, syntax highlighting, autosuggestions, vi mode
- **tmux** — Catppuccin theme, tmuxinator session layouts
- **WezTerm** — Terminal config with FiraCode Nerd Font
- **macOS defaults** — Sane system defaults for development use
- **Homebrew** — CLI tools and GUI apps via Brewfile
- **scripts** — Shell utilities on `$PATH` (branch naming, git helpers, etc.)

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

This will install Homebrew, set zsh as the default shell, install all
packages from the Brewfile, create symlinks, and set up Node, Ruby,
and Python via asdf.

## Updating

To pull latest changes and re-apply symlinks:

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

See [CLAUDE.md](CLAUDE.md) for a detailed breakdown of the repository
structure and Neovim architecture.
