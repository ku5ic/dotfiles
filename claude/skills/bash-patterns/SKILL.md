---
name: bash-patterns
description: Bash and shell script patterns covering safety flags, quoting, conditionals, traps, functions, ShellCheck discipline, and review-worthy anti-patterns. Use whenever the project contains `.sh`, `.bash`, `.zsh` files (or files with bash/sh shebangs), scripts in `bin/`, dotfiles like `.zshrc`/`.bashrc`/`.zprofile`, Makefile recipes, OR the user asks about bash, shell, scripts, or any shell-pipeline work, even if "bash" is not mentioned by name.
---

# Bash patterns

Default assumption: bash 5.x targeting macOS (via Homebrew bash) and Linux. Scripts use `#!/usr/bin/env bash` so the resolved binary is whatever is first on PATH, which on the user's machine is the Homebrew 5.x build, not the stock macOS `/bin/bash` 3.2. Anything that requires bash 4.0+ (case modification, `mapfile`, `${parameter@op}`) is unsafe under stock macOS bash and is flagged here when the version cut matters.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                                 | Covers                                                                                                       |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [reference/safety-flags.md](reference/safety-flags.md)               | Script preamble, `set -euo pipefail` edge cases, `inherit_errexit`, `nullglob`, verification before shipping |
| [reference/quoting.md](reference/quoting.md)                         | Quoting rules, nested quoting, heredoc indentation, `printf` over `echo`, zsh-vs-bash differences            |
| [reference/conditionals.md](reference/conditionals.md)               | `[[ ]]` over `[ ]`, glob vs literal, numeric vs string comparison, `(( ))`, `case`                           |
| [reference/functions-and-traps.md](reference/functions-and-traps.md) | Functions and locals, `trap` patterns, `BASH_LINENO` / `BASH_SOURCE` / `caller` debug introspection          |
| [reference/parameter-expansion.md](reference/parameter-expansion.md) | `${var:-}`, `${var:?}`, prefix/suffix removal, pattern substitution, case modification                       |
| [reference/subshells-and-pipes.md](reference/subshells-and-pipes.md) | Subshell semantics, `\|` pitfalls, process substitution `<(cmd)`, filesystem operations                      |
| [reference/shellcheck.md](reference/shellcheck.md)                   | Top SC codes, suppression discipline, POSIX-only contexts (Alpine, BusyBox)                                  |
| [reference/anti-patterns.md](reference/anti-patterns.md)             | Fifteen review-time anti-patterns with severity calls                                                        |

## When to load this skill

- `.sh`, `.bash`, `.zsh` files; or any file with a bash/sh shebang.
- Editing dotfiles like `.zshrc`, `.bashrc`, `.zprofile`, `.aliases.zsh`.
- CI workflow shell steps (GitHub Actions `run:` blocks, GitLab `script:`, etc.).
- Makefile recipes. GNU Make defaults to `/bin/sh`; set `SHELL := /bin/bash` at the top of the Makefile if recipes use bash features.
- Reviewing scripts in `~/.dotfiles/scripts/` and `~/.dotfiles/claude/bin/`.

## When not to load this skill

- One-off command-line invocations in conversation (single pipelines, ad-hoc `find` commands).
- Pure POSIX `sh` (`#!/bin/sh`) where bashisms would be wrong; note the constraint and switch to POSIX-only forms.
- Fish or other non-POSIX shells.
- zsh-specific features beyond what bash shares.

## References

- GNU Bash manual: https://www.gnu.org/software/bash/manual/bash.html
- POSIX shell command language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- ShellCheck wiki: https://www.shellcheck.net/wiki/
- BashFAQ: https://mywiki.wooledge.org/BashFAQ
- BashPitfalls: https://mywiki.wooledge.org/BashPitfalls
- BashGuide: https://mywiki.wooledge.org/BashGuide
- Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html

## Maintenance note

When bash evolves -- 6.x or beyond -- reconcile this skill against the manual before trusting deltas above. The 4.0+ feature cuts (case modification, `mapfile`, `${parameter@op}`) are the main version-sensitive items today; once stock macOS ships a bash 4+ default, those notes can come out.
