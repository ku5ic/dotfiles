---
description: Establish shared understanding of the codebase before any work begins
argument-hint: <optional task description>
model: sonnet
effort: medium
---

## Procedure

1. Get the project name: `!`project-name.sh``. Stack is in the injected `<repo-context>` block.
2. Session continuity check. If a previous preflight artifact exists for this project from this session (`ls -t ~/.claude/scratch/preflight-<project-name>-*.md | head -1`), compare current `git status` and `git log -5 --oneline` against the artifact's recorded state. If unchanged AND the new task's target area is covered by the previous artifact, emit a delta-only report ("same context as preflight-<project-name>-<HHMM>, no new findings, target area X already covered") and stop. Otherwise proceed to step 3.
3. Read `CLAUDE.md` at the project root in full. Read any `CLAUDE.md` in the path from project root to the target area.
4. Read project README only if it explicitly covers the task area, judged from headings.
5. Identify the minimum file set the task touches: the files that will change, plus the files that the changing files import or depend on. No more, no less.
6. Requirements clarity check. Before reading the minimum file set, evaluate the task statement from $ARGUMENTS or the prior conversation against:
   - Testable: can pass/fail be observed without ambiguity? If "improve X" or "make Y better" without a measurable signal, flag.
   - Unambiguous: does the statement admit only one reasonable interpretation? If words like "should also handle X if needed" appear, flag.
   - Complete: are inputs, outputs, and error cases stated or inferable from the codebase? If only the happy path is described, flag.
   - Consistent: does the statement contradict anything in CLAUDE.md, the existing tests, or the recent commit history? If yes, flag.

   If any of the four flag, stop and ask one focused clarifying question before proceeding to step 6. Do not infer requirements; surface the gap.

7. Read those files.
8. File budget: read at most 12 files across steps 3-6. If the minimum set exceeds 12, stop and ask the user to scope the task. The tokei call in step 8 does not count toward this budget.
9. Run `tokei` once at the project root for repo size context: total lines, language breakdown. This replaces the reflex to read many files just to estimate size. Capture the headline numbers in the preflight report under the Stack summary.
10. Identify the CI checks the project defines (scripts in `package.json`, `Makefile`, `pyproject.toml` `[tool]` sections). List what is available (typecheck, lint, test, format) without running them. Note any that are missing entirely.
11. Check `git status` and `git log -5 --oneline`. Note uncommitted work and recent direction.

## Output

Write a short preflight report with:

- Stack summary (from injected `<repo-context>` block, plus tokei size headline)
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
