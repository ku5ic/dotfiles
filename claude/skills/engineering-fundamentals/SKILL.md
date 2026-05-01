---
name: engineering-fundamentals
description: Engineering fundamentals reference covering requirements clarity, design integrity, code-level quality, test design, verification and validation, and metric thresholds. Foundation skill that loads alongside language and framework skills for any engineering work, including review, audit, plan, implementation, refactor, or code quality assessment, even if the user does not mention "principles", "SOLID", "DRY", "KISS", or "metrics" explicitly. The /flow:* and /audit:* commands enforce these checks as deterministic phase gates; this skill is the always-available reference that those commands defer to.
---

# Engineering fundamentals

Foundation reference for engineering work. Loads alongside language and framework skills for any review, audit, plan, implementation, refactor, or code quality task.

The `/flow:*` and `/audit:*` commands enforce these checks as deterministic phase gates at the right moment. When inside one of those commands, defer to the command's enforcement and apply only the sections relevant to ad-hoc questions that arise during execution. When outside any command, apply this checklist as the primary engineering quality reference.

Severity rubric matches `markdown-report`: `failure`, `warning`, `info`. Cite the rubric on findings; do not invent new levels.

## When to apply each section

| Activity                            | Sections to apply                                         |
| ----------------------------------- | --------------------------------------------------------- |
| Reviewing someone else's PR or diff | Code-level integrity, Test design, Metric thresholds, V&V |
| Planning a change ad-hoc            | Requirements clarity, Design integrity                    |
| Writing code without a plan         | Code-level integrity                                      |
| Triaging a "this feels wrong" hunch | Metric thresholds, V&V                                    |
| Sanity-checking docs or specs       | Requirements clarity                                      |

Apply only what fits. Do not pad findings to fill sections.

## Requirements clarity

Before any non-trivial implementation, the request must satisfy:

- **Testable.** Pass or fail is observable without ambiguity. "Improve performance" without a measurable signal fails this.
- **Unambiguous.** One reasonable interpretation only. Words like "should also handle X if needed" or "be flexible" fail this.
- **Complete.** Inputs, outputs, and error cases are stated or directly inferable from the codebase. Happy-path-only specs fail this.
- **Consistent.** Does not contradict project `CLAUDE.md`, existing tests, or recent commit history.

If any of the four flag, surface the gap and ask one focused clarifying question. Do not infer requirements silently.

## Design integrity

Applies when planning a change, evaluating an architecture, or reviewing a design doc. For each, the answer must be a concrete sentence, not yes/no.

- **Modularity.** Which module owns this change? If the change crosses module boundaries, name them and justify.
- **Abstraction level.** Does any caller need to know an implementation detail to use the new code? If yes, abstraction is wrong.
- **Separation of concerns.** Does any function or component combine independently changing concerns (data fetching + presentation, validation + persistence)? If yes, split or justify.
- **KISS.** Is the simplest sufficient solution chosen? Name any non-obvious complexity and why it earns its place.
- **DRY judgment.** If duplication exists, is it along a stable axis or a divergent one? Duplication with divergent lifecycles is correct, not a violation.
- **Reversibility.** If this proves wrong after merge, what is the cost to reverse? If high, justify the choice over a more reversible alternative.
- **Verifiability.** How will the implemented code be verified? Name the test, type check, or manual check. "Manual eyeball" means the design is incomplete.

## Code-level integrity

Applies per file, per function, during implementation or review.

- **Cohesion.** A function does one thing. If the name needs an "and", split.
- **Coupling.** A new module depends on the fewest concrete other modules possible. More than five non-stdlib imports in a new file: justify.
- **Naming.** Names describe what, not how. `processItems` is weak; `validatePaymentBatch` is concrete.
- **Magic values.** Literals beyond `0`, `1`, `-1`, `""`, and obvious enums get a named constant with a comment explaining the value.
- **Single source of truth.** Data lives in one place. Two stores being kept in sync is a smell.
- **Comments.** Explain why, not what. Remove comments that paraphrase the next line.
- **Error handling.** Each error path is intentional. Bare catches that swallow are `failure`. `try/finally` without `catch` is fine when cleanup is the goal.

## Test design

Applies to tests just written, tests being reviewed, or test coverage being evaluated.

- **Behavior, not implementation.** Would the test still pass after a refactor that preserves behavior? Tests that read internal state or assert on call counts of internal helpers are testing implementation.
- **Boundary coverage.** For inputs with a range, edge values are tested: zero, one, max, max+1, empty, null where allowed.
- **Equivalence partitioning.** Distinct input classes have at least one test each: valid, invalid, edge, error path.
- **Negative cases.** At least one test per public surface verifies failure mode (invalid input rejected, error raised, expected exception type).
- **Independence.** Tests do not depend on order; each sets up and tears down its own state.
- **Determinism.** No time, random, or network without explicit control. Intermittent CI failure means broken, not flaky.
- **Worth testing.** Pass-through wrappers, trivial getters, and framework defaults are not worth testing. Coverage of these is noise.

## Verification and validation

Applies during review or post-implementation reflection.

- **Verification (building it right).** Does the code implement what the plan or spec said? If the plan moved while implementing, was the plan updated? Drift between plan and code is `warning`.
- **Validation (building the right thing).** Does the change actually solve the underlying problem? A change that is technically correct but misses the user's actual need fails validation, regardless of how clean the code is.
- **Traceability.** Can each behavior change be traced to a line in the spec, plan, or ticket? Behavior in code without a corresponding requirement is a `warning`; surface it.

## Metric thresholds

Statically inferable smells. None are hard limits; each is a signal that compounds with other findings.

- **Function size:** over 50 lines without a clear cohesive reason. `warning`.
- **Cyclomatic complexity:** nested conditionals deeper than 3, or more than 7 distinct branches in one function. `warning`.
- **Coupling:** a module with more than ~10 internal imports, or a class with more than 7 public methods. `warning`.
- **Cohesion:** a class or module whose methods operate on disjoint subsets of fields suggests two responsibilities. `warning`.
- **File size:** over 500 lines is a candidate for split unless genuinely cohesive (single config, single component with tight internal cohesion).

These compound. A 60-line function with cyclomatic complexity 9 inside a 700-line file is one finding, not three.

## Anti-patterns to flag

- "It works, ship it" without verifiability check
- "We can refactor later" applied to architecture, not just code
- Requirements inferred from code rather than stated
- Tests written to confirm the implementation, not the behavior
- Metric thresholds dismissed without examining whether they compound
- "DRY" applied to coincidentally similar code with divergent lifecycles
- "KISS" used to justify skipping necessary abstractions
- "SOLID" cited without naming which principle and how

## What this skill does not do

- Replace `/flow:*` or `/audit:*` enforcement. Those are deterministic. This is a fallback.
- Substitute for stack-specific skills. Stack-specific patterns load independently when project signals match.
- Provide implementation patterns. This is principles only.

## References

These checklists distill widely accepted software engineering practice. For deeper background:

- Modularity, abstraction, separation of concerns: Parnas (1972), "On the Criteria To Be Used in Decomposing Systems into Modules"
- Cyclomatic complexity: McCabe (1976)
- Cohesion and coupling: Stevens, Myers, Constantine (1974)
- V&V distinction: Boehm (1981)
- Test design (boundary, equivalence): Myers, "The Art of Software Testing"

Citations are for context. Do not require Claude to read source material; the checklists above are the operational version.
