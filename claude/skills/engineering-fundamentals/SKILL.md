---
name: engineering-fundamentals
description: Engineering fundamentals reference covering requirements clarity, design integrity, code-level quality, test design, verification and validation, and metric thresholds. Foundation skill that loads alongside language and framework skills for any engineering work, including review, audit, plan, implementation, refactor, or code quality assessment, even if the user does not mention "principles", "SOLID", "DRY", "KISS", or "metrics" explicitly. The /flow:* and /audit:* commands enforce these checks as deterministic phase gates; this skill is the always-available reference that those commands defer to.
---

# Engineering fundamentals

Foundation reference for engineering work. Loads alongside language and framework skills for any review, audit, plan, implementation, refactor, or code quality task.

The `/flow:*` and `/audit:*` commands enforce these checks as deterministic phase gates at the right moment. When inside one of those commands, defer to the command's enforcement and apply only the sections relevant to ad-hoc questions that arise during execution. When outside any command, apply this checklist as the primary engineering quality reference.

## Severity rubric

Severity rubric matches `markdown-report`: cite on findings, do not invent new levels.

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## When to apply each section

| Activity                            | Sections to apply                                         |
| ----------------------------------- | --------------------------------------------------------- |
| Reviewing someone else's PR or diff | Code-level integrity, Test design, Metric thresholds, V&V |
| Planning a change ad-hoc            | Requirements clarity, Design integrity                    |
| Writing code without a plan         | Code-level integrity                                      |
| Triaging a "this feels wrong" hunch | Metric thresholds, V&V                                    |
| Sanity-checking docs or specs       | Requirements clarity                                      |

Apply only what fits. Do not pad findings to fill sections.

## Reference files

| File                                                                                 | Covers                                                                                    |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| [reference/requirements-clarity.md](reference/requirements-clarity.md)               | Testable / Unambiguous / Complete / Consistent before non-trivial implementation          |
| [reference/design-integrity.md](reference/design-integrity.md)                       | Modularity, abstraction, KISS, DRY, plus SOLID principles and DRY/KISS attribution        |
| [reference/code-level-integrity.md](reference/code-level-integrity.md)               | Per-file checks plus the Stevens/Myers/Constantine cohesion and coupling hierarchies      |
| [reference/test-design.md](reference/test-design.md)                                 | Behavior, boundary, equivalence partitioning, negative cases (after Myers's testing book) |
| [reference/verification-and-validation.md](reference/verification-and-validation.md) | Boehm's V&V distinction with concrete failure modes                                       |
| [reference/metric-thresholds.md](reference/metric-thresholds.md)                     | Function size, cyclomatic complexity, McCabe < 10, SonarSource Cognitive Complexity       |
| [reference/anti-patterns.md](reference/anti-patterns.md)                             | Eight anti-patterns covering the gap between citing principles and applying them          |

## What this skill does not do

- Replace `/flow:*` or `/audit:*` enforcement. Those are deterministic. This is a fallback.
- Substitute for stack-specific skills. Stack-specific patterns load independently when project signals match.
- Provide implementation patterns. This is principles only.

## References

These checklists distill widely accepted software engineering practice. For deeper background:

- Modularity, abstraction, separation of concerns: Parnas (1972), "On the Criteria To Be Used in Decomposing Systems into Modules", CACM 15(12) pp 1053-1058.
- Cyclomatic complexity: McCabe (1976), "A Complexity Measure", IEEE Transactions on Software Engineering SE-2(4) pp 308-320.
- Cohesion and coupling: Stevens, Myers, Constantine (1974), "Structured design", IBM Systems Journal 13(2) pp 115-139.
- V&V distinction: Boehm (1981), "Software Engineering Economics", Prentice-Hall.
- Test design (boundary, equivalence): Myers, "The Art of Software Testing", Wiley (1979 / revised editions).
- SOLID: Robert C. Martin (2000), "Design Principles and Design Patterns" (paper). Acronym coined by Michael Feathers (~2004).
- DRY: Hunt and Thomas, "The Pragmatic Programmer" (1st ed 1999, 20th anniversary ed 2019), Addison-Wesley.
- Refactoring catalog: Martin Fowler, "Refactoring" (2nd ed, 2018).
- Construction practice: Steve McConnell, "Code Complete" (2nd ed, 2004).
- Cognitive Complexity (vendor source): https://www.sonarsource.com/resources/cognitive-complexity/
- SEI CERT Coding Standards: https://wiki.sei.cmu.edu/confluence/display/seccode

Citations are for context. Do not require Claude to read source material; the checklists above are the operational version.
