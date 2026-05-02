---
name: react-patterns
description: React patterns, anti-patterns, hooks rules, performance, component design, and review checklist for React core (independent of any specific meta-framework). Use whenever the project contains `.jsx` or `.tsx` files, `react` in `package.json` dependencies, OR the user asks about React, hooks, components, JSX, TSX, useState, useEffect, useMemo, useCallback, rendering, hydration, React performance, or any React component work, even if React is not mentioned by name.
---

# React patterns

Default assumption: React 19 with the modern (concurrent) renderer. Most rules apply unchanged to React 18; deltas (`use`, `useActionState`, `useFormStatus`, `useOptimistic`, Actions) are called out where they matter. Server Components are a feature of frameworks built on React; framework-specific patterns load when those framework signals are present in the project.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                     | Covers                                                                              |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [reference/correctness.md](reference/correctness.md)     | Rules of Hooks, dependency arrays, key stability, effect cleanup, render pitfalls   |
| [reference/performance.md](reference/performance.md)     | Memoization costs, `React.memo`, virtualization, lazy init, context, React Compiler |
| [reference/structure.md](reference/structure.md)         | Controlled vs uncontrolled, derived state, prop drilling, effects vs handlers       |
| [reference/anti-patterns.md](reference/anti-patterns.md) | Seven review-time anti-patterns with severity calls                                 |
| [reference/when-to-split.md](reference/when-to-split.md) | Heuristics for component splitting and what does not justify a split                |

## When to load this skill

- Any task touching `.jsx` or `.tsx` files.
- Any task involving React component design, hooks, state management, or render performance.
- Code review where the diff includes React components, custom hooks, or context usage.
- Migrations between React major versions (17 -> 18 -> 19).

## When not to load this skill

- Pure utility code with no React surface (the language patterns apply, not these).
- Styling-only changes that do not touch components or hooks.

## References

- React docs: https://react.dev/
- Rules of React: https://react.dev/reference/rules
- React 19 release notes: https://react.dev/blog/2024/12/05/react-19
- React Compiler: https://react.dev/learn/react-compiler/introduction
- "You Might Not Need an Effect": https://react.dev/learn/you-might-not-need-an-effect
- Dan Abramov on React internals: https://overreacted.io/
- Mark Erikson on React state management: https://blog.isquaredsoftware.com/

## Maintenance note

React's release cadence has slowed since 18; major changes now arrive through the React Compiler and through Server Component primitives that frameworks adopt. When new React 19 features (Actions, `use`, `useActionState`) appear in code, verify against the per-hook page on react.dev rather than older blog posts. The React Compiler is stable but opt-in; it is not a default and may not be present in every project.
