---
description: Shape a fuzzy feature request into a structured brief before planning
argument-hint: <feature description or ticket text>
allowed-tools: Read, Grep, Glob, Bash($HOME/.claude/bin/detect-stack.sh), Bash($HOME/.claude/bin/project-name.sh)
---

**Effort: heavy.** Thinking-heavy. One step before `/flow:plan`. Produces a brief, not a plan.

## When to use

- A ticket or request arrives fuzzy or ambiguous
- You want to shape scope before committing engineering effort
- You need to hand a brief to a teammate or back to the requester
- You want to think through a feature before writing any code

## Procedure

1. Run `!`$HOME/.claude/bin/detect-stack.sh`` for context. Get the project name: `!`$HOME/.claude/bin/project-name.sh``. Some features make sense in one stack and not another.
2. Read $ARGUMENTS. If it points to a ticket file or URL string, read the file. Otherwise treat as the request.
3. Read project CLAUDE.md and any architecture docs.
4. Work through the questions below in order. Write the brief as you go. It is fine for a section to end with "unknown, ask requester" rather than a fabricated answer.

## Output

Write to `~/.claude/scratch/feature-<project-name>-<slug>-<YYYYMMDD-HHMM>.md`. Print the path.

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

<One or two sentences on the shape of the solution. Leave detail to /flow:plan. This is not the plan.>

## Open questions

<Questions for the requester or stakeholder. Blocking vs non-blocking flagged.>
```

## Rules

- Do not plan. Do not break into steps. That is `/flow:plan`.
- Do not estimate unless asked. Briefs shape work, they do not size it.
- If the brief is under-specified and cannot be shaped without more input: write what is known, list open questions, and stop. Better to ask than to fabricate a straw man.
- If the feature conflicts with an architectural constraint in CLAUDE.md: flag it in "Risks and uncertainties" before proposing an approach.
