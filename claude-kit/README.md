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
- The `Stop` hook runs file-scoped checks (eslint, jest/vitest, ruff, pyright, shellcheck, and others) on only the files the turn edited, skipped when the tree is clean, and blocks once on failure. A linter blocks only on findings on lines the tree changed against HEAD, so pre-existing ones in a touched file are reported, not blocking; type checkers and test runners still judge the whole file. The checks run in parallel, and one that runs past kit.yml's `check_timeout` (90 s) is killed and reported as a skip. A tool counts when the project configures it or declares it as a dependency; kit.yml `file_checks` adds your own. `bin/kit explain stop <file>...` shows what claims a file and the exact command, `bin/kit explain bash '<cmd>'` and `bin/kit explain edit <path>` show a guard's decision; none of them logs, blocks, or runs anything.
- Migrating an overlay: `bin_lookups`, and a `file_checks` entry's `test_script` and `needs_files`, are gone. Package-manager environments (poetry, pipenv, Yarn PnP, bundler) are built in, and `bin/kit config --check` names any key left behind. The full `bin/run-checks.sh` suite runs alongside `/code-review` because `rules/workflow.md` says to; the built-in doesn't run it.

## Develop

The code lives in `go/`: `go test ./...` runs the suite, with the end-to-end tests in `go/e2e`, and `bats tests/` covers the two bash scripts; `go/build.sh` rebuilds the committed `bin/kit-<os>-<arch>` binaries, and CI fails when they don't match the source. `bin/kit config` prints the effective kit.yml, and `--check` reports unknown keys. `bin/bootstrap.sh` and `bin/doctor.sh` serve the symlinked layout in [ku5ic/dotfiles](https://github.com/ku5ic/dotfiles) and are not needed for a plugin install.
