# CLAUDE.md

Global instructions for Claude Code, every repository. Project CLAUDE.md files extend these.

`rules/*.md` loads every session: output, evidence, change, workflow, tooling, agents. `rules/markdown-report.md` is path-scoped, so read `~/.claude/rules/markdown-report.md` before writing any audit or review report. Reply shape and length are the i-have-adhd plugin's job.

The three that bind hardest:

- **Answer first.** First line of every reply is the answer, command, or path. One next action at the end. `guard-response.sh` blocks banned openers and walls of text, never length.
- **Never invent.** Paths, API shapes, versions, and test results are read, not recalled. Label every theory `verified` / `likely` / `hypothesis` / `unknown`.
- **Ask before destroying.** Destructive operations, dependency changes, and project config edits need explicit confirmation.

## Skills

- `<required-skills>` block: invoke each named skill via the Skill tool before any other action. Blocking.
- `<suggested-skills>` block: load the named skill when about to take that action.
- `guard-skills` blocks the first edit of a mapped file type until its patterns skill is loaded for the session.
- Source of truth for every mapping and trigger phrase: `_stacks.yml`.

## Project boot protocol

Once per session, on the first substantive action in a repo:

1. Use the injected `<repo-context>` block for stack info. If it is absent and the project root has a stack sentinel (`anchor: true` in `_stacks.yml`), say so: the hook should have fired.
2. Read the project root CLAUDE.md. Read README.md only if directly relevant to the task.
3. Check branch and dirty state. Dirty tree plus a new-feature task: surface it and ask before proceeding.
4. Use the injected `<tooling>` block for the test runner, type checker, linter, and formatter.
5. Do not run quality checks yet. Save that for after a change.

## Planning

- Multi-step work: TaskCreate past a couple of steps, one item per step, one in progress at a time.
- If the task grows mid-execution, pause and confirm the expanded scope.
- If a task needs more than the current context can hold, say so and propose a split.
- Never declare a task complete with failing checks. Run `/flow-checks` or `run-checks.sh`; if any fail, fix them or report and stop.
