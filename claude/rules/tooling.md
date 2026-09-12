# Tooling

Which CLI to reach for, how to call the bin scripts, and where temporary files go.

## 1. Reach for the CLI first

When a deterministic CLI can answer the question, call it before reading files and reasoning. Fewer tokens wins: one CLI call beats a targeted read beats a broad grep beats reasoning from memory. Authoritative inventory of what is installed: `~/.dotfiles/Brewfile`.

| Question                                     | Tool                                                                         | Over                               |
| -------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------- |
| Locate code by text                          | `rg`                                                                         | grep, find -name, Read walks       |
| Locate code by shape (AST)                   | `sg`                                                                         | rg, when structure is the question |
| Find files/paths                             | `fd`                                                                         | find                               |
| Repo size, language breakdown                | `tokei`                                                                      | reading files to estimate          |
| Secrets, quick                               | `gitleaks`                                                                   | manual grep                        |
| Secrets, deep history                        | `trufflehog git file://.`                                                    | gitleaks                           |
| Timing a perf claim                          | `hyperfine`                                                                  | opinion                            |
| JSON                                         | `jq`, or `gron` to grep flat paths                                           | substring matching                 |
| YAML/TOML                                    | `yq`                                                                         | manual parsing                     |
| CSV/TSV                                      | `qsv`                                                                        | ad-hoc awk                         |
| In-place substitution                        | `sd 'find' 'repl' file`                                                      | sed -i                             |
| Buffer stdin for in-place pipes              | `cmd \| sponge file`                                                         | temp-file dance                    |
| Fixup commits from staged hunks              | `git absorb`                                                                 | rebase -i + fixup                  |
| Git outside cwd                              | `git -C <dir>`                                                               | cd <dir> && git (prompts)          |
| Validate a GitHub Actions workflow           | `actionlint`                                                                 | reading YAML by eye                |
| Who calls X, callers/callees, how Y is wired | `mcp__codebase-memory-mcp__search_graph` / `trace_path` / `get_architecture` | grep + multi-file reads            |

Graph tools answer structural questions in one call where grep needs a read chain, but only cover indexed projects - check `list_projects` / `index_status` first, and fall back to `rg` for literal text or an unindexed repo.

Factual question (how big, what secrets, how fast, what is in this JSON): reach for the tool. Interpretive question (is this correct, does this design hold): reading and reasoning is correct.

### Budget

- Cap `git log` at `-20` unless a wider window is justified.
- Do not `cat` files over 500 lines without a reason. Use line ranges.
- Once located, read the matched section, not the whole file.
- Do not re-read a file in the same session unless an edit changed it.
- For diffs, prefer `git diff <base>..HEAD -- <path>` over unfiltered diff.
- Reference scratch artifacts by path; do not inline their contents.
- Skip for any glob, grep, or read: `node_modules/**`, `.next/**`, `dist/**`, `build/**`, `coverage/**`, `.turbo/**`, `.cache/**`, `vendor/**`, `target/**`, `out/**`, `storybook-static/**`, `.pnpm-store/**`, `__pycache__/**`, `.venv/**`, `venv/**`.

## 2. Call bin scripts by bare name

`~/.claude/bin` is on PATH. Call every script there by bare name, never by path.

- Correct: `project-name.sh`, `run-checks.sh`, `git-base.sh main`, `scratch-dir.sh`
- Wrong: `$HOME/.claude/bin/run-checks.sh`, `./bin/run-checks.sh`, `bash run-checks.sh`

Arguments go as plain positional args after a space. Do not wrap a call in `bash` or `sh`; the shebang handles it. Inline skill injection uses the same form: `` !`project-name.sh` ``.

`settings.json` grants scoped `Bash(<name>:*)` allows keyed to the bare name - a pathful or wrapped invocation will not match and triggers a permission prompt. It also matters for `guard-bash.sh`'s chain-safety classification, which keys on the leading binary name.

Script-to-script calls inside the bin scripts are exempt; they resolve paths internally.

## 3. Scratch

Scratch is whatever `scratch-dir.sh` prints: `<project-root>/scratch/` inside a recognized project (a git worktree, or a stack sentinel matched during the ancestor walk), `$HOME/.claude/scratch/` everywhere else.

The project tier is `scratch/`, not `.claude/scratch/`: Claude Code treats `.claude/` as protected and always confirms edits there regardless of allow rules.

**Everything temporary goes there**: reports, plans, previews, test artifacts, proof-of-concept scripts, one-off debug files, downloads, screenshots, logs. This overrides two competing defaults - the harness's per-session `/tmp` scratchpad (the project `scratch/` survives the session) and ad hoc paths under `~/.claude/`. The harness's own memory stores are the one carve-out.

### Never the project root

Resolve the destination first, then pass it explicitly:

- `curl -o "$(scratch-dir.sh)/<name>"`, not `curl -O`
- a screenshot or export tool's `out_dir` argument, not its default
- `cmd > "$(scratch-dir.sh)/<name>.log"`, not `cmd > out.log`

Never default to `.`, a bare filename, or whatever directory the tool picks. A stray file in the project root pollutes `git status`, risks being committed, and lands in every clone.

`guard-bash.sh` blocks `curl -O`/`-J` and bare `wget` outright, and forces a prompt on an explicit relative target. Tool-driven writes (a browser screenshot's `out_dir`, an MCP server's download path) are invisible to the hook and rely on this rule.

### Naming

Structured artifacts (reports, plans):

```
$(scratch-dir.sh)/<kind>-<scope-slug>-<YYYYMMDD-HHMM>.md
$(scratch-dir.sh)/<kind>-<YYYYMMDD-HHMM>.md        # no scope slug
```

Test artifacts and POC files need no fixed shape - name them sensibly, but keep them under the resolved directory.

Reading the most recent artifact of a kind, always filtered to the resolved directory:

```sh
ls -t "$(scratch-dir.sh)"/<kind>-*.md | head -1
```

Never read across projects. If none exists for this project, run the predecessor command first.

### Retention

`scratch-rotate.sh` prunes both tiers on a 30-day default (pass a custom window as the first argument). The home tier is pruned directly. Project tiers are pruned via a registry: `scratch-dir.sh` appends each project scratch path it resolves to `~/.claude/logs/scratch-registry.txt`, and the rotate run reads that file, since the scheduled launchd run has no project cwd of its own. Project `scratch/` directories are gitignored.
