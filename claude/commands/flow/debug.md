---
description: Investigate unexpected behavior without a clear failing signal
argument-hint: <what is wrong and where, plus any reproduction steps you already have>
model: opus
effort: high
---

## When to use this

Unexpected behavior where you do not yet have a failing test, type error, or clear error message to hand to `/flow:fix`. The goal is to identify root cause and produce a handoff artifact. This command does not fix anything.

Use `/flow:fix` instead when you already have a failing signal and know roughly which file is responsible.
Use `/flow:plan` instead when root cause is already understood but the fix is structural.

## Procedure

1. Read $ARGUMENTS. Extract: observed behavior, expected behavior, entry point (route, function, event), any reproduction steps already known. If the observed vs expected distinction is absent, stop and ask before proceeding.

2. Reproduce. Run the narrowest command or interaction that triggers the behavior. Confirm it reproduces consistently. If it does not reproduce, note flakiness and attempt 3 times before concluding non-deterministic.

3. Check recent history in the area. Run `git log -10 --oneline -- <affected paths>`. If a recent commit aligns with when the behavior started, note it as the prime suspect.

4. Trace the code path. From the entry point, follow the execution path to where the observed behavior diverges from expected. Read files on the path; stop reading when the path exits the repo (library boundary, external API). Cap at 10 files.

5. State the first hypothesis in one sentence before checking it: "The bug is caused by X in file Y at line Z."

6. Test the hypothesis with the least invasive probe available, in order of preference:
   - Read the code more carefully: check the edge case implied by the hypothesis.
   - Run an existing test that exercises the path.
   - Use `git bisect` if the bug is a regression and the history is clean enough to bisect.
   - Add a single, targeted log line or assertion and re-run the reproducer.

7. If the hypothesis is confirmed, skip to Output. If it is wrong, form a revised hypothesis and repeat from step 6. Cap at 3 hypothesis cycles. If 3 cycles exhaust without convergence, stop and report what was ruled out.

## Stop conditions

- Root cause identified: document and stop. Do not proceed to fix.
- 3 hypothesis cycles without convergence: surface what was ruled out and ask the user to provide more context (logs, environment details, a more targeted reproducer).
- Bug is in a dependency or external system: document the boundary and stop.
- Investigation scope is growing beyond the stated entry point: surface and ask before expanding.

## Output

Write a debug report to `~/.claude/scratch/debug-<project-name>-<scope-slug>-<YYYYMMDD-HHMM>.md` using this structure:

```
# Debug: <one-line description>

Generated: <ISO timestamp>
Scope: <entry point / affected area>

## Observed vs expected

<one or two sentences>

## Reproduction

<exact command or steps; "not reproduced" if flaky>

## Code path

<list of files read and what each revealed>

## Hypotheses

1. <hypothesis> -> <result: confirmed / ruled out / inconclusive>
2. ...

## Root cause

<one paragraph, or "not found - see Blocked section">

## Blocked

<what additional context is needed, if root cause not found>

## Proposed next step

<"hand off to /flow:fix: <one-line fix description>" or "hand off to /flow:plan: <one-line scope">
```

Print the absolute path. Terminal output: the root cause sentence and the proposed next step only. Everything else goes in the file.
