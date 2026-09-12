# CLAUDE.md

Global instructions for Claude Code. Applies to every repository. Project level CLAUDE.md files extend these rules.

## The rules

`rules/*.md` loads unconditionally every session via Claude Code's native `.claude/rules/` support - same priority as this file, not read-on-demand. Seven files, one topic each:

| File                       | Governs                                                                         |
| -------------------------- | ------------------------------------------------------------------------------- |
| `rules/output.md`          | Reply shape, length tiers, voice, where deliverables go.                        |
| `rules/evidence.md`        | What must be true before a claim, conclusion, or cross-boundary fix is stated.  |
| `rules/change.md`          | Fix sizing, blast radius, dead code, code style, scope.                         |
| `rules/workflow.md`        | Git, destructive operations, the skills namespace, resolving external context.  |
| `rules/tooling.md`         | Which CLI to reach for, bin script invocation, scratch conventions.             |
| `rules/agents.md`          | Spawn discipline, model/effort pins, the forked decision protocol, agent shell. |
| `rules/markdown-report.md` | The report format every audit and review writes to disk.                        |

The three that bind hardest, in one line each:

- **Answer first.** First line of every reply is the answer, command, or path. At most 3 bullets after it. One next action. Default ceiling is 12 prose lines - `guard-response.sh` enforces it.
- **Never invent.** Paths, API shapes, versions, and test results are read, not recalled. Label every theory `verified` / `likely` / `hypothesis` / `unknown`.
- **Ask before destroying.** Destructive operations, dependency changes, and project config edits need explicit confirmation.

## Required skills

Skills surface in three layers:

| Layer     | Source                     | Behavior                                                                                                                                                               |
| --------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Required  | `<required-skills>` block  | The global core, empty by default - when `global_skills` does name a skill, invoke it immediately via the Skill tool before any other action; blocking, no exceptions. |
| Suggested | `<suggested-skills>` block | Action-conditioned stack skills, one trigger action per line - load the skill when about to take that action.                                                          |
| Enforced  | `guard-skills`             | Blocks the first read or edit of any file type mapped in `_stacks.yml` until the relevant patterns skill is loaded for the session.                                    |

Source of truth for all skill mappings and trigger phrases: `_stacks.yml`.

## Project boot protocol

On the first substantive action in a repo:

1. Check for an injected `<repo-context>` block.
   - Present: use it for stack info.
   - Absent, and the project root has a stack sentinel (see `anchor: true` entries in `_stacks.yml`): surface it - the hook should have fired but did not.
   - Absent, and no sentinel exists: proceed normally, the hook intentionally skips non-stack repos.
2. Read project root CLAUDE.md if present.
3. Read README.md only if directly relevant to the task.
4. Check current branch and dirty state. If dirty and the task implies a new feature, surface this and ask before proceeding.
5. Use the injected `<tooling>` block for the test runner, type checker, linter, and formatter; identify manually only if it is absent.
6. Do not run quality checks yet. Save that for after a change.

After this protocol runs once per session, do not repeat it.

## Verification before acting

- Read the file before editing it. Never edit from memory.
- Check what the project already uses before adding a tool, library, or pattern (`rules/change.md`).
- Check the project defines a script before running it: `scripts` in `package.json`, Makefile, justfile, task runner.
- Verify current versions and APIs of fast-moving tools against the authoritative source or the lockfile. Training memory is not sufficient.
- Never assume paths, directory structure, or naming. Look first, and state what was checked (`rules/evidence.md`).
- Never declare a task complete with failing checks. Run `/flow-checks` or `run-checks.sh`; if any fail, fix them or report and stop.

## Planning

- For multi-step work, plan first. Use TaskCreate past a couple of steps.
- If the task grows mid-execution, pause and confirm the expanded scope.
- If a task needs more than the current context can hold, say so and propose a split.

## Principles

- SOLID, DRY, KISS: judgment, not ritual - see engineering-fundamentals, loaded every session.
- Correctness, clarity, and long-term maintainability over novelty.
- Proven patterns over trendy abstractions, absent a strong explicit reason.
- Production-ready solutions with tradeoffs stated.
- Accessibility, performance, and clean semantics are not optional.
