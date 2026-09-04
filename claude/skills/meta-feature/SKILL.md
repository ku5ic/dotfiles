---
description: Shape a fuzzy feature request into a structured brief before planning
argument-hint: <feature description or ticket text>
disable-model-invocation: true
context: fork
---

## When to use

- A ticket or request arrives fuzzy or ambiguous
- You want to shape scope before committing engineering effort
- You need to hand a brief to a teammate or back to the requester
- You want to think through a feature before writing any code

## Procedure

1. Run `!`detect-stack.sh`` for context. Some features make sense in one stack and not another.
2. Get the scratch directory: `!`scratch-dir.sh``.
3. Read $ARGUMENTS. If it points to a ticket file or URL string, read the file. Otherwise treat as the request.
4. Read project CLAUDE.md and any architecture docs.
5. Verify before writing. For any file path, module, or existing pattern that will land in Problem, Constraints, or Proposed approach:
   1. Confirm it exists.
   2. Read directly when it is a couple of files.
   3. Delegate to the scout agent when the request references code or architecture spanning more than a couple of files.
   4. Anything unconfirmed stays "unknown, ask requester" per the existing convention, never asserted.
6. Work through the questions below in order. Write the brief as you go. It is fine for a section to end with "unknown, ask requester" rather than a fabricated answer.

## Output

Write to `$(scratch-dir.sh)/feature-<slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Structure:

```
# Feature brief: <title>

## Problem

<Who has a problem, what problem, what is the current workaround if any. If the request describes a solution, extract the underlying problem.>

## Goal

<One sentence. The outcome, not the implementation.>

## Non-goals

<What this explicitly does not address. Protect scope.>

## Users and scenarios

<Who uses this, in what situation. Concrete if possible.>

## Acceptance criteria

<List. Observable behavior, not implementation. Each item is independently verifiable.>

## Constraints

<Stack, data, compliance, performance, accessibility, timeline. Skip sections that do not apply.>

## Risks and uncertainties

<What could go wrong. What we do not know yet. What depends on external answers.>

## Proposed approach (high level)

<One or two sentences on the shape of the solution. Leave detail to /flow-plan. This is not the plan.>

## Decisions

<Questions that came up for the requester or stakeholder, and the answer picked. Resolved via the AskUserQuestion tool before this brief was finalized, not left open.>
```

## Rules

- Do not plan. Do not break into steps. That is `/flow-plan`.
- Do not estimate unless asked. Briefs shape work, they do not size it.
- If the brief is under-specified and cannot be shaped without more input: ask via the AskUserQuestion tool (multiple-choice, "Other" for free text) before finalizing, then write what is known plus the resolved answers in "Decisions". Better to ask than to fabricate a straw man. If forked, follow CLAUDE.md's forked decision protocol instead of guessing.
- If the feature conflicts with an architectural constraint in CLAUDE.md: flag it in "Risks and uncertainties" before proposing an approach.
- Do not name a file path, module, or pattern in the output unless confirmed this session via Read/Grep/fd or scout; unconfirmed items stay "unknown, ask requester".
