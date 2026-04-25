---
description: Establish shared understanding of the codebase before any work begins
argument-hint: <optional task description>
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash($HOME/.claude/bin/project-name.sh)
---

**Effort: medium.** Read, do not write. No code generation in this step.

## Procedure

1. Get the project name: `!`$HOME/.claude/bin/project-name.sh``. Stack is in the injected `<repo-context>` block.
2. Read `CLAUDE.md` at the project root in full. Read any `CLAUDE.md` in the path from project root to the target area.
3. Read project README only if it explicitly covers the task area, judged from headings.
4. Identify the minimum file set the task touches: the files that will change, plus the files that the changing files import or depend on. No more, no less.
5. Read those files.
6. File budget: read at most 12 files across steps 2-5. If the minimum set exceeds 12, stop and ask the user to scope the task.
7. Identify the CI checks the project defines (scripts in `package.json`, `Makefile`, `pyproject.toml` `[tool]` sections). List what is available (typecheck, lint, test, format) without running them. Note any that are missing entirely.
8. Check `git status` and `git log -5 --oneline`. Note uncommitted work and recent direction.

## Output

Write a short preflight report with:

- Stack summary (from injected `<repo-context>` block)
- Task (from $ARGUMENTS, or "not specified, ask user")
- Files that will change
- Files read for context
- Layer or boundary ownership (which module owns this change)
- CI health now (typecheck, lint, test, format)
- Risks, unknowns, or stop conditions
- Recommended smallest next step

Write to `~/.claude/scratch/preflight-<project-name>-<YYYYMMDD-HHMM>.md`. Print the path.

## Stop

Do not plan. Do not implement. Do not propose code. Present the report and wait for explicit confirmation on the next step. The task and its shape are the user's decision, not yours.
