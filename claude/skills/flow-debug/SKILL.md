---
description: Investigate unexpected behavior without a clear failing signal
argument-hint: <what is wrong and where, plus any reproduction steps or a link to an external tracker/doc>
disable-model-invocation: true
---

## When to use this

Unexpected behavior where you do not yet have a failing test, type error, or clear error message to hand to `/flow-fix`. The goal is to identify root cause and produce a handoff artifact. This command does not fix anything.

Use `/flow-fix` instead when you already have a failing signal and know roughly which file is responsible.
Use `/flow-plan` instead when root cause is already understood but the fix is structural.

## Procedure

0. Resolve external context per `rules/external-context.md`, using the debugger agent for lookups. Extract observed behavior, expected behavior, entry point, and repro steps from what comes back. If no connected tool matches the URL's domain, say so and ask for the content pasted inline instead.

1. From the resolved arguments, confirm: observed behavior, expected behavior, entry point (route, function, event), any reproduction steps already known. If the observed vs expected distinction is still absent after step 0, stop and ask before proceeding.

2. Delegate fault localization to the debugger agent (Agent tool, subagent_type: debugger, foreground). Constraint on the caller: the debugger has no MCP tools by design, so its prompt must carry fully resolved plain text - never a link. Prompt: the resolved context plus this procedure for it to follow:
   - Reproduce: run the narrowest command or interaction that triggers the behavior; confirm it reproduces consistently, attempting 3 times before concluding non-deterministic.
   - Check recent history: `git log -10 --oneline -- <affected paths>`; if a recent commit aligns with when the behavior started, note it as the prime suspect.
   - Trace the code path from the entry point to where observed diverges from expected; stop at library/external-API boundaries; cap at 10 files.
   - State the first hypothesis in one sentence before checking it: "The bug is caused by X in file Y at line Z."
   - Test the hypothesis with the least invasive probe available, in order: read the code more carefully, run an existing test that exercises the path, `git bisect` if it's a regression with clean history, then a single targeted log line or assertion reverted after use.
   - If confirmed, stop with the hypothesis. If wrong, revise and repeat, capped at 3 hypothesis cycles; if exhausted, report what was ruled out.

3. Take the debugger's returned root cause, evidence, and proposed fix location and continue to Output below.

## Stop conditions

- Root cause identified: document and stop. Do not proceed to fix.
- 3 hypothesis cycles without convergence: surface what was ruled out and ask the user to provide more context (logs, environment details, a more targeted reproducer).
- Bug is in a dependency or external system: document the boundary and stop.
- Investigation scope is growing beyond the stated entry point: surface and ask before expanding.

## Output

Write a debug report to `$(scratch-dir.sh)/debug-<scope-slug>-<YYYYMMDD-HHMM>.md` using this structure:

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

<"hand off to /flow-fix: <one-line fix description>" or "hand off to /flow-plan: <one-line scope">
```

Print the absolute path. Terminal output: the root cause sentence and the proposed next step only. Everything else goes in the file.
