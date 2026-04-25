---
description: Execute an approved plan step by step, staying within scope
argument-hint: <optional: step number or range>
allowed-tools: Read, Edit, MultiEdit, Write, Grep, Glob, Bash($HOME/.claude/bin/project-name.sh), Bash(ls:*)
---

**Effort: heavy.** Actual code changes. Stay strictly within the approved plan.

## Prerequisites

- An approved plan exists for this project: `ls -t ~/.claude/scratch/plan-<project-name>-*.md | head -1`. If none, run /flow:plan first.
- If $ARGUMENTS specifies a step or range, implement only those. Otherwise implement the next unchecked step.

## Procedure

1. Get the project name: `!`$HOME/.claude/bin/project-name.sh``. Read the most recent plan for this project: `ls -t ~/.claude/scratch/plan-<project-name>-\*.md | head -1`. Identify the step to implement.
2. Confirm the files involved still match the plan. If drift: stop and report.
3. Load the patterns skill for the stack if the change is stack-specific.
4. Make the changes. One step at a time. After each file:
   - Match existing style, naming, and patterns. Read a nearby file first if unsure.
   - Do not refactor unrelated code.
   - Do not upgrade or add dependencies unless the plan explicitly includes them.
   - Comments only where the code does not explain itself. Explain why, not what.
5. Run the narrow verification the plan prescribed (one file's tests, one type check).
6. Pause. Report what was done, what was verified, what is left in the step.

## Scope rules

- Stay in the files the plan names. If the plan is wrong, stop and surface the mismatch. Do not silently expand.
- If a drive-by fix is tempting: note it, propose as a separate step or commit. Do not apply.
- If the change requires editing project-level config (`tsconfig`, `next.config`, `settings.py`, etc.): stop and ask. This matches the CLAUDE.md rule.

## Output

No report file. Terminal output only:

- Files changed (path list)
- What each change accomplishes (one line each)
- Verification result: pass, fail, not run
- Next: what the next step in the plan is, or "plan complete"

## Stop

After each step, stop. Do not proceed to the next step even if it is small. Wait for the user to explicitly say `continue`, or to invoke `/flow:test` or `/flow:review`.
