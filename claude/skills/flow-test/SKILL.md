---
description: Add or update tests for recent implementation work, then run them
argument-hint: <optional: file or area to focus on, or a link to an external tracker/doc>
disable-model-invocation: true
---

## Procedure

0. Resolve external context. If $ARGUMENTS contains a URL with little or no inline description, resolve it before anything else: identify which connected service the URL belongs to from its domain, use ToolSearch to find a matching fetch/read tool for that service (e.g. a URL under `app.clickup.com` points at the clickup tools, `notion.so` at the Notion tools, `github.com` at `gh` via Bash or the github tools), and call it to pull the content. Extract the relevant scope and requirements from what comes back. Treat the resolved text as the effective $ARGUMENTS for the rest of this procedure - never hand a bare link to the tester agent.

Delegate the procedure below (steps 1 onward, through Stop) to the tester agent (Agent tool, subagent_type: tester, foreground), passing the resolved arguments from step 0. It executes every step itself and reports results; relay its returned summary.

1. Get the scratch directory via `scratch-dir.sh`. Identify the test runner from the repo context your startup produced (`agent-context.sh`).
2. Load the `test-patterns` skill and the patterns skill matching the detected stack (`react-patterns`, `django-patterns`, etc.) when relevant to the change.
3. Identify what changed via `git diff HEAD` and `git status`. Scope testing to the delta.
4. For each changed function, component, or endpoint:
   - Check if tests already exist. If yes, read them and extend.
   - If no, create a new test file mirroring source path.
5. Scale test depth to criticality before writing anything. Business rules, auth, payment, and security boundaries get the full coverage below. A thin wrapper, a single-caller internal helper, or straightforward display logic gets a happy-path test only - stop there, do not apply the rest of this checklist for its own sake. For anything above that bar, write tests that verify behavior, not implementation, and cover:
   - Happy path
   - At least one negative or edge case per public surface
   - Boundary conditions specific to the change (null, empty, max, etc.)
6. Test design check. For the tests just written, verify each:
   - Behavior, not implementation: would the test still pass after a refactor that preserves behavior? If a test reads internal state or asserts on call counts of internal helpers, it is testing implementation.
   - Boundary coverage: for any input with a range, edge values are tested (zero, one, max, max+1, empty, null where allowed).
   - Equivalence partitioning: distinct input classes have at least one test each (valid input, invalid input, edge case, error path).
   - Negative cases: at least one test per public surface verifies failure mode (invalid input rejected, error raised, expected exception type).
   - Independence: tests do not depend on order; each sets up and tears down its own state.
   - Determinism: no time, random, or network without explicit control. If the test fails intermittently in CI, it is broken.

   If any test fails this check, fix the test. Do not proceed to step 6 with shape-checking tests masquerading as behavior tests.

7. Run the new tests narrowly first (single file). Then run the adjacent test suite (module or package).
8. If tests fail:
   - If the test is wrong, fix the test
   - If the implementation is wrong, stop and report. Do not silently change implementation
9. Report results. Include pass count, fail count, and coverage delta if measurable.

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

No scratch report for routine test passes. If something structurally wrong is found while testing (e.g. a function is untestable without refactor), write a short note to `$(scratch-dir.sh)/test-findings-<YYYYMMDD-HHMM>.md`.

## Stop

Stop after reporting results. Do not commit. Do not move to /flow-review unless asked.
