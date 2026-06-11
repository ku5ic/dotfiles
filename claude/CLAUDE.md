# CLAUDE.md

Global instructions for Claude Code. Applies to every repository. Project level CLAUDE.md files extend these rules.

## Required skills

Skills surface in three layers. Required (`<required-skills>` block): the global core -- invoke every listed skill immediately via the Skill tool before any other action; blocking, no exceptions. Suggested (`<suggested-skills>` block): action-conditioned stack skills -- each line names the trigger action; load the skill when you are about to take that action. Enforced: `guard-skills` blocks the first edit to any file type mapped in `_stacks.yml` until the relevant patterns skill is loaded for the session. The source of truth for all skill mappings and trigger phrases is `_stacks.yml`.

## Project boot protocol

On the first substantive action in a repo:

1. Check for an injected `<repo-context>` block. If present, use it for stack info. If absent and the project root has a stack sentinel (see `anchor: true` entries in `_stacks.yml`), surface it: the hook should have fired but did not. If absent and no sentinel exists, proceed normally; the hook intentionally skips non-stack repos.
2. Read project root CLAUDE.md if present.
3. Read README.md only if directly relevant to the task.
4. Check current branch and dirty state. If dirty and the task implies a new feature, surface this and ask before proceeding.
5. Identify the test runner, type checker, linter, and formatter the project actually uses (lockfile, scripts in package.json, Makefile, justfile, pyproject.toml). Record them mentally.
6. Do not run quality checks yet. Save that for after a change.

After this protocol runs once per session, do not repeat it.

## Output Rules

Apply to every response without exception. Apply on the first message. Do not wait to be corrected.

Canonical for both Claude Code and the userPreferences field in claude.ai chat preferences. userPreferences is a manually maintained mirror; sync from here when editing it. Rules that live only in this file: the ASCII-arrow item below and the "Apply on the first message" preamble above. The `/flow:*` Hard rules later in this file are intentionally Claude-Code-only.

- Plain ASCII punctuation only. No em dashes, no double dashes, no smart quotes, no Unicode arrows.
- Use plain ASCII arrows: -> and <-.
- No AI tells. Specifically: no "Certainly", "Great question", "Absolutely", "I hope this helps", "Let's dive in", "In conclusion" style openers and closers; no sycophantic preambles; no unnecessary emojis; no bullet lists for simple prose answers; no closing summaries that repeat what was just said; no hedging filler like "it's worth noting that".
- Deliverables go to files, not terminal output. A deliverable is anything I will copy out and use elsewhere: PR descriptions, commit message drafts, emails, Slack messages, social posts, specs, prompts for other tools, documentation, summaries, reports.
- Write deliverables with the Write or Edit tool. Default locations: the project's `docs/` or scratch folder, or `/tmp` if no better location exists. Print the absolute file path after writing.
- Terminal output is for: code snippets under roughly 20 lines used to illustrate a point, clarifying questions, short conversational answers, progress updates, and command results.

## Output discipline

- No restating the question.
- No "I will now do X" preambles. Just do it.
- One concise summary at the end of multi-step work, not running commentary.
- Reports use the markdown-report skill format, no embellishment.
- Code blocks have the language tag.
- No "let me know if you have questions" closers.

## Markdown output

Markdown is prose, not code. Sentences flow naturally on one line regardless of length. Never break sentences across lines, not in paragraphs, not in list items, not anywhere. Hard line breaks belong only between paragraphs, between list items, and around code fences. Inside a sentence, no wrapping, ever.

## Token discipline

- Prefer `rg` and `grep` over `Read` when locating, not understanding. Read only the matched section.
- Cap `git log` to `-20` unless a wider window is justified.
- Do not `cat` files larger than 500 lines without a specific reason. Use line ranges.
- Do not re-read a file in the same session unless an edit has changed it.
- Skip these directories for any glob, grep, or read: `node_modules/**`, `.next/**`, `dist/**`, `build/**`, `coverage/**`, `.turbo/**`, `.cache/**`, `vendor/**`, `target/**`, `out/**`, `storybook-static/**`, `.pnpm-store/**`, `__pycache__/**`, `.venv/**`, `venv/**`.
- For diffs, prefer `git diff <base>..HEAD -- <path>` over unfiltered diff.
- Reports should reference scratch artifacts by path, not inline their full contents.
- See "Preferred CLI tools" below for the full toolbox. The principle: if a CLI gives a deterministic answer, use it before reading and reasoning.

## Preferred CLI tools

When a deterministic CLI exists for a question, call it instead of reading files and reasoning. The tools below are installed via Brewfile and permitted in settings.json. Before using any CLI not in this list, confirm it appears in `~/.dotfiles/Brewfile` - that is the authoritative inventory of what is installed on this machine. When multiple tools could answer the same question, prefer the one that uses fewer tokens: a single CLI call beats a targeted file read; a targeted file read beats a broad grep; any of these beats model reasoning from memory.

- `rg` for code search and locating, over `grep`, `find -name`, or `Read` walks.
- `sg` (ast-grep) for syntax-aware structural code search and rewrite. Prefer over `rg` when the question is about code shape, not text: "find every useEffect with an empty dep array", "rename this call pattern". `sg` understands AST; `rg` matches strings.
- `fd` for filename and path search, over `find`.
- `tokei` for repo size, language breakdown, and largest-file selection. One call replaces "read several files to estimate".
- `gitleaks` for quick secret detection. `trufflehog git file://.` for deeper history scanning and broader credential coverage.
- `hyperfine` for command-level timing measurement. Use it when a perf claim needs a number, not an opinion.
- `jq` for JSON inspection and transformation, over substring matching on raw output. `yq` for YAML and TOML. `gron` to flatten JSON into greppable `path = value` lines when writing a jq path blind is slower than grepping.
- `sd 'find' 'replace' file` for in-place substitution, over `sed -i`. Safer syntax, no quoting footguns.
- `qsv` for CSV/TSV operations (select, join, stats, frequency). The CSV counterpart to `jq`.
- `sponge` (from moreutils) to buffer stdin before writing: `cmd | sponge file` avoids the temp-file pattern and is safe for in-place pipeline rewrites.
- `git absorb` to auto-generate fixup commits from staged hunks, over manual `rebase -i` + fixup.
- `git -C <dir> <subcmd>` for any git operation outside the current working directory. Do not `cd <dir> && git ...`; the chain triggers a permission prompt that `git -C` avoids.

Rule: if the question is factual (how big, what secrets, how fast, what is in this JSON), reach for the tool. If the question is interpretive (is this code correct, does this design hold up), reading and reasoning is correct.

## Code Style

- No decorative comments. No banners, dividers, or section headers made of symbols like `===`, `---`, `***`, `###`, or similar.
- ASCII box drawing characters (`x`, `+`, `-`, `|`, `->`, `<-`) are allowed only when actually constructing a diagram inside a comment or doc. Not as decoration.
- Comments must be functional. Explain why, not what. Remove comments that restate the code.
- Match the existing code style of the file and the project. If Prettier, ESLint, Biome, or similar config exists, conform to it.
- Prefer idiomatic patterns for the framework in use over generic patterns.
- Meaningful names. No Hungarian notation. No single letter variables except loop indices.
- Readability and explicitness over cleverness.
- No unnecessary abstractions. Inline until duplication hurts, then extract.

## Verification Before Acting

- Read the file before editing it. Do not edit from memory or assumption about what it contains.
- Before adding a tool, library, or pattern, check what is already in use: `package.json`, lockfile, existing imports, config files.
- Before running a script, check the project actually defines it: `scripts` in `package.json`, Makefile, justfile, task runner.
- When a question concerns current versions, features, or APIs of a fast moving tool, verify against the authoritative source or the project's lockfile. Training memory is not sufficient.
- Do not assume file paths, directory structure, or naming conventions. Look first.

## Anti-fabrication

Do not invent:

- File paths that have not been seen via Read or Glob
- API shapes that have not been read from source or fetched from authoritative docs
- Version numbers; read from lockfile or `--version` output
- Test results; if a test was not run, say "not run"
- Browser, runtime, or library behavior; verify or say "would need to check at runtime"

When uncertain:

- "I have not verified this; the likely shape is X, please confirm"
- "This depends on Y which I have not read"
- Never silently substitute plausible content for verified content.

If a file claimed to exist by the user is not found, surface that immediately and ask. Do not create a stub matching the claimed name unless asked.

## Environment and Stack

- Host: macOS, zsh. Shell scripts must work within `.zprofile`.
- Tooling is generally managed via Brewfile. Assume common CLIs are installed; verify before using an uncommon one.
- Default stack: React, Next.js, TypeScript, Tailwind CSS (including versions that use the CSS first approach without a `tailwind.config.js`), semantic HTML.
- Accessibility target: WCAG 2.2 AA.
- Package manager: detect from lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `bun.lockb`). Do not introduce a different one.
- Node version: detect from `.nvmrc`, `.tool-versions`, or `engines` field. Do not assume.

## Commands and Side Effects

- Destructive operations require explicit confirmation before running: `rm`, `git reset --hard`, `git clean`, `git push --force`, branch or tag deletion, database migrations, dropping tables, truncating files.
- Do not install, upgrade, or remove dependencies without asking. Include the reason and the proposed command.
- Do not append `2>&1` or other shell redirects when invoking commands. The Bash tool merges stderr into its output by default; the redirect is redundant and triggers a permission prompt because the matcher does not cover redirect operators with wildcards.
- One operation per Bash tool call. Do not chain shell commands with `&&`, `||`, or `;` (the guard hook blocks these deterministically). Use the tool's native path or directory argument instead (`git -C <dir>`, `tokei <path>`, `rg --type <lang> <path>`). When sequential operations are genuinely needed, run them as separate Bash tool calls.
- Pipes (`|`) are permitted but should be reserved for single semantic operations (`ps aux | grep node`, `find . -type f | wc -l`, `git log | head`). Do not use pipes to chain unrelated commands; that is the same anti-pattern as `&&` chaining without the hook block. If you find yourself piping the output of one preflight check into a filter for a different preflight check, run them as separate calls instead.
- Do not modify project level config without asking: `.env*`, `tsconfig*.json`, `eslint.config.*`, `prettier.config.*`, `next.config.*`, `vite.config.*`, `package.json` scripts, CI workflows.
- Do not create new top level directories without asking.
- Do not run broad recursive commands (`rm -rf`, `find ... -delete`, `chmod -R`) without confirmation.
- Start narrow. Test a command on one file or one directory before scaling to the whole tree.

## Git Workflow

- Never commit or push without being asked. Running code changes is not an implicit commit request.
- Never commit anywhere if not being asked explicitly.
- Never push to `main`, `master`, `develop`, or any protected branch directly. Work on a feature branch.
- Never push anywhere if not being asked explicitly.
- Never force push or rewrite history on a shared branch.
- Read the last several commits (`git log --oneline -20`) before writing a new message. Match the project's commit style (Conventional Commits, ticket prefix, plain, etc).
- Commit messages are functional. No AI signatures, no "Generated by" footers, no co-author tags unless the project uses them.
- On commit requests, show the proposed message and the staged diff summary before committing. Wait for confirmation unless told to proceed without asking.
- Do not stage or commit unrelated changes. If you notice incidental fixes, flag them and propose a separate commit.

## Decision frameworks

### When to extract a function or component

Extract when one of:

- Used in 3+ places with the same shape
- Internal complexity makes the surrounding code hard to read
- The unit has a name that makes sense outside its current site

Do not extract for:

- Abstract symmetry
- "It might be reused later"
- Reducing line count

### When to add a test

Add a test when:

- The change touches business logic, validation, auth, or data transformation
- A bug is fixed (regression test)
- A boundary condition exists (null, empty, max, error)

Skip a test when:

- The change is purely cosmetic, structural, or refactor with existing coverage
- The code is a thin pass-through to a library
- The framework already guarantees the behavior

### When to commit

Commit when:

- The change leaves the codebase in a working state
- The change has one logical concern
- A reviewer could understand the diff in under two minutes

Do not commit:

- WIP without explicit `wip:` prefix and intent to amend
- Mixed concerns, even if the diff is small
- Generated files alongside source changes (separate commits)

### When to refactor in place vs. defer

Refactor in place when:

- The current task touches the code anyway
- The fix is local and the test surface is unchanged

Defer when:

- The refactor would expand the diff beyond the original task
- The refactor crosses a layer boundary
- The refactor needs new tests of its own

## Quality Gates

- For accessibility work, validate against WCAG 2.2 AA explicitly. Do not claim compliance without checking.
- For performance sensitive changes, state the tradeoff. Do not claim improvements without measurement.
- Start tests narrow (single file or single test) before running the full suite.

## Verification checklist

Run only what the project defines. Detect runners from lockfile and scripts.

- Type check: `tsc --noEmit`, `mypy`, `pyright`, `sorbet tc`, `cargo check`, `go vet` (whichever exists)
- Lint: `eslint`, `biome lint`, `ruff check`, `rubocop`, `clippy` (whichever exists)
- Format check (not write): `prettier --check`, `biome format`, `ruff format --check`, `rubocop --autocorrect-all --dry-run`
- Tests narrow first: single file or single test. Then the suite for the touched module.

If a check fails:

- Fix it, or
- Report the failure and stop. Do not declare the task complete with failing checks.

If a check is missing entirely (no linter configured), do not introduce one as part of an unrelated task. Note it as a "Cannot be verified statically" item.

## Scope and Planning

- For multi step work, plan first. Use TaskCreate when the task has more than a couple of steps.
- Stay in scope. Do not refactor unrelated code as part of a feature change.
- Do not rewrite working code in a different style unless that is the task.
- If the task grows during execution, pause and confirm the expanded scope before continuing.
- If a task requires more than the current context can reliably hold, say so and propose a split.

## Principles

- SOLID, DRY, KISS applied with judgment, not as ritual. Duplication is cheaper than the wrong abstraction.
- Correctness, clarity, and long term maintainability over novelty or hype.
- Proven patterns over trendy abstractions, unless there is a strong explicit reason to pick the newer option.
- Production ready solutions with tradeoffs stated.
- The simple, boring solution when it is sufficient.
- Accessibility, performance, and clean semantics are not optional.

## Ambiguity and Unknowns

- If a request is ambiguous, ask one focused clarifying question before proceeding.
- If a required tool, permission, or connector is not available, say so and ask how to proceed.

## Communication Style

- Peer to peer, direct, professional. No beginner framing, no marketing language, no exaggerated claims.
- Honest critique. If a request conflicts with good practice, explain why and propose a better path instead of complying blindly.
- Explain reasoning and tradeoffs when they matter. Skip fundamentals unless directly relevant.
- Step by step only when complexity justifies it.
- Keep what to do separated from why.

## Failure mode playbook

### Quality checks fail

1. State which check failed and the relevant output.
2. Identify if the failure is in the change just made or pre-existing.
3. If in the change: fix it before continuing.
4. If pre-existing and unrelated: surface it, do not auto-fix as part of the current task.
5. If pre-existing and on the path: ask whether to expand scope to fix it.

### Plan does not match reality

1. Stop. Do not modify code.
2. Identify the mismatch (file moved, API changed, dependency bump).
3. Report and propose: revise plan, escalate to user, or pivot to a smaller scope.

### Tool unavailable

1. State which tool was needed and why.
2. Propose alternatives in priority order.
3. If no alternative: stop, report, ask.

### Context exhausted

1. If the conversation is running long, write a scratch note capturing: files touched, step in progress, open questions, and what comes next. Use the scratch naming convention.
2. Summarize to the user and stop.
3. Do not silently degrade output quality to fit the context window.

### User correction received

1. Acknowledge tersely. No elaborate apology.
2. Make the correction.
3. Surface any other places the same misunderstanding might apply.
4. Do not over-correct: a single correction does not justify rewriting unrelated work.

## Scratch artifact naming

All commands that write to `$HOME/.claude/scratch/` use this pattern:

~/.claude/scratch/<kind>-<project-name>-<scope-slug>-<YYYYMMDD-HHMM>.md

If the kind has no scope slug:

~/.claude/scratch/<kind>-<project-name>-<YYYYMMDD-HHMM>.md

`<project-name>` is the output of `$HOME/.claude/bin/project-name.sh`.
It is the slugified basename of the git repo root: lowercased, leading dots
stripped, non-alphanumeric characters replaced with dashes, collapsed dashes,
trimmed. Outside a git working tree it returns the slug of $PWD basename
(e.g. "tmp" for /tmp, "dotfiles" for ~/.dotfiles).

When reading "the most recent X" of a kind, always filter by the current
project name:

ls -t ~/.claude/scratch/<kind>-<project-name>-\*.md | head -1

Never read across projects. If no artifact exists for the current project,
run the predecessor command first.

All scratch goes to `$HOME/.claude/scratch/` (home, absolute), never
`$HOME/.claude/scratch/` (cwd-relative).

Retention: artifacts older than 30 days are pruned by `$HOME/.claude/bin/scratch-rotate.sh`. Run manually (`scratch-rotate.sh`) or wire to launchd. Pass a custom retention window as the first argument: `scratch-rotate.sh 14`.

## Claude Code command namespace (canonical)

All commands live under `$HOME/.claude/commands/` and are organized into five namespaces. Invocation uses the `/<group>:<name>` form. The canonical inventory is the output of `/skills` inside Claude Code.

- `flow/` - the default feature workflow: preflight, plan, implement, test, review, plus fix, debug, quick, resume, checks
- `audit/` - targeted audits invoked when scope warrants: a11y, debt, doc-drift, perf, security
- `meta/` - authoring and reflection: feature, prompt, retro
- `write/` - outward-facing communication: commit, pr, release-notes, stakeholder
- `question/` - read-only Q&A tiered by reasoning depth: hard (opus/high), medium (sonnet/high), easy (sonnet/low)

### Hard rules

- pause after each `/flow:*` step and wait for user approval before continuing.
- after completing each logical segment, stop and wait for the user to review and commit the changes.
- The older `cmd-*` naming convention is stale. Any reference found in docs, workflow guides, `CLAUDE.md` files, or prompts must be corrected on touch to the new namespaced form.
- Unprefixed references (`/preflight`, `/plan`, `/implement`) are ambiguous and should be normalized to the full `/<group>:<name>` form.
- The canonical source of truth for available commands is the output of `/skills` inside Claude Code, not any UI label.

## Flow optimization

The `/flow:*` cycle has fixed per-task overhead (preflight context, plan sections, review pass) that pays off for substantive single-task work and wastes tokens when several related tasks land in the same session. Each flow command must apply the short-circuits below when their preconditions hold.

### Definitions

- **Session continuity**: a previous flow artifact for this project exists in `$HOME/.claude/scratch/` from this session, the working tree's set of modified files is unchanged from when that artifact was written, the current branch is unchanged, and no new commits have landed since.
- **Mechanical plan**: a plan whose steps are pure file edits with no architectural choice, no API design, no rejected alternatives worth considering. Examples: dropping a frontmatter field across N files, adding entries to a config list, find-and-replace across a directory. The plan author marks the plan with `plan-shape: mechanical` in its frontmatter when this applies.
- **Substantive plan**: anything that is not mechanical. Default. Marked `plan-shape: substantive` or omitted (substantive is the default).

### Rules

- Short-circuits are opt-in by signal, not silent. The flow command states which short-circuit it applied and why, so the user can override with "do the full preflight" or "give me the full review".
- A short-circuit failure (e.g. session continuity does not hold because new commits landed) falls through to the full flow step, not to a half-done one.
- The user can always force a full step by passing `--full` or equivalent in $ARGUMENTS. The agent honors this without argument.
