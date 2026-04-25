---
description: Add or update tests for recent implementation work, then run them
argument-hint: <optional: file or area to focus on>
allowed-tools: Read, Edit, Write, Grep, Glob, Bash($HOME/.claude/bin/detect-stack.sh), Bash(git diff:*), Bash(git status:*), Bash(npm test*), Bash(pnpm test*), Bash(yarn test*), Bash(vitest *), Bash(jest *), Bash(pytest *), Bash($HOME/.claude/bin/project-name.sh)
---

**Effort: medium.** Matches existing test style. Does not design new testing infrastructure.

## Procedure

1. Run `!`$HOME/.claude/bin/detect-stack.sh`` to identify test runner and language. Get the project name: `!`$HOME/.claude/bin/project-name.sh``.
2. Load the test-patterns skill.
3. Identify what changed via `git diff HEAD` and `git status`. Scope testing to the delta.
4. For each changed function, component, or endpoint:
   - Check if tests already exist. If yes, read them and extend.
   - If no, create a new test file mirroring source path.
5. Write tests that verify behavior, not implementation. Cover:
   - Happy path
   - At least one negative or edge case per public surface
   - Boundary conditions specific to the change (null, empty, max, etc.)
6. Run the new tests narrowly first (single file). Then run the adjacent test suite (module or package).
7. If tests fail:
   - If the test is wrong, fix the test
   - If the implementation is wrong, stop and report. Do not silently change implementation
8. Report results. Include pass count, fail count, and coverage delta if measurable.

## Rules

- Do not write tests for things the test-patterns skill says are not worth testing (trivial getters, framework defaults, pass-throughs).
- Do not introduce a new test framework. Use what the project already uses.
- No snapshot tests unless the project already has them and the snapshot is small and stable.

## Output

Terminal only:

- Files added or modified
- Test count delta
- Run result
- Coverage delta, if measured

No scratch report for routine test passes. If something structurally wrong is found while testing (e.g. a function is untestable without refactor), write a short note to `~/.claude/scratch/test-findings-<project-name>-<YYYYMMDD-HHMM>.md`.
