---
name: review
description: Code review focused on correctness, TypeScript, accessibility, performance, and maintainability
---

Review the following code as a senior frontend engineer would. Target: production quality in a React/Next.js/TypeScript codebase.

Evaluate in this order:

1. Correctness - logic errors, edge cases, null/undefined handling, async pitfalls
2. TypeScript - type safety, improper use of any/unknown/as, missing generics, inaccurate return types
3. Accessibility - semantic HTML, ARIA usage, keyboard operability, focus management, WCAG 2.1 AA violations
4. Performance - unnecessary re-renders, missing memoization, large bundle imports, layout thrash
5. Design principles - SOLID violations (single responsibility, open/closed, dependency inversion), DRY (duplicated logic that should be abstracted), KISS (unnecessary complexity, over-engineered solutions)
6. Maintainability - naming clarity, abstraction level, coupling, hidden assumptions
7. Tech debt - anything that will cause pain at scale or during future refactoring

For each issue found: state what it is, why it matters, and the fix. Skip categories with no findings. Do not pad the output.

$ARGUMENTS
