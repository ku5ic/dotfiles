---
description: Turn a confirmed task into an ordered implementation plan with explicit tradeoffs
argument-hint: <task description or link to preflight report>
allowed-tools: Read, Grep, Glob, Bash($HOME/.claude/bin/detect-stack.sh)
---

**Effort: heavy.** Thinking-heavy. Read project CLAUDE.md, relevant skills, and the preflight report if one exists.

## Prerequisites

- A preflight report exists in `~/.claude/scratch/`. If not, run `/flow:preflight` first.
- The task is stated clearly. If $ARGUMENTS is vague, ask one focused clarifying question before planning.

## Procedure

1. Read the most recent preflight report in `.claude/scratch/`.
2. Load the patterns skill matching the detected stack (react-patterns, django-patterns, etc.) if the task is in that area.
3. Consider two implementation approaches. For each: scope, risk, effort, reversibility. Pick one and justify why.
4. Break the chosen approach into phased steps. Each step is independently committable and leaves the codebase in a working state.
5. Identify the test strategy per step.
6. Identify rollback: if step N fails in production, what is the revert path.

## Output

Write a plan to `.claude/scratch/plan-<task-slug>-<YYYYMMDD-HHMM>.md`:

- Goal (one sentence)
- Non-goals (what this change explicitly does not do)
- Chosen approach and rationale
- Rejected alternatives (one line each, why rejected)
- Phased steps. Each step: files touched, behavior change, test, commit message shape
- Risks and mitigations
- Open questions for the user

Print the path. Do not implement.

## Stop

Present the plan and wait for approval, changes, or rejection. Do not move to implement.
