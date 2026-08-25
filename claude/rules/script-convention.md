# Script invocation

The `~/.claude/bin` directory is on PATH. Call every bin script by bare name, never by path.

- Correct: `project-name.sh`, `run-checks.sh`, `git-base.sh main`, `git-diff-from-base.sh src/`
- Wrong: `$HOME/.claude/bin/run-checks.sh`, `~/.claude/bin/run-checks.sh`, `./bin/run-checks.sh`, `bash run-checks.sh`

Pass arguments as plain positional args after a space (`git-base.sh main`), not glued to the name and not via a subshell. Do not wrap a script call in `bash` or `sh`; the shebang handles that.

settings.json grants scoped `Bash(<name>:*)` allows keyed to the bare script name, not a blanket `Bash` allow - a pathful or wrapped invocation will not match those patterns and can trigger a permission prompt. The bare-name convention also matters for `guard-bash.sh`'s `_is_safe_chain_lead`, which classifies chain safety by the leading binary name.

Inline skill injection uses the same bare form: `!`project-name.sh``, not `!`$HOME/.claude/bin/project-name.sh``.

Script-to-script calls inside the bin scripts themselves are exempt; those resolve paths internally and never pass through the allow list.
