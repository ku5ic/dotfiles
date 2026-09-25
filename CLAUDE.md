# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal macOS dotfiles managed as a git repo at `~/.dotfiles`. Files are symlinked into `$HOME`, `~/.config`, and `~/.claude/` via `install.sh`.

## Installation

```sh
source ~/.dotfiles/install.sh
```

To re-symlink a single config without running the full installer, re-run the `ln -sfv` manually:

```sh
ln -sfv ~/.dotfiles/config/nvim ~/.config/
```

## Structure

Claude Code config is split in two, both symlinked into `~/.claude/` by `claude-kit/bin/bootstrap.sh`. `claude-kit/` is the shareable plugin (`agents/`, `hooks/`, `skills/`, `rules/`, `bin/`, `_stacks.yml`, bats tests in `tests/`); `claude/` is personal (`settings.json`, `CLAUDE.md`, `rules/voice.md`, and `rules/kit` linking to the kit rules). `~/.claude/bin` is on `$PATH` via `.zprofile`. Neovim config lives in `config/nvim/`, see `config/nvim/CLAUDE.md`.

## Neovim Architecture

See `config/nvim/CLAUDE.md` for the entry point, plugin file layout, augroups, and keymap prefix conventions.

## Scripts

`scripts/` is prepended to `$PATH` in `.zprofile`. The alias loop at the bottom of `.aliases.zsh` then maps each `*.sh` file to its bare name, so e.g. `branch_name.sh` is callable as `branch_name` in every new shell session.

Branch naming via `branch_name.sh`: `<type>/<ISSUE-ID>/<slug>` or `<type>/<slug>` (no issue id). Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `release`, `poc`, `spike`, `wip`, `draft`, `temp`, `drill`, `sandbox`, `personal`, `exp`, `try`. Use `--checkout` flag to create and switch in one step. Tab-completion is registered via `completions/_branch_name.sh`.

`claude-kit/bin/git-diff-from-base.sh` diffs the current branch against its base, resolved by `git-base.sh` (upstream, then `origin/HEAD`, then main/master/develop/trunk) or a base passed as the first argument. Both are on `$PATH` via `~/.claude/bin`, so they are callable by bare name.

Machine-local shell overrides go in `~/.zshrc.local` (sourced at the end of `.zshrc`, not tracked in this repo).
