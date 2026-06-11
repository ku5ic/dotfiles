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
