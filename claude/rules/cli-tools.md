# Preferred CLI tools

When a deterministic CLI can answer the question, call it before reading files and reasoning. Fewer tokens wins: one CLI call beats a targeted read beats a broad grep beats reasoning from memory. Authoritative inventory of installed tools: `~/.dotfiles/Brewfile`; confirm there before using anything not listed below.

| Question                        | Tool                                | Over                                           |
| ------------------------------- | ----------------------------------- | ---------------------------------------------- |
| Locate code by text             | `rg`                                | grep, find -name, Read walks                   |
| Locate code by shape (AST)      | `sg`                                | rg, when the question is structure not text    |
| Find files/paths                | `fd`                                | find                                           |
| Repo size, language breakdown   | `tokei`                             | reading files to estimate                      |
| Secrets, quick                  | `gitleaks`                          | manual grep                                    |
| Secrets, deep history           | `trufflehog git file://.`           | gitleaks                                       |
| Timing a perf claim             | `hyperfine`                         | opinion                                        |
| JSON                            | `jq` (or `gron` to grep flat paths) | substring matching                             |
| YAML/TOML                       | `yq`                                | manual parsing                                 |
| CSV/TSV                         | `qsv`                               | ad-hoc awk                                     |
| In-place substitution           | `sd 'find' 'repl' file`             | sed -i                                         |
| Buffer stdin for in-place pipes | `cmd \| sponge file`                | temp-file dance                                |
| Fixup commits from staged hunks | `git absorb`                        | rebase -i + fixup                              |
| Git outside cwd                 | `git -C <dir>`                      | cd <dir> && git (triggers a permission prompt) |

Factual question (how big, what secrets, how fast, what is in this JSON): reach for the tool. Interpretive question (is this correct, does this design hold): reading and reasoning is correct.

## Budget

- Cap `git log` to `-20` unless a wider window is justified.
- Do not `cat` files larger than 500 lines without a specific reason. Use line ranges.
- Once located, read only the matched section, not the whole file.
- Do not re-read a file in the same session unless an edit has changed it.
- Skip these directories for any glob, grep, or read: `node_modules/**`, `.next/**`, `dist/**`, `build/**`, `coverage/**`, `.turbo/**`, `.cache/**`, `vendor/**`, `target/**`, `out/**`, `storybook-static/**`, `.pnpm-store/**`, `__pycache__/**`, `.venv/**`, `venv/**`.
- For diffs, prefer `git diff <base>..HEAD -- <path>` over unfiltered diff.
- Reports should reference scratch artifacts by path, not inline their full contents.
