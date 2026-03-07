# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal macOS dotfiles managed as a git repo at `~/.dotfiles`. Files are symlinked into `$HOME` and `~/.config` via `install.sh`.

## Installation

```sh
source ~/.dotfiles/install.sh
```

This script: pulls the latest repo, installs Homebrew, installs zsh/bash shells, runs `brew bundle` from `Brewfile`, creates all symlinks, and sets up asdf for Node/Ruby/Python.

To update symlinks only (no full install):
```sh
# Run just the create_symlinks() function, or manually re-run:
ln -sfv ~/.dotfiles/config/nvim ~/.config/
```

## Structure

| Path | Purpose |
|------|---------|
| `.zshrc` / `.zprofile` / `.aliases.zsh` | Shell config — zprofile sets PATH and env vars, zshrc configures zsh options/plugins, aliases.zsh defines all aliases |
| `.tmux.conf` / `.tmuxinator/` | tmux config and tmuxinator session layouts |
| `Brewfile` | All Homebrew formulae, casks, and Mac App Store apps in one file |
| `scripts/` | Shell scripts on `$PATH` — callable by name without `.sh` extension |
| `config/nvim/` | Neovim config (lazy.nvim plugin manager, symlinked to `~/.config/nvim`) |
| `config/starship.toml` | Starship prompt config |
| `config/wezterm/` | WezTerm terminal config |
| `macos/set-defaults.sh` | macOS system defaults (run once on new machine) |
| `.tool-versions` | asdf runtime versions (Node 24, Ruby 4, Python 3) |

## Neovim Architecture

Entry point: `config/nvim/init.lua` — bootstraps lazy.nvim, sets leader to `<Space>`, then loads:
- `plugins/` — one file per plugin category (lazy.nvim auto-discovers all files)
- `config/options` — vim options
- `keymaps/keymaps` — all keymaps
- `keymaps/copilotchat` — AI-specific keymaps

**Plugin categories:**
- `lsp.lua` — Mason + nvim-lspconfig; LSP server list is the single source of truth for both Mason installation and lsp setup. Switch TypeScript LSP between `ts_ls`/`vtsls` via the `typescript_lsp` variable at the top.
- `code-completion.lua` — blink.cmp
- `copilot.lua` + `claude.lua` — GitHub Copilot and claude-code.nvim
- `editor.lua` — Telescope, Neo-tree, gitsigns, etc.
- `formatting.lua` / `linting.lua` — conform.nvim / nvim-lint
- `treesitter.lua` — syntax highlighting
- `debuggers.lua` — nvim-dap
- `ui.lua` — noice, bufferline, lualine, etc.

**Keymap prefix conventions** (leader = `<Space>`):
- `<leader>f` — Find/files (Telescope)
- `<leader>s` — Search/grep
- `<leader>g` — Git (LazyGit, gitsigns)
- `<leader>w` — Window splits
- `<leader>t` — Tabs/explorer toggle
- `<leader>b` — Buffer management
- `<leader>l` — LSP actions
- `<leader>x` — Trouble diagnostics
- `<leader>d` — DAP debugger
- `<leader>a` — AI/Copilot (see `keymaps/copilotchat.lua`)

## Scripts

`scripts/` is prepended to `$PATH` in `.zprofile`, so any `.sh` file added there is immediately callable by name (without the `.sh` extension) in every new shell session.

Branch naming follows the convention in `jira_to_git_branch.sh`: `ku5ic/<type>/<STORY-ID>/<normalized_title>` where type is `feature`, `bugfix`, or `hotfix`.

Machine-local shell overrides go in `~/.zshrc.local` (sourced at the end of `.zshrc`, not tracked in this repo).

## Key Aliases

- `dotfiles` — cd to `~/.dotfiles`
- `mux` — tmuxinator
- `lg` — lazygit
- `vim` / `vi` — nvim
- `brew_all` — full Homebrew update/upgrade/cleanup cycle
- `bat` — bat with TwoDark theme and line numbers
