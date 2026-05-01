---
description: Execute an approved plan step by step, staying within scope
argument-hint: <optional: step number or range>
---

**Effort: heavy.** Actual code changes. Stay strictly within the approved plan.

## Prerequisites

- An approved plan exists for this project: `ls -t ~/.claude/scratch/plan-<project-name>-*.md | head -1`. If none, run /flow:plan first.
- If $ARGUMENTS specifies a step or range, implement only those. Otherwise implement the next unchecked step.

## Procedure

1. Get the project name: `!`project-name.sh``. Read the most recent plan for this project: `ls -t ~/.claude/scratch/plan-<project-name>-\*.md | head -1`. Identify the step to implement.
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

## Code-level integrity (per file changed)

Apply during step 4 alongside existing style-matching:

- Cohesion: each function does one thing; if the function name needs an "and", split it.
- Coupling: a new module or component depends on the fewest concrete other modules possible. If a new file imports more than five non-stdlib modules, name why.
- Naming: names describe what, not how. `processItems` is weak; `validatePaymentBatch` is concrete.
- Magic values: literal numbers or strings beyond 0, 1, -1, "", and obvious enums get a named constant with a comment explaining the value.
- Single source of truth: a piece of data lives in one place. If you find yourself synchronizing two stores, stop and surface.
- Comments: explain why, not what. Remove comments that paraphrase the next line.

If a file change violates any of these and the violation is not justified by the plan, stop and surface. Do not silently absorb the violation.

## Output

No report file. Terminal output only:

- Files changed (path list)
- What each change accomplishes (one line each)
- Verification result: pass, fail, not run
- Next: what the next step in the plan is, or "plan complete"

## Stop

If the plan declares its steps as a single phase (all steps under one "Phase" or "Step" heading; mechanical plans typically have this shape), implement all steps in that phase in one turn, then stop at the phase boundary. Pause at phase boundaries only.
If the plan has multiple phases, stop at the end of each phase and wait
for the user to say `continue`, or invoke `/flow:test` or `/flow:review`.

The user can override at any time with "stop after step N" in $ARGUMENTS, or pass `--step` to force per-step pausing for a substantive plan.
