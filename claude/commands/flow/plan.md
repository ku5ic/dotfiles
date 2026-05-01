---
description: Turn a confirmed task into an ordered implementation plan with explicit tradeoffs
argument-hint: <task description or link to preflight report>
---

**Effort: heavy.** Thinking-heavy. Read project CLAUDE.md, relevant skills, and the preflight report if one exists.

## Prerequisites

- A preflight report exists in `~/.claude/scratch/`. If not, run `/flow:preflight` first.
- The task is stated clearly. If $ARGUMENTS is vague, ask one focused clarifying question before planning.

## Procedure

1. Get the project name: `!`project-name.sh``. Read the most recent preflight report for this project: `ls -t ~/.claude/scratch/preflight-<project-name>-\*.md | head -1`. If none exists for this project, run /flow:preflight first.
2. Load the patterns skill matching the detected stack (react-patterns, django-patterns, etc.) if the task is in that area.
3. Determine plan shape. If $ARGUMENTS contains "mechanical:" or "plan-shape: mechanical", the plan is mechanical: skip steps 4 and 6 below (no rejected alternatives, no per-step test strategy beyond a single end verification). If the work is clearly mechanical from the preflight (pure file edits, no architectural choice), the agent may self-mark mechanical, stating the reason. Otherwise the plan is substantive (default).
4. Consider two implementation approaches. For each: scope, risk, effort, reversibility. Pick one and justify why. If both score similarly, pick the approach that touches fewer layers.
   4a. Design integrity check on the chosen approach. For each item, the answer must be a concrete sentence in the plan, not a yes/no:
   - Modularity: which module owns this change? If the change crosses module boundaries, name them and justify.
   - Abstraction level: is the new code at the right level of abstraction for its callers? Concretely: does any caller need to know an implementation detail to use it?
   - Separation of concerns: does any new function or component combine independently changing concerns (data fetching + presentation, validation + persistence, etc.)? If yes, split or justify the merge.
   - KISS: is the simplest sufficient solution being chosen? Name any non-obvious complexity and why it earns its place.
   - DRY judgment: if this introduces apparent duplication, is the duplication along a stable axis or a divergent one? Duplication with divergent lifecycles is correct.
   - Reversibility: if this approach proves wrong after merge, what is the cost to reverse? If high, justify the choice over a more reversible alternative.
   - Verifiability: how will the implemented code be verified against this plan? Name the test, the type check, or the manual check. If "manual eyeball" is the answer, the plan is incomplete.
5. Break the chosen approach into phased steps. Each step is independently committable and leaves the codebase in a working state.
6. Identify the test strategy per step.
7. Identify rollback: if step N fails in production, what is the revert path.

## Output

Write a plan to `~/.claude/scratch/plan-<project-name>-<task-slug>-<YYYYMMDD-HHMM>.md`:

- `plan-shape: mechanical | substantive` field at the top of the plan artifact, before "Goal".
- Goal (one sentence)
- Non-goals (what this change explicitly does not do)
- Chosen approach and rationale
- Rejected alternatives (one line each, why rejected) -- omit for mechanical plans
- Phased steps. Each step: files touched, behavior change, test, commit message shape
- Design integrity notes (one or two sentences per item from step 4a)
- Risks and mitigations
- Open questions for the user (omit if none, including for mechanical plans where there usually are none)

Print the path. Do not implement.

## Stop

Present the plan and wait for approval, changes, or rejection. Do not move to implement.
