---
name: bash-patterns
description: Bash and shell script patterns covering safety flags, quoting, conditionals, traps, functions, ShellCheck discipline, and review-worthy anti-patterns. Use whenever the project contains `.sh`, `.bash`, `.zsh` files (or files with bash/sh shebangs), scripts in `bin/`, dotfiles like `.zshrc`/`.bashrc`/`.zprofile`, Makefile recipes, OR the user asks about bash, shell, scripts, or any shell-pipeline work, even if "bash" is not mentioned by name.
---

# Bash patterns

Default assumption: bash 5.x targeting macOS (via Homebrew bash) and Linux. Scripts use `#!/usr/bin/env bash` so the resolved binary is whatever is first on PATH, which on the user's machine is the Homebrew 5.x build, not the stock macOS `/bin/bash` 3.2. Anything that requires bash 4.0+ (case modification, `mapfile`, `${parameter@op}`) is unsafe under stock macOS bash and is flagged here when the version cut matters.

## Script preamble

Every non-trivial script starts with:

```sh
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e` exits on a simple-command non-zero status. It does not exit when the failure is in the test of an `if`/`elif`, in the head of `while`/`until`, in `&&`/`||` chains except after the final operator, in any pipeline command but the last (subject to `pipefail`), or with a leading `!`. A trap on `ERR` runs under the same conditions.
- `set -u` errors on parameter expansion of an unset variable. `$@` and `$*` (and array `[@]`/`[*]` subscripts) are exempt by design, so iterating `"$@"` over zero positional args is safe.
- `set -o pipefail` makes a pipeline's exit status the rightmost non-zero, instead of just the last command's status. Without it, `cmd_a | cmd_b` succeeds whenever `cmd_b` succeeds, even if `cmd_a` failed.
- `IFS=$'\n\t'` removes space as a field separator. Default IFS is space-tab-newline; dropping space prevents accidental word splitting on filenames-with-spaces. `$'...'` is ANSI-C quoting, supported in bash since 2.x.

`#!/usr/bin/env bash` over `#!/bin/bash`. The env form picks up Homebrew bash on macOS so 4.0+ features work; the absolute path is locked to whatever ships in `/bin`. Use the absolute form only when the script must run before PATH is set up (early init scripts, recovery shells).

## Quoting

The single highest-impact section. Most shell bugs are quoting bugs.

- Quote every variable expansion: `"$var"`, never bare `$var`. Unquoted expansions undergo word splitting on IFS and pathname expansion (globbing).
- Quote command substitutions: `cmd "$(other_cmd)"`. Same reason.
- Single quotes preserve every character literal; double quotes preserve everything except `$`, backticks, `\`, and `!`.
- Heredocs: `<<'EOF'` (any quoting on the delimiter) disables expansion; `<<EOF` allows parameter, command, and arithmetic expansion. Use `<<-EOF` to strip leading tabs (tabs only, not spaces).
- ANSI-C quoting `$'\n'`, `$'\t'`, `$'\x1b'` for escape characters in literals.
- Array expansions: `"${array[@]}"` expands each element to a separate word; `"${array[*]}"` joins with the first character of `IFS`. `[@]` is almost always what you want.

## Conditionals and tests

- `[[ ... ]]` over `[ ... ]` in bash scripts. `[[` does NOT word-split or pathname-expand its operands, so `[[ $var = pattern ]]` is safe even unquoted on the left side. `[ ]` is the POSIX `test` builtin and does both, so unquoted operands are bugs.
- Inside `[[ ]]`: `==` and `=` are equivalent. `==` reads better. The right side of `==`/`!=` is treated as a glob pattern unless it is quoted: `[[ "$x" == *.log ]]` matches; `[[ "$x" == "*.log" ]]` is a literal-string compare.
- Numeric comparison inside `[[ ]]`: `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge`. Do NOT use `==` for numbers; that is a string compare and `[[ 01 == 1 ]]` is false.
- `(( expression ))` for arithmetic. Returns 0 if non-zero, 1 if zero, which inverts the natural reading; remember `(( count == 0 ))` returns 1 (false in shell, true in C).
- `case "$x" in pattern) cmd ;; esac` for multi-branch dispatch. Patterns use the same glob syntax as pathname expansion.
- `&&` and `||` for terse one-liners. Avoid for multi-statement flow; reach for `if/then/else`.

## Functions and locals

- `name() { ... }` is the POSIX form; `function name { ... }` is bash-specific. Use `name() { ... }` unless there is a reason not to.
- Every variable inside a function gets `local`. Without it, the assignment writes to the caller's scope or to global, which is a major footgun.
- `readonly` for constants set at script load.
- Functions return integer status codes (0 success, non-zero failure). `return N` exits the function; `exit N` exits the script.
- Stdout for data, stderr for human messages: `echo "result"`, `echo "error: ..." >&2`. Tests pipe stdout; logs pipe stderr.
- `local foo=$(cmd)` masks `cmd`'s exit status (the `local` builtin's success is what survives). Split into `local foo; foo=$(cmd)` when the exit status matters. ShellCheck flags this as SC2155.

## Traps and cleanup

- `trap 'cleanup' EXIT` runs `cleanup` whenever the shell exits, error or not. Use this for tempdir removal.
- `trap 'echo interrupted >&2; exit 130' INT TERM` for graceful shutdown. 130 is `128 + 2` (SIGINT signal number), the conventional exit code.
- `trap '...' ERR` runs only on non-zero exit, with the same edge-case list as `set -e`. Less reliable than `EXIT` for cleanup.
- Combined: `trap 'rc=$?; cleanup; exit $rc' EXIT` preserves the original exit code through the cleanup.
- Cleanup functions: idempotent and defensive. `rm -f`, not `rm`. `kill -0 "$pid" 2>/dev/null && kill "$pid"`, not bare `kill`.

## Parameter expansion

All forms below are bash-standard; the case-modification family is bash 4.0+.

- `${var:-default}` returns `default` if `var` is unset or empty; does not assign.
- `${var:=default}` assigns `default` to `var` if unset or empty, then expands.
- `${var:?error}` writes `error` to stderr and exits non-interactive shells if `var` is unset or empty. Useful at the top of a script to assert required env vars.
- `${var:+alt}` returns `alt` if `var` is set and non-empty, otherwise nothing.
- `${var#prefix}` / `${var##prefix}`: remove shortest / longest matching prefix.
- `${var%suffix}` / `${var%%suffix}`: remove shortest / longest matching suffix.
- `${var/pattern/replacement}` first match; `${var//pattern/replacement}` all matches.
- `${var^^}` uppercase, `${var,,}` lowercase. Bash 4.0+; unsafe under stock macOS bash 3.2.

## Subshells, pipes, process substitution

- `$(cmd)` is the modern command substitution form. Backticks still work; they are harder to nest and harder to read. Stay with `$(...)`.
- The right side of `|` runs in a subshell. Variable assignments inside `cmd | while read -r line; do count=$((count+1)); done` do not survive the loop. Replace with `while read -r line; do ...; done < file` (input redirection) or `while read -r line; do ...; done < <(cmd)` (process substitution, same effect with arbitrary commands).
- Process substitution `<(cmd)` produces a path the consumer reads from; bash, ksh, zsh only, not POSIX.
- Useless `cat`: `cat file | grep ...` spawns an extra process. Use `grep ... file` or `< file grep ...`.

## Filesystem operations

- `mktemp -d` for temp directories; `-d` is portable on BSD (macOS) and GNU. Pair with `trap` cleanup.
- `cd "$dir" || exit 1` to fail fast. Bare `cd` continues silently in the wrong directory if the path is missing or unreadable. ShellCheck flags this as SC2164.
- `(cd "$dir" && cmd)` keeps the `cd` scoped to a subshell when the surrounding script must stay in its original cwd.
- Filenames with spaces or newlines: `find ... -print0 | xargs -0 cmd`. Both `-print0` and `-0` exist on BSD (macOS) and GNU. The `for f in $(find ...)` pattern is broken on any non-trivial input.
- `realpath path` and `readlink -f path` are both available on modern macOS (13+) and Linux. Flag sets differ between BSD and GNU implementations; the no-flag `realpath path` form is the safest portable spelling.

## printf over echo

`echo`'s handling of `-e`, `-n`, and embedded backslashes varies across shells and even across bash versions. `printf '%s\n' "$str"` is portable and predictable. Reach for `echo` only for trivial constant strings where none of those edge cases apply.

## ShellCheck discipline

ShellCheck catches most quoting and word-splitting bugs statically. Run it on every committed script. Codes worth knowing:

- `SC2086` -- "Double quote to prevent globbing and word splitting." The unquoted-expansion finding. Almost always a real bug; fix it, do not silence it.
- `SC2155` -- "Declare and assign separately to avoid masking return values." `local`/`export`/`readonly` with a command substitution on the same line drops the command's exit status. Split the declaration.
- `SC2046` -- "Quote this to prevent word splitting." Unquoted command substitution on the right of an assignment or in argument position.
- `SC2164` -- "Use `cd ... || exit` in case `cd` fails." Bare `cd` without an exit-on-failure guard.

Suppression: `# shellcheck disable=SCXXXX` on the line above the offending line, with a comment explaining why. Do not blanket-disable at file top; that hides real findings. The default answer to a ShellCheck warning is to fix it.

## Anti-patterns to flag

- Parsing `ls`: `for f in $(ls)`. Breaks on filenames with spaces, newlines, or glob characters. `failure`. Use `for f in *` (with `shopt -s nullglob` to handle empty globs) or `find ... -print0 | xargs -0`.
- `for f in $(find ...)`: same word-splitting hazard. `failure`. Use `find -print0 | xargs -0` or `while IFS= read -r -d '' f; do ...; done < <(find ... -print0)`.
- Useless `cat`: `cat file | grep ...`. `warning`.
- `cmd | while read line; do var=...; done` then reading `var` outside the loop. Pipe creates a subshell; assignment is lost. `failure`. Use input redirection or process substitution.
- Unquoted expansions: `[ $var = "yes" ]`. `failure`. With unset or empty `$var` this becomes `[ = "yes" ]`, a syntax error. Quote it, or use `[[ ]]`.
- Missing `set -euo pipefail` in non-trivial scripts. `warning`. Failure modes are silent.
- Hardcoded `/tmp/<name>`: predictable, racy, and not cleaned up. `warning`. `mktemp -d` plus a trap.
- `rm -rf "$VAR/"` without verifying `$VAR` is non-empty. `failure`. Empty `$VAR` deletes `/`. Guard with `[[ -n "$VAR" ]]` or use `${VAR:?}` to error out on empty.
- Functions without `local`. `warning`. Caller scope leaks; remote-debug nightmare.
- `eval` on user input. `failure` unless every component is provably safe; even then, prefer arrays of arguments and avoid `eval` entirely.
- `cd "$dir"` without `|| exit` or subshell wrap. `warning`. SC2164.
- `<<EOF` when the heredoc body should be literal (paths, regex, code samples). `warning`. Use `<<'EOF'`.
- `read` without `-r`. `warning`. The default mangles backslashes and treats `\<newline>` as line continuation.
- `[[ "$x" == "yes" ]] && do_thing || do_other_thing`. `warning`. The `||` runs if `do_thing` itself fails, not just if the condition is false. Use `if/then/else`.
- Globs without `nullglob`: `for f in *.log` runs once with the literal string `*.log` if no files match. `warning`. `shopt -s nullglob` at the top, or guard inside: `[[ -e "$f" ]] || continue`.

## Verification before shipping

Non-obvious shell -- case-pattern globs, regex, IFS games, complex parameter expansion, here-doc quoting -- gets a quick test in `bash` before commit. A 30-second `bash -c '...'` run beats multiple debug rounds. ShellCheck is a static analyzer; runtime behavior with real inputs is the final check.

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
- Greg's BashFAQ: https://mywiki.wooledge.org/BashFAQ
- Greg's BashGuide: https://mywiki.wooledge.org/BashGuide

When bash evolves -- 6.x or beyond -- reconcile this skill against the manual before trusting deltas above. The 4.0+ feature cuts (case modification, `mapfile`, `${parameter@op}`) are the main version-sensitive items today; once stock macOS ships a bash 4+ default, those notes can come out.
