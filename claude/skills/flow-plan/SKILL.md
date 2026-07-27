---
description: Ground a task in the codebase, then turn it into an ordered implementation plan with explicit tradeoffs
argument-hint: <task description>
model: opus
disable-model-invocation: true
---

## Prerequisites

- The task is stated clearly. If $ARGUMENTS is vague, ask one focused clarifying question before anything else.

## Procedure

Steps 1-4 are the grounding phase; steps 5-10 are the planning phase. Keep this context lean: delegate broad code exploration and check-running to the scout or checker agent, but every phase-boundary stop stays in the main conversation.

1. Get the scratch directory: `!`scratch-dir.sh``. Stack is in the injected `<repo-context>` block. Persist the task's verbatim source: if a matching brief already exists (`ls -t "$(scratch-dir.sh)"/brief-\*.md "$(scratch-dir.sh)"/feature-\*.md 2>/dev/null | head -1`), read it. Otherwise write $ARGUMENTS byte-for-byte, including any embedded code, scripts, or replacement text blocks, to `$(scratch-dir.sh)/brief-<slug>-<YYYYMMDD-HHMM>.md` - this file is the durable source of truth for anything the task gives verbatim; conversation context can compact away, this file cannot. If $ARGUMENTS is empty because the task was only stated in prior conversation, write the fullest verbatim restatement available and say plainly in the file that it is a reconstruction, not the original. Print the brief path.
2. Ground in the project. Read `CLAUDE.md` at the project root in full, plus any `CLAUDE.md` on the path to the target area. Read the README only if its headings explicitly cover the task area. Check `git status` and `git log -5 --oneline`; note uncommitted work and recent direction. Identify the CI checks the project defines (scripts in `package.json`, `Makefile`, `pyproject.toml` `[tool]` sections) - list what exists and what is missing entirely, without running anything.
3. Requirements clarity gate. Evaluate the task statement against: Testable (can pass/fail be observed without ambiguity?), Unambiguous (only one reasonable interpretation?), Complete (inputs, outputs, and error cases stated or inferable?), Consistent (no contradiction with CLAUDE.md, existing tests, or recent history?). If any of the four flags, stop and ask via the AskUserQuestion tool before proceeding. Do not infer requirements; surface the gap.
4. Identify the minimum file set the task touches: the files that will change, plus the files those files import or depend on. Read them. Budget: at most 12 files across steps 2-4; if the minimum set exceeds 12, stop and ask the user to scope the task. Delegate anything broader than the minimum set to the scout agent rather than reading it here. Run `tokei` once at the project root for size context (does not count toward the budget).
5. Load the patterns skill matching the detected stack (react-patterns, django-patterns, etc.) if the task is in that area.
6. Determine plan shape. If $ARGUMENTS contains "mechanical:" or "plan-shape: mechanical", the plan is mechanical: skip steps 7 and 9 below (no rejected alternatives, no per-step test strategy beyond a single end verification). If the work is clearly mechanical from the grounding phase (pure file edits, no architectural choice), the agent may self-mark mechanical, stating the reason so the user can override. `--full` in $ARGUMENTS forces a substantive plan even when the work looks mechanical.
7. Consider two implementation approaches. For each: scope, risk, effort, reversibility, and fit with this project's own existing convention (CLAUDE.md, loaded pattern skills, precedent elsewhere in the codebase) - not generic best practice. An approach that only wins by diverging from established convention needs that divergence named and justified before it can be chosen; if the other approach is otherwise comparable, prefer the convention-aligned one. Pick one and justify why. If both score similarly on every other axis, pick the approach that touches fewer layers.
   7a. Design integrity check on the chosen approach. For each item, the answer must be a concrete sentence in the plan, not a yes/no:
   - Modularity: which module owns this change? If the change crosses module boundaries, name them and justify.
   - Abstraction level: is the new code at the right level of abstraction for its callers? Concretely: does any caller need to know an implementation detail to use it?
   - Separation of concerns: does any new function or component combine independently changing concerns (data fetching + presentation, validation + persistence, etc.)? If yes, split or justify the merge.
   - KISS: is the simplest sufficient solution being chosen? Name any non-obvious complexity and why it earns its place.
   - DRY judgment: if this introduces apparent duplication, is the duplication along a stable axis or a divergent one? Duplication with divergent lifecycles is correct.
   - Reversibility: if this approach proves wrong after merge, what is the cost to reverse? If high, justify the choice over a more reversible alternative.
   - Verifiability: how will the implemented code be verified against this plan? Name the test, the type check, or the manual check. If "manual eyeball" is the answer, the plan is incomplete.
   - Convention fit: does the chosen approach match how this codebase already solves this class of problem? Cite the precedent. If it diverges, name the divergence and justify it - an unnamed divergence is not acceptable in the plan.
8. Break the chosen approach into phased steps. Each step is independently committable and leaves the codebase in a working state. If a step writes or replaces a file with content the task or brief gives verbatim (a script, an exact text block, a full-file replacement), inline that verbatim content directly in the plan artifact under that step - do not merely name or reference it. `/flow-implement` reads only the plan file, not the brief and not this conversation; a step that says "write payload X verbatim" without the actual bytes of payload X present in the plan is not implementable once this conversation's context has moved on.
9. Identify the test strategy per step.
10. Identify rollback: if step N fails in production, what is the revert path.

## Output

Write a plan to `$(scratch-dir.sh)/plan-<task-slug>-<YYYYMMDD-HHMM>.md`:

- `plan-shape: mechanical | substantive` field at the top of the plan artifact, before "Goal".
- Context: stack summary (from `<repo-context>` plus the tokei headline), CI health at plan time (what exists, what is missing), blast radius (files that will change plus their dependents, and which module owns the change).
- Goal (one sentence)
- Non-goals (what this change explicitly does not do)
- Chosen approach and rationale
- Rejected alternatives (one line each, why rejected) -- omit for mechanical plans
- Phased steps. Each step: files touched, behavior change, test, commit message shape. Verbatim content a step depends on is inlined here, not referenced by name.
- Design integrity notes (one or two sentences per item from step 7a)
- Risks and mitigations
- Decisions: any open question ask via the AskUserQuestion tool (multiple-choice, "Other" for free text) before writing this plan, then record the resolved answer here (omit if none, including for mechanical plans where there usually are none)

Print the plan path alongside the brief path from step 1. Do not implement.

## Critique

Skip this step when `plan-shape: mechanical`. Otherwise, dispatch the `plan-critic` agent (Agent tool, subagent_type: plan-critic, foreground) with the plan's absolute path. It reads the codebase, not only the plan, and reports findings against the plan's cited precedent, its design-integrity answers, verifiability, phase independence, non-goals, rollback, and unstated assumptions. Do not act on its findings by revising the plan yourself -- present the plan and the critique together, unmodified, at the Stop below.

## Stop

Present the plan (and its critique, unless skipped for a mechanical plan) and wait for approval, changes, or rejection. Do not move to implement.
