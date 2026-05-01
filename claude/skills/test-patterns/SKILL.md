---
name: test-patterns
description: Testing conventions covering test design, fixtures, mocking, query priority, async handling, behavior-vs-implementation tests, boundary coverage, and what to skip. Use whenever the project contains test config files (e.g. `vitest.config.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini`, `conftest.py`) or test directories (`tests/`, `__tests__/`, `spec/`), OR the user asks about tests, testing, unit tests, integration tests, e2e tests, mocking, fixtures, coverage, test failures, or extending test coverage in any stack, even if a specific framework is not mentioned by name.
---

# Test patterns

Apply the section that matches the detected test runner.

## Principles (all stacks)

- Test behavior, not implementation. If refactoring internals breaks the test, the test is too coupled.
- One clear assertion per test where possible. Multiple related assertions are fine; sprawling assertions are not.
- Arrange, act, assert. Visible in the test structure.
- Fixtures over factories over repetition. Extract when used three or more times.
- Name tests as full sentences describing the expected behavior, not the method under test.
- Flaky tests are failures. Fix or delete, never retry loop.

## Vitest and Jest (shared patterns)

- Use `describe` for the unit, `it` for each behavior. Keep nesting to 2 levels max.
- Mock at the module boundary, not inside the unit under test. Prefer dependency injection.
- Avoid `beforeEach` state unless truly shared. Explicit setup per test reads better.
- `toBe` for primitives, `toEqual` for structures, `toStrictEqual` when undefined vs missing matters.
- Async: return the promise or use `async/await`. No `.then` chains.
- Snapshots only for stable, meaningful output. Not for DOM trees (use Testing Library queries instead).

## React Testing Library

- Query priority: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId` (last resort).
- `userEvent` over `fireEvent`. Always `await user.click(...)`.
- Do not query by class name or CSS selector.
- `waitFor` around async assertions only. Do not wrap synchronous assertions.
- `findBy*` returns a promise, use for async elements. Do not combine with `waitFor`.
- No shallow rendering. Render components fully.

Accessibility check built into tests: if you cannot find an element by role or label, the component likely has an accessibility issue worth fixing, not working around.

## Playwright

- `page.getByRole` mirrors RTL conventions. Prefer role and label selectors.
- Wait for network idle is an anti pattern. Wait for the thing you actually need (a request, a visible element).
- Page object pattern for flows used in three or more tests.
- Use `test.step` to annotate long flows for better failure traces.
- One browser context per test. Do not share state.

## pytest (Django and general Python)

- File layout: mirror source layout under `tests/`. One test module per source module.
- Fixtures in `conftest.py` at the appropriate scope. Prefer function scope unless setup is expensive.
- Parametrize with `@pytest.mark.parametrize` for table tests. Include an `id` for readability on failure.
- Django: use `pytest-django`, `@pytest.mark.django_db` only when DB needed. Prefer `--no-migrations` in CI if migrations are settled.
- Factory Boy for model fixtures when the same model is used in many tests.
- Avoid `unittest.TestCase` subclasses in a pytest codebase. Pick one style.

## Coverage

- Coverage is a signal, not a goal. 100% on generated code is meaningless. Focus on core logic and branching.
- Flag uncovered branches in code that contains business rules, auth, or payment flows.

## What to skip as not worth testing

- Direct pass-through wrappers around library calls with no logic.
- Trivial getters and setters.
- Framework defaults (e.g. testing that React re-renders on state change).

## Output when adding tests

- New test file mirrors source path.
- Each test describes behavior, not function.
- Include at least one negative case per public function if it has validation.
- Run the new tests before finishing. Report pass, fail, and coverage delta if measurable.
