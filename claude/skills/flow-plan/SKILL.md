---
description: Turn a confirmed task into an ordered implementation plan with explicit tradeoffs
argument-hint: <task description or link to preflight report>
model: opus
effort: high
disable-model-invocation: true
---

## Prerequisites

- A preflight report exists in `~/.claude/scratch/`. If not, run `/flow-preflight` first.
- The task is stated clearly. If $ARGUMENTS is vague, ask one focused clarifying question before planning.

## Procedure

1. Get the project name: `!`project-name.sh``. Read the most recent preflight report for this project: `ls -t ~/.claude/scratch/preflight-<project-name>-\*.md | head -1`. If none exists for this project, run /flow-preflight first.
2. Load the patterns skill matching the detected stack (react-patterns, django-patterns, etc.) if the task is in that area.
   - You may delegate noisy sub-work (broad code exploration, running checks) to the scout or checker agent to keep this context clean, but every phase-boundary stop stays in the main conversation.
3. Determine plan shape. If $ARGUMENTS contains "mechanical:" or "plan-shape: mechanical", the plan is mechanical: skip steps 4 and 6 below (no rejected alternatives, no per-step test strategy beyond a single end verification). If the work is clearly mechanical from the preflight (pure file edits, no architectural choice), the agent may self-mark mechanical, stating the reason. Otherwise the plan is substantive (default). Self-marking mechanical is opt-in by signal: state why the plan is mechanical so the user can override. `--full` in $ARGUMENTS forces a substantive plan even when the work looks mechanical.
4. Consider two implementation approaches. For each: scope, risk, effort, reversibility, and fit with this project's own existing convention (CLAUDE.md, loaded pattern skills, precedent elsewhere in the codebase) - not generic best practice. An approach that only wins by diverging from established convention needs that divergence named and justified before it can be chosen; if the other approach is otherwise comparable, prefer the convention-aligned one. Pick one and justify why. If both score similarly on every other axis, pick the approach that touches fewer layers.
   4a. Design integrity check on the chosen approach. For each item, the answer must be a concrete sentence in the plan, not a yes/no:
   - Modularity: which module owns this change? If the change crosses module boundaries, name them and justify.
   - Abstraction level: is the new code at the right level of abstraction for its callers? Concretely: does any caller need to know an implementation detail to use it?
   - Separation of concerns: does any new function or component combine independently changing concerns (data fetching + presentation, validation + persistence, etc.)? If yes, split or justify the merge.
   - KISS: is the simplest sufficient solution being chosen? Name any non-obvious complexity and why it earns its place.
   - DRY judgment: if this introduces apparent duplication, is the duplication along a stable axis or a divergent one? Duplication with divergent lifecycles is correct.
   - Reversibility: if this approach proves wrong after merge, what is the cost to reverse? If high, justify the choice over a more reversible alternative.
   - Verifiability: how will the implemented code be verified against this plan? Name the test, the type check, or the manual check. If "manual eyeball" is the answer, the plan is incomplete.
   - Convention fit: does the chosen approach match how this codebase already solves this class of problem? Cite the precedent. If it diverges, name the divergence and justify it - an unnamed divergence is not acceptable in the plan.
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
- Decisions: any open question ask via the AskUserQuestion tool (multiple-choice, "Other" for free text) before writing this plan, then record the resolved answer here (omit if none, including for mechanical plans where there usually are none)

Print the path. Do not implement.

## Critique

Skip this step when `plan-shape: mechanical`. Otherwise, dispatch the `plan-critic` agent (Agent tool, subagent_type: plan-critic, foreground) with the plan's absolute path. It reads the codebase, not only the plan, and reports findings against the plan's cited precedent, its design-integrity answers, verifiability, phase independence, non-goals, rollback, and unstated assumptions. Do not act on its findings by revising the plan yourself -- present the plan and the critique together, unmodified, at the Stop below.

## Stop

Present the plan (and its critique, unless skipped for a mechanical plan) and wait for approval, changes, or rejection. Do not move to implement.
