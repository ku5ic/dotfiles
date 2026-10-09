# ku5ic's Dotfiles

My macOS dev setup as code. One command turns a fresh Mac into it: shell, editor, terminal, apps, language runtimes, and a guarded Claude Code.

## What this is

A git repo that lives at `~/.dotfiles` and gets symlinked into `$HOME`, `~/.config`, and `~/.claude`. The configs you edit in place are the ones in the repo, so every change is a diff.

It's macOS only, and built around how I work: Neovim in tmux inside WezTerm, zsh in vi mode, and Claude Code as a daily tool.

## Why it exists

Setting up a new Mac by hand takes a day and never comes out the same twice. Configs drift between machines, and the tweak you made six months ago is gone, along with the reason you made it.

This repo fixes that:

- **Reproducible machines.** A new or wiped Mac is one install away from the same setup.
- **Configs with history.** Every tweak is a commit, so `git log` tells you when and why something changed, and `git revert` undoes it.
- **One place to change things.** Edit it once, pull on the other machine, done.

It's not a framework. There are no modules to toggle and no abstraction over what the tools already do. It's one person's setup, kept tidy.

## Opinionated, personal, and free to fork

Every choice in here is mine: Catppuccin everywhere, vi keys everywhere, asdf for runtimes, WezTerm over iTerm, Neovim over anything else. Some of them won't suit you, and that's fine.

It's MIT licensed. Fork it, rip out what you don't want, and make it yours. I'm not taking PRs that change the taste, but issues for real bugs are welcome.

Before you run it on your own machine, change these, or you'll end up committing as me:

- **Git identity**: `name`, `email`, and `signingkey` in `.gitconfig`.
- **Apps**: prune the `Brewfile`. It installs everything I use, including Mac App Store apps.
- **Claude Code**: `claude/` holds my personal settings and rules. Keep, edit, or drop them.
- **Location**: `install.sh` assumes the repo lives at `~/.dotfiles`.
- **Clone URL**: use your fork's URL, over HTTPS if you don't have a GitHub SSH key set up yet.

## What you get

| Area          | What's in it                                                          |
| ------------- | --------------------------------------------------------------------- |
| Editor        | Neovim with LSP, Treesitter, Copilot, lazy.nvim                       |
| Shell         | zsh, Starship prompt, autosuggestions, syntax highlighting, vi mode   |
| Terminal      | WezTerm with FiraCode Nerd Font, tmux with Catppuccin and tmuxinator  |
| Apps and CLIs | Everything in the `Brewfile`, installed via Homebrew                  |
| Runtimes      | Node, Ruby, Python, and Go via asdf, pinned in `.tool-versions`       |
| Scripts       | Helpers on `$PATH`: branch naming, tmux session picker, git utilities |
| Claude Code   | claude-kit guardrails, see below                                      |

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

No SSH key yet, or installing a fork? Clone over HTTPS instead:

```bash
git clone https://github.com/<you>/dotfiles.git ~/.dotfiles
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

| To                          | Run                                                                 |
| --------------------------- | ------------------------------------------------------------------- |
| Pull and refresh everything | `~/.dotfiles/install.sh`                                            |
| Upgrade Homebrew packages   | `brew_all`                                                          |
| Add or remove an app        | edit `Brewfile`, then `brew bundle --file="$DOTFILES_DIR/Brewfile"` |
| Drop apps no longer listed  | `brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" --force`       |
| Re-link one config          | `ln -sfv ~/.dotfiles/config/nvim ~/.config/`                        |

## Layout

| Path                         | Holds                                                 |
| ---------------------------- | ----------------------------------------------------- |
| `config/`                    | Neovim, WezTerm, Starship, git                        |
| `claude/`                    | My personal Claude Code settings on top of claude-kit |
| `scripts/`                   | Shell helpers, each callable by its bare name         |
| `completions/`               | zsh tab-completion for the scripts                    |
| `tests/`                     | bats tests for the scripts                            |
| `macos/`                     | System defaults script                                |
| `launchd/`                   | Background jobs                                       |
| `.tmuxinator/`               | tmux session layouts                                  |
| `.github/workflows/lint.yml` | CI: shellcheck and bats tests                         |
| `Brewfile`                   | Every Homebrew package and app                        |
| `install.sh`                 | The installer                                         |

## License

[MIT](LICENSE).
