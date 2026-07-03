# Script invocation

The `~/.claude/bin` directory is on PATH. Call every bin script by bare name, never by path.

- Correct: `project-name.sh`, `run-checks.sh`, `git-base.sh main`, `git-diff-from-base.sh src/`
- Wrong: `$HOME/.claude/bin/run-checks.sh`, `~/.claude/bin/run-checks.sh`, `./bin/run-checks.sh`, `bash run-checks.sh`

Pass arguments as plain positional args after a space (`git-base.sh main`), not glued to the name and not via a subshell. Do not wrap a script call in `bash` or `sh`; the shebang handles that.

The settings.json allow list is keyed on the bare form (`Bash(run-checks.sh)` and `Bash(git-base.sh *)`). Any pathful or wrapped invocation misses the allow entry and triggers a permission prompt. Consistency here is what keeps the allow list small: one entry per script, plus one `<name> *` entry for scripts that take args.

Inline skill injection uses the same bare form: `!`project-name.sh``, not `!`$HOME/.claude/bin/project-name.sh``.

Script-to-script calls inside the bin scripts themselves are exempt; those resolve paths internally and never pass through the allow list.
