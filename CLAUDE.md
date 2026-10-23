# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal macOS dotfiles managed as a git repo at `~/.dotfiles`. Files are symlinked into `$HOME`, `~/.config`, and `~/.claude/` via `install.sh`. Top-level folders are named for where they land: `home/` -> `$HOME` without the leading dot (`home/zshrc` -> `~/.zshrc`), `config/` -> `~/.config`, `claude/` -> `~/.claude`. Anything that reads from `~/.config` goes in `config/`, not `home/`. `config/tmux/tmux.conf` pins `TMUX_PLUGIN_MANAGER_PATH` to `~/.tmux/plugins`, or tpm would clone plugins into the repo. Dotfiles left at the repo root (`.gitignore`, `.github`, `.shellcheckrc`) configure the repo itself.

## Installation

```sh
source ~/.dotfiles/install.sh
```

Pass stage names to run only those, e.g. `~/.dotfiles/install.sh create_symlinks setup_claude`; an unknown name prints the full list.

To re-symlink a single config without running the full installer, re-run the `ln -sfv` manually:

```sh
ln -sfv ~/.dotfiles/config/nvim ~/.config/
```

## Structure

Claude Code config is split in two. The shareable kit is the `kit@ku5ic` plugin from [ku5ic/claude-kit](https://github.com/ku5ic/claude-kit); its marketplace clone at `~/.claude/plugins/marketplaces/ku5ic/` supplies the rules (linked as `claude/rules/claude-kit`, gitignored) and the `bin/` scripts, which `home/zprofile` puts on `$PATH`. `claude/` is personal (`settings.json`, `CLAUDE.md`, `rules/voice.md`, `skills/`, `claude-kit.local.yml`), linked into `~/.claude/` by `install.sh`. Kit changes go to the kit repo (clone at `~/Projects/claude-kit`), not here. `claude/desktop.md` holds the Claude desktop instructions, pasted in by hand; its section 11 names the rule files it mirrors. Neovim config lives in `config/nvim/`, see `config/nvim/CLAUDE.md`.

## Neovim Architecture

See `config/nvim/CLAUDE.md` for the entry point, plugin file layout, augroups, and keymap prefix conventions.

## Scripts

`scripts/` is prepended to `$PATH` in `home/zprofile`. The alias loop at the bottom of `home/aliases.zsh` then maps each `*.sh` file to its bare name, so e.g. `branch_name.sh` is callable as `branch_name` in every new shell session.

Branch naming via `branch_name.sh`: `<type>/<ISSUE-ID>/<slug>` or `<type>/<slug>` (no issue id). Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `release`, `poc`, `spike`, `wip`, `draft`, `temp`, `drill`, `sandbox`, `personal`, `exp`, `try`. Use `--checkout` flag to create and switch in one step. Tab-completion is registered via `completions/_branch_name.sh`.

The kit's `git-base.sh` prints the current branch's base (upstream, then `origin/HEAD`, then main/master/develop/trunk, or a base passed as an argument); `--diff` and `--log` print the diff and log against it. It is on `$PATH` via the marketplace clone's `bin/`, so it is callable by bare name.

Machine-local shell overrides go in `~/.zshrc.local` (sourced at the end of `home/zshrc`, not tracked in this repo).
