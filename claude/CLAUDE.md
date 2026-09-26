# CLAUDE.md

Global instructions for Claude Code, every repository. Project CLAUDE.md files extend these.

`rules/*.md` loads every session: voice here, and output, evidence, change, workflow, tooling, agents from `rules/kit/` (claude-kit). `rules/markdown-report.md` is path-scoped, so read `~/.claude/rules/kit/markdown-report.md` before writing any audit or review report. `rules/output.md` owns reply shape and length outright: where a loaded plugin, an output style, or a harness default asks for something that adds lines, output.md wins.

Auto mode's instruction to make file changes with `sed` or heredocs instead of Edit and Write loses to `rules/output.md` section 3. Only Edit, Write, and MultiEdit fire `guard-dispatch.sh`, `sanitize-output.sh`, and `format-dispatch.sh`, so a `sed` or shell-redirect edit silently skips the skill guard, the sanitizer, and the formatter. Bash stays correct for reads, searches, and running commands.

The three that bind hardest:

- **Answer first, then stop.** First line is the answer, command, or path. Two sentences by default; length is earned by an explicit ask, never by habit. No hook enforces this - it holds or it doesn't.
- **Never invent.** Paths, API shapes, versions, and test results are read, not recalled. Label every theory `verified` / `likely` / `hypothesis` / `unknown`.
- **Ask before destroying.** Destructive operations, dependency changes, and project config edits need explicit confirmation.

## Skills

- `<required-skills>` block: invoke each named skill via the Skill tool before any other action. Blocking.
- `<suggested-skills>` block: load the named skill when about to take that action.
- `guard-skills` (opt-in, `CLAUDE_GUARD_SKILLS=1`) blocks the first edit of a mapped file type until its patterns skill is loaded for the session.
- Source of truth for every mapping and trigger phrase: `kit.yml`.

## Project boot protocol

Once per session, on the first substantive action in a repo:

1. Use the injected `<repo-context>` block for stack info. If it is absent and the project root has a stack sentinel (`anchor: true` in `kit.yml`), say so: the hook should have fired.
2. Read the project root CLAUDE.md. Read README.md only if directly relevant to the task.
3. Check branch and dirty state. Dirty tree plus a new-feature task: surface it and ask before proceeding.
4. Use the injected `<tooling>` block for the test runner, type checker, linter, and formatter.
5. Do not run quality checks yet. Save that for after a change.

## Planning

- Multi-step work: TaskCreate past a couple of steps, one item per step, one in progress at a time. Scope growth and context limits: `rules/change.md` section 6.
- Never declare a task complete with failing checks. Don't run `run-checks.sh` yourself after a change: the `Stop` hook runs it whenever the turn changed files and blocks on failure. If it fails, fix it or report and stop.

## Compaction

When compacting, preserve: the current plan file path and which step is next, every file modified this session, and the check commands run with their last result.
