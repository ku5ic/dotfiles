# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal macOS dotfiles managed as a git repo at `~/.dotfiles`. Files are symlinked into `$HOME`, `~/.config`, and `~/.claude/` via `install.sh`.

## Installation

```sh
source ~/.dotfiles/install.sh
```

This script: pulls the latest repo, installs Homebrew, installs zsh/bash shells, sets zsh as the login shell, runs `brew bundle` from `Brewfile`, creates all symlinks, makes scripts and hooks executable, and sets up asdf for Node/Ruby/Python.

To re-symlink a single config without running the full installer, re-run the `ln -sfv` manually:

```sh
ln -sfv ~/.dotfiles/config/nvim ~/.config/
```

## Structure

| Path                                    | Purpose                                                                                                                                                       |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.zshrc` / `.zprofile` / `.aliases.zsh` | Shell config - zprofile sets PATH and env vars, zshrc configures zsh options/plugins, aliases.zsh defines all aliases                                         |
| `.tmux.conf` / `.tmuxinator/`           | tmux config and tmuxinator session layouts                                                                                                                    |
| `Brewfile`                              | All Homebrew formulae, casks, and Mac App Store apps in one file                                                                                              |
| `scripts/`                              | Shell scripts on `$PATH`; callable by bare name via aliases generated in `.aliases.zsh`                                                                       |
| `completions/`                          | zsh completion functions (e.g. `_branch_name.sh` for `branch_name`)                                                                                           |
| `config/nvim/`                          | Neovim config (lazy.nvim plugin manager, symlinked to `~/.config/nvim`)                                                                                       |
| `config/starship.toml`                  | Starship prompt config                                                                                                                                        |
| `config/wezterm/`                       | WezTerm terminal config                                                                                                                                       |
| `macos/set-defaults.sh`                 | macOS system defaults (run once on new machine)                                                                                                               |
| `.tool-versions`                        | asdf runtime versions (Node 24, Ruby 4, Python 3)                                                                                                             |
| `claude/`                               | Claude Code config (`settings.json`, `CLAUDE.md`, `commands/`, `hooks/`, `skills/`, `bin/`) symlinked into `~/.claude/`; `bin/` is on `$PATH` via `.zprofile` |

## Neovim Architecture

Entry point: `config/nvim/init.lua` - bootstraps lazy.nvim, sets leader to `<Space>`, loads `config.options` first (so plugins can read final option state), then `lazy.setup("plugins")`, then keymap modules.

Top-level layout under `config/nvim/lua/`:

- `plugins/` - one file per plugin category, auto-discovered by lazy.nvim (top-level files only; subdirectories without `init.lua` are not treated as specs)
- `config/options.lua` - vim options
- `config/icons.lua` - icon set used by lualine, bufferline, diagnostics
- `config/filetypes.lua` - filetype constants (`JS`, `TS`, `JS_TS`, `JS_REACT`, `CSS`, `WEB`) consumed by formatting, linting, and LSP filetype lists
- `lsp/servers/` - per-server LSP settings, one file per server. Adding a server is dropping a file here; `plugins/lsp.lua` discovers them at startup via `readdir` and feeds Mason
- `keymaps/keymaps.lua` - global / built-in / cmd-form keymaps (window, tab, buffer, telescope, git, LSP, Trouble, copy paths, Neovide). Plugin-specific keymaps live with their plugin spec via lazy `keys = {...}`
- `keymaps/copilotchat.lua` - AI keymaps
- `utils/copilotchat.lua`, `utils/copilotchat/prompts.lua` - CopilotChat helpers and prompt templates

**Plugin categories:**

- `lsp.lua` - Mason + nvim-lspconfig; LSP server list is built dynamically from `lua/lsp/servers/`. Switch TypeScript LSP between `ts_ls`/`vtsls` via the `typescript_lsp` variable at the top; the inactive one is filtered out of the discovered list.
- `code-completion.lua` - blink.cmp
- `copilot.lua` - GitHub Copilot and CopilotChat.nvim
- `coding.lua` - vim-surround, Comment.nvim, nvim-autopairs, vim-rbenv
- `editor.lua` - Telescope, Neo-tree, gitsigns, which-key (with group labels for every `<leader>` prefix), etc.
- `formatting.lua` / `linting.lua` - conform.nvim / nvim-lint; both consume `config.filetypes` for JS/TS filetype lists
- `treesitter.lua` - syntax highlighting
- `debuggers.lua` - nvim-dap (all DAP keymaps colocated here via lazy `keys`)
- `ui.lua` - noice, bufferline, lualine, nvim-notify, dressing

**Augroups:**

All custom autocmds belong to a `dotfiles_*` augroup created with `clear = true`, so `:source $MYVIMRC` does not duplicate registrations: `dotfiles_autoreload` (FocusGained/BufEnter checktime), `dotfiles_lsp_attach`, `dotfiles_lsp_codelens`, `dotfiles_treesitter_highlight`.

**Keymap prefix conventions** (leader = `<Space>`):

- `<leader>f` - Find/files (Telescope)
- `<leader>s` - Search/grep (Telescope, Spectre, todo-comments)
- `<leader>g` - Git (LazyGit, Telescope, fugitive blame, gitsigns)
- `<leader>w` - Window splits
- `<leader>t` - Tabs/explorer toggle
- `<leader>b` - Buffer management
- `<leader>l` - LSP actions
- `<leader>x` - Trouble diagnostics
- `<leader>d` - DAP debugger (also F5/F10/F11/F12)
- `<leader>a` - AI/Copilot (see `keymaps/copilotchat.lua`)
- `<leader>n` - Notifications/UI (notify, noice, precognition)
- `<leader>c` - Copy file path

## Scripts

`scripts/` is prepended to `$PATH` in `.zprofile`. The alias loop at the bottom of `.aliases.zsh` then maps each `*.sh` file to its bare name, so e.g. `branch_name.sh` is callable as `branch_name` in every new shell session.

Branch naming via `branch_name.sh`: `<type>/<ISSUE-ID>/<slug>` or `<type>/<slug>` (no issue id). Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `release`. Use `--checkout` flag to create and switch in one step. Tab-completion is registered via `completions/_branch_name.sh`.

`git_diff_base.sh` diffs the current branch against main/master (auto-detected) or a specified base branch.

Machine-local shell overrides go in `~/.zshrc.local` (sourced at the end of `.zshrc`, not tracked in this repo).

## Key Aliases

- `dotfiles` - cd to `~/.dotfiles`
- `mux` - tmuxinator
- `lg` - lazygit
- `vim` / `vi` - nvim
- `brew_all` - full Homebrew update/upgrade/cleanup cycle
- `bat` - bat with TwoDark theme and line numbers
