---
name: test-patterns
description: Testing conventions covering test design, fixtures, mocking, query priority, async handling, behavior-vs-implementation tests, boundary coverage, and what to skip. Use whenever the project contains test config files (e.g. `vitest.config.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini`, `conftest.py`) or test directories (`tests/`, `__tests__/`, `spec/`), OR the user asks about tests, testing, unit tests, integration tests, e2e tests, mocking, fixtures, coverage, test failures, or extending test coverage in any stack, even if a specific framework is not mentioned by name.
---

# Test patterns

Apply the runner-specific reference matching the detected test runner. Principles apply to all stacks.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                                     | Covers                                                                            |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| [reference/principles.md](reference/principles.md)                       | Test design principles + Test Pyramid (Fowler) vs Testing Trophy (Dodds)          |
| [reference/vitest-and-jest.md](reference/vitest-and-jest.md)             | Shared Jest / Vitest patterns, runner choice, MSW for HTTP mocking                |
| [reference/react-testing-library.md](reference/react-testing-library.md) | Query priority, full priority order, `getBy` vs `queryBy` vs `findBy` semantics   |
| [reference/playwright.md](reference/playwright.md)                       | Playwright patterns, page object, property-based testing (fast-check, hypothesis) |
| [reference/pytest.md](reference/pytest.md)                               | pytest fixtures, parametrize, pytest-django                                       |
| [reference/coverage-and-skip.md](reference/coverage-and-skip.md)         | Coverage discipline, what to skip, output expectations                            |

## When to load this skill

- Project contains test config (`vitest.config.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini`, `conftest.py`) or test directories (`tests/`, `__tests__/`, `spec/`).
- User asks about tests, testing, unit / integration / e2e tests, mocking, fixtures, coverage, or test failures.
- Adding or extending tests in any stack.

## When not to load this skill

- Pure refactor with existing test coverage and no test changes needed.
- One-off scripts with no testable surface.

## References

- Vitest: https://vitest.dev/
- Jest: https://jestjs.io/
- React Testing Library: https://testing-library.com/docs/react-testing-library/intro/
- Testing Library guiding principles: https://testing-library.com/docs/guiding-principles/
- Playwright: https://playwright.dev/
- pytest: https://docs.pytest.org/en/stable/
- pytest-django: https://pytest-django.readthedocs.io/
- Kent C. Dodds (Testing Trophy): https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications
- Martin Fowler (Test Pyramid): https://martinfowler.com/articles/practical-test-pyramid.html
- MSW: https://mswjs.io/
- fast-check: https://github.com/dubzzz/fast-check
- hypothesis: https://hypothesis.readthedocs.io/en/latest/

## Maintenance note

Test runner choices shift on a multi-year cycle. Reconcile against current Vitest, Jest, Playwright, pytest releases when the project uses an older config. Property-based and HTTP-mocking choices (fast-check, hypothesis, MSW) have been stable for several years; verify they remain maintained at major version bumps.
