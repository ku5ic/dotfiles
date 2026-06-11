# Token discipline

- Prefer `rg` and `grep` over `Read` when locating, not understanding. Read only the matched section.
- Cap `git log` to `-20` unless a wider window is justified.
- Do not `cat` files larger than 500 lines without a specific reason. Use line ranges.
- Do not re-read a file in the same session unless an edit has changed it.
- Skip these directories for any glob, grep, or read: `node_modules/**`, `.next/**`, `dist/**`, `build/**`, `coverage/**`, `.turbo/**`, `.cache/**`, `vendor/**`, `target/**`, `out/**`, `storybook-static/**`, `.pnpm-store/**`, `__pycache__/**`, `.venv/**`, `venv/**`.
- For diffs, prefer `git diff <base>..HEAD -- <path>` over unfiltered diff.
- Reports should reference scratch artifacts by path, not inline their full contents.
- See `cli-tools.md` for the full toolbox. The principle: if a CLI gives a deterministic answer, use it before reading and reasoning.
