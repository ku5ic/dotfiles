---
description: Surgical fix from a failing signal (test, type error, runtime error, lint)
argument-hint: <error message, file path, or test name>
allowed-tools: Read, Edit, MultiEdit, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(npm:test*), Bash(pnpm:test*), Bash(yarn:test*), Bash(vitest:*), Bash(jest:*), Bash(pytest:*), Bash(cargo:test*), Bash(go:test*), Bash(bundle:exec *)
---

**Effort: medium.** Find the bug, fix it, verify. Do not refactor.

## Procedure

1. Read $ARGUMENTS. Identify: file, line, expected vs actual.
2. Reproduce the failure with the narrowest possible command (single test, single file). Confirm the failure mode matches the report.
3. Read the failing code and its callers (not the whole module). Form a hypothesis.
4. State the hypothesis in one sentence before changing anything.
5. Make the smallest change that addresses the root cause, not the symptom.
6. Re-run the narrow command. If green, run adjacent tests.
7. If still red, revise hypothesis. Do not pile on changes.

## Stop conditions

- The hypothesis requires a refactor. Stop and propose a separate `flow:plan`.
- The fix touches more than 3 files. Stop and surface; this is no longer a fix.
- The fix changes a public API. Stop; this needs a plan.

## Output

Terminal only:

- Hypothesis
- Files changed
- Verification command run and result
