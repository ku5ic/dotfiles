# Coverage, what to skip, and output

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
