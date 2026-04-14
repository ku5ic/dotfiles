---
name: debt
description: Surface technical debt and architectural risks with severity and remediation path
---

Analyze the following for technical debt and architectural risk. Be direct and skeptical.

For each issue found, provide:

- What it is
- Why it is a problem (scale, maintainability, correctness, security, or performance)
- Severity: critical / high / medium / low
- Remediation: what to do and roughly how much effort it involves

Categories to evaluate:

1. Architecture - inappropriate coupling, missing abstraction boundaries, wrong layer responsibilities
2. Type safety - escape hatches, runtime assumptions not reflected in types, unsafe casts
3. State management - local state that should be lifted, global state that should be local, derived state being stored
4. Side effects - unguarded async, missing cleanup, implicit dependencies
5. Scalability - things that work now but will break or become unmaintainable under growth
6. Dead code and duplication - unused exports, copy-paste logic, parallel implementations
7. Build and dependency health - outdated patterns, deprecated APIs, ejected config, implicit peer dependency assumptions

Prioritize issues that will cause real pain. Do not list minor style preferences as debt.

$ARGUMENTS
