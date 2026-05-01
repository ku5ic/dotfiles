---
description: Add or update tests for recent implementation work, then run them
argument-hint: <optional: file or area to focus on>
---

**Effort: medium.** Matches existing test style. Does not design new testing infrastructure.

## Procedure

1. Get the project name: `!`project-name.sh``. Identify the test runner from the injected `<repo-context>` block.
2. Load the `test-patterns` skill and the patterns skill matching the detected stack (`react-patterns`, `django-patterns`, etc.) when relevant to the change.
3. Identify what changed via `git diff HEAD` and `git status`. Scope testing to the delta.
4. For each changed function, component, or endpoint:
   - Check if tests already exist. If yes, read them and extend.
   - If no, create a new test file mirroring source path.
5. Write tests that verify behavior, not implementation. Cover:
   - Happy path
   - At least one negative or edge case per public surface
   - Boundary conditions specific to the change (null, empty, max, etc.)
     5a. Test design check. For the tests just written, verify each:
   - Behavior, not implementation: would the test still pass after a refactor that preserves behavior? If a test reads internal state or asserts on call counts of internal helpers, it is testing implementation.
   - Boundary coverage: for any input with a range, edge values are tested (zero, one, max, max+1, empty, null where allowed).
   - Equivalence partitioning: distinct input classes have at least one test each (valid input, invalid input, edge case, error path).
   - Negative cases: at least one test per public surface verifies failure mode (invalid input rejected, error raised, expected exception type).
   - Independence: tests do not depend on order; each sets up and tears down its own state.
   - Determinism: no time, random, or network without explicit control. If the test fails intermittently in CI, it is broken.

   If any test fails this check, fix the test. Do not proceed to step 6 with shape-checking tests masquerading as behavior tests.

6. Run the new tests narrowly first (single file). Then run the adjacent test suite (module or package).
7. If tests fail:
   - If the test is wrong, fix the test
   - If the implementation is wrong, stop and report. Do not silently change implementation
8. Report results. Include pass count, fail count, and coverage delta if measurable.

## Rules

- Do not write tests for things the test-patterns skill says are not worth testing (trivial getters, framework defaults, pass-throughs).
- Do not introduce a new test framework. Use what the project already uses.
- If the project uses snapshot tests, prefer that pattern only when snapshots are small and stable. Do not introduce snapshots if the project does not use them.
- After narrow tests pass, run `run-checks.sh` for full verification across typecheck, lint, and tests.

## Output

Terminal only:

- Files added or modified
- Test count delta
- Run result
- Coverage delta, if measured

No scratch report for routine test passes. If something structurally wrong is found while testing (e.g. a function is untestable without refactor), write a short note to `~/.claude/scratch/test-findings-<project-name>-<YYYYMMDD-HHMM>.md`.

## Stop

Stop after reporting results. Do not commit. Do not move to /flow:review unless asked.
