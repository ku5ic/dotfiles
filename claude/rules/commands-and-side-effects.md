# Commands and side effects

Elaboration on `CLAUDE.md`'s `## Commands and Side Effects` line; most of this is mechanically enforced by guard-bash.sh / guard-edit.sh.

- Destructive operations require explicit confirmation before running: `rm`, `git reset --hard`, `git clean`, `git push --force` (never on a shared branch, see `git-workflow.md`), branch or tag deletion, database migrations, dropping tables, truncating files.
- Do not install, upgrade, or remove dependencies without asking. Include the reason and the proposed command.
- `2>&1` and other shell redirects are unnecessary (the Bash tool merges stderr by default) but no longer blocked.
- Chaining with `&&`, `||`, or `;` is allowed only when every command in the chain is read-only.
  - See `_is_safe_chain_lead` in guard-bash.sh: `ls`, `cat`, `grep`, `find`, `jq`, etc.
  - `git` is never chain-safe, even for read-only subcommands - chain-safety is classified by binary name, not subcommand.
  - A chain containing any mutating command still requires separate Bash tool calls.
  - Use native path args where available instead of `cd <dir> && cmd`; see `cli-tools.md` for the table (`git -C <dir>`, `tokei <path>`).
- Pipes (`|`) for single-operation semantics only: `cmd | grep`, `find | wc -l`, `git log | head`. Sequential checks go in separate calls.
- Do not modify project level config without asking: `.env*`, `tsconfig*.json`, `eslint.config.*`, `prettier.config.*`, `next.config.*`, `vite.config.*`, `package.json` scripts, CI workflows.
- Do not create new top level directories without asking.
- Do not run broad recursive commands (`rm -rf`, `find ... -delete`, `chmod -R`) without confirmation.
- Start narrow. Test a command on one file or one directory before scaling to the whole tree.
