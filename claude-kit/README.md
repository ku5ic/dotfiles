# claude-kit

A Claude Code plugin: deterministic guard hooks, stack-aware context, a read-only investigation skill, `/audit` and `/write`, 22 stack pattern skills, and review agents. It leans on built-ins (`/plan`, `/code-review`, `/security-review`, Explore) and only adds what Claude Code lacks.

## Install

```sh
claude plugin marketplace add ku5ic/dotfiles
claude plugin install claude-kit@ku5ic
~/.claude/plugins/marketplaces/ku5ic/claude-kit/install-rules.sh
```

The last step links the always-on rules into `~/.claude/rules/claude-kit`; plugins cannot ship rules. Start from `templates/CLAUDE.md` for your own `~/.claude/CLAUDE.md`.

Requires `git` and bash (any version, the stock macOS 3.2 included): every hook and helper runs in one prebuilt Go binary, `bin/kit-<os>-<arch>` (darwin and linux, arm64 and amd64), behind same-name bash shims. `bin/doctor.sh` and `bin/bootstrap.sh`, which maintain the symlinked dotfiles layout, also need bash 4.4+, `jq`, and mikefarah `yq`. Formatters and linters (`prettier`, `shfmt`, `shellcheck`, `stylua`, `gitleaks`) are used when installed and skipped when not.

## What you get

| Part                      | What it does                                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `hooks/`                  | Block risky shell and commit patterns, sanitize and format edited files, inject repo context, run checks on `Stop` |
| `skills/investigate`      | Read-only answer to a question or symptom; loads on its own, and in plan mode its findings feed the plan           |
| `skills/audit`            | `/audit a11y\|debt\|doc-drift\|perf\|verify`                                                                       |
| `skills/write`            | `/write commit\|pr\|release-notes\|devnote\|explainer\|review-comment\|review-reply\|stakeholder`                  |
| `skills/*-patterns`       | Stack knowledge packs, suggested per repo by `kit.yml`                                                             |
| `agents/`                 | `auditor`, `checker`, `debugger`, `plan-critic`, `researcher`, `tester`                                            |
| `rules/`                  | Output, evidence, change, workflow, tooling, and agent rules                                                       |
| `bin/`                    | Helpers on PATH: `run-checks.sh`, `scratch-dir.sh`, `git-base.sh`, and others                                      |

## Options

- `CLAUDE_GUARD_SKILLS=1` in your settings `env` blocks the first edit of a mapped file type until its pattern skill is loaded. Off by default.
- `CLAUDE_SANITIZE_TYPOGRAPHY=1` in your settings `env` makes the sanitizer rewrite em dashes, smart quotes, ellipses, and Unicode arrows in edited files to ASCII. Off by default; bidi control characters are always stripped.
- The `Stop` hook runs kit.yml's `file_checks` on only the files the turn edited, skipped when the tree is clean, and blocks once on failure. The full `bin/run-checks.sh` suite runs alongside `/code-review` because `rules/workflow.md` says to; the built-in doesn't run it.

## Develop

`bats tests/` runs the suite. The Go port lives in `go/` (`go test ./...`); `go/build.sh` rebuilds the committed `bin/kit-<os>-<arch>` binaries, and CI fails when they don't match the source. `bin/kit config` prints the effective kit.yml, and `--check` reports unknown keys. `bin/bootstrap.sh` and `bin/doctor.sh` serve the symlinked layout in [ku5ic/dotfiles](https://github.com/ku5ic/dotfiles) and are not needed for a plugin install.
