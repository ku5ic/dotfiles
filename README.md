# ku5ic's Dotfiles

One command turns a fresh Mac into my full dev setup: shell, editor, terminal, apps, language runtimes, and a guarded Claude Code.

## The problem

Setting up a new Mac by hand takes a day and never comes out the same twice. Configs drift between machines, and the tweak you made six months ago is gone.

This repo fixes that. Every config lives here, under git, and gets symlinked into place. Change it once, and every machine picks it up on the next pull.

## What you get

| Area             | What's in it                                                          |
| ---------------- | --------------------------------------------------------------------- |
| Editor           | Neovim with LSP, Treesitter, Copilot, lazy.nvim                       |
| Shell            | zsh, Starship prompt, autosuggestions, syntax highlighting, vi mode   |
| Terminal         | WezTerm with FiraCode Nerd Font, tmux with Catppuccin and tmuxinator  |
| Apps and CLIs    | Everything in the `Brewfile`, installed via Homebrew                  |
| Runtimes         | Node, Ruby, Python, and Go via asdf, pinned in `.tool-versions`       |
| Window handling  | Hammerspoon, focus follows the cursor                                 |
| Scripts          | Helpers on `$PATH`: branch naming, tmux session picker, git utilities |
| Claude Code      | claude-kit guardrails, see below                                      |

## claude-kit

Guardrails for Claude Code. It blocks dangerous commands like `rm -rf ~` or a force push to main, keeps Claude out of `.env` and SSH keys, and won't let it say "done" while a linter or test is still failing.

It lives in its own repo, [ku5ic/claude-kit](https://github.com/ku5ic/claude-kit), as a Claude Code plugin that works without the rest of these dotfiles. `install.sh` installs it.

## Install

Needs macOS with the Xcode command line tools:

```bash
xcode-select --install
```

Then:

```bash
git clone git@github.com:ku5ic/dotfiles.git ~/.dotfiles
source ~/.dotfiles/install.sh
```

The installer is safe to re-run. In order, it:

1. pulls the latest repo
2. installs Homebrew, then zsh and bash, and makes zsh your login shell
3. runs `brew bundle` from the `Brewfile`
4. symlinks every config into `$HOME` and `~/.config`
5. sets up Claude Code with claude-kit
6. installs launchd agents
7. installs the asdf runtimes

macOS system defaults are opt-in. Run them yourself:

```bash
~/.dotfiles/macos/set-defaults.sh
```

## Keeping it current

| To                              | Run                                            |
| ------------------------------- | ---------------------------------------------- |
| Pull and refresh everything     | `~/.dotfiles/install.sh`                       |
| Upgrade Homebrew packages       | `brew_all`                                     |
| Add or remove an app            | edit `Brewfile`, then `brew bundle --file="$DOTFILES_DIR/Brewfile"` |
| Drop apps no longer listed      | `brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" --force` |
| Re-link one config              | `ln -sfv ~/.dotfiles/config/nvim ~/.config/`   |

## Layout

| Path             | Holds                                          |
| ---------------- | ---------------------------------------------- |
| `config/`        | Neovim, WezTerm, Starship, git                 |
| `claude/`        | My personal Claude Code settings on top of it  |
| `scripts/`       | Shell helpers, each callable by its bare name  |
| `macos/`         | System defaults script                         |
| `launchd/`       | Background jobs                                |
| `Brewfile`       | Every Homebrew package and app                 |
| `install.sh`     | The installer                                  |
