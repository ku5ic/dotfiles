---
description: Execute an approved plan step by step, staying within scope
argument-hint: <optional: step number or range>
model: sonnet
effort: high
---

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
6. Run Skill(/flow:checks) after each Phase.
7. Pause. Report what was done, what was verified, what is left in the step.

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

Default rule (any plan with two or more phases): implement exactly one phase per turn, then stop and wait for the user to say `continue`, or to invoke `/flow:test` or `/flow:review`. Every phase boundary is a hard stop. Do not roll consecutive phases into the same turn under any rationale, including: the phases are short, mechanical, thematically related, sequentially numbered, or "obviously" safe to batch. A 12-phase plan produces 11 stops, not fewer.

Counting phases: a phase is anything declared with a `Phase` or `Step` heading in the plan. Numbered subheadings inside a single phase are steps, not phases, and are not pause points on their own.

Exception (single-phase plans only): if the plan declares exactly one phase total, with every step nested under that one heading, implement every step in one turn and stop at the end. This exception does not apply to multi-phase plans where individual phases happen to contain only one step.

The user can override at any time with "stop after step N" in $ARGUMENTS, or pass `--step` to force per-step pausing inside a substantive phase.
