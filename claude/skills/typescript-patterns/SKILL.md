---
name: typescript-patterns
description: TypeScript patterns, strictness flags, type-safety anti-patterns, and review checklist covering any vs unknown, satisfies operator, branded types, discriminated unions, generic constraints, and module boundaries. Use whenever the project contains `.ts` or `.tsx` files, `tsconfig.json`, `tsconfig.base.json`, or `typescript` in `package.json` dependencies, OR the user asks about TypeScript, types, type errors, type narrowing, generics, tsconfig, or any work in a `.ts` or `.tsx` file, even if "TypeScript" is not mentioned by name.
---

# TypeScript patterns

Default assumption: a TypeScript project with `strict` mode enabled. If `strict` is off, that itself is a finding.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                             | Covers                                                                                                     |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [reference/strictness.md](reference/strictness.md)               | Strictness flags, tsconfig review, incremental migration patterns                                          |
| [reference/type-expressions.md](reference/type-expressions.md)   | `unknown` vs `any`, `satisfies`, discriminated unions, branded types, generic constraints, common patterns |
| [reference/narrowing.md](reference/narrowing.md)                 | `typeof` / `in` / `instanceof`, predicates, exhaustiveness, `assertNever`                                  |
| [reference/module-boundaries.md](reference/module-boundaries.md) | `import type`, project references, circular imports, barrel-file anti-pattern                              |
| [reference/anti-patterns.md](reference/anti-patterns.md)         | Twelve review-time anti-patterns with severity calls                                                       |

## When to load this skill

- Any task touching `.ts` or `.tsx` files.
- Any task involving `tsconfig.json`.
- Code review where the diff includes type definitions, generic helpers, or module boundary changes.
- Migrations from `.js` to `.ts`.

## When not to load this skill

- Pure `.js` or `.jsx` work in a project with no TypeScript adoption.
- Trivial type imports from a known-good third-party package.

## References

- TypeScript handbook: https://www.typescriptlang.org/docs/handbook/
- tsconfig reference: https://www.typescriptlang.org/tsconfig
- Release notes index: https://www.typescriptlang.org/docs/handbook/release-notes/overview.html
- `satisfies` operator (4.9): https://devblogs.microsoft.com/typescript/announcing-typescript-4-9/
- Variance annotations (4.7): https://devblogs.microsoft.com/typescript/announcing-typescript-4-7/
- `verbatimModuleSyntax` and `const` type parameters (5.0): https://devblogs.microsoft.com/typescript/announcing-typescript-5-0/
- typescript-eslint rules (`no-empty-object-type`, `prefer-ts-expect-error`, `no-explicit-any`): https://typescript-eslint.io/rules/
- Vercel: package import optimization (barrel files): https://vercel.com/blog/how-we-optimized-package-imports-in-next-js

## Maintenance note

When TypeScript evolves (5.x minor releases, 6.x, 7.x), reconcile this skill against the current handbook before trusting deltas above. As of writing, 6.0 is the last release of the JavaScript-based compiler; 7.0 is the native (Go) port and may shift defaults around module resolution and strictness.
