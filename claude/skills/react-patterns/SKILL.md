---
name: react-patterns
description: React core patterns - hooks rules, component design, rendering performance, anti-patterns, and review checklist, independent of any meta-framework. Use whenever the project contains `.jsx`/`.tsx` files or `react` in `package.json`, OR the user asks about React, its hooks, component structure, or rendering and hydration behavior, even if React is not mentioned by name.
---

# React patterns

Default assumption: React 19 with the modern (concurrent) renderer.

- Most rules apply unchanged to React 18; deltas (`use`, `useActionState`, `useFormStatus`, `useOptimistic`, Actions) are called out where they matter.
- Server Components are a feature of frameworks built on React; framework-specific patterns load when those framework signals are present in the project.
- Adapt advice to the version in the project's `package.json` or lockfile.

## Reference files

| File                                                     | Covers                                                                              |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [reference/correctness.md](reference/correctness.md)     | Rules of Hooks, dependency arrays, key stability, effect cleanup, render pitfalls   |
| [reference/performance.md](reference/performance.md)     | Memoization costs, `React.memo`, virtualization, lazy init, context, React Compiler |
| [reference/structure.md](reference/structure.md)         | Controlled vs uncontrolled, derived state, prop drilling, effects vs handlers       |
| [reference/anti-patterns.md](reference/anti-patterns.md) | Seven review-time anti-patterns with severity calls                                 |
| [reference/when-to-split.md](reference/when-to-split.md) | Heuristics for component splitting and what does not justify a split                |

## References

- React docs: https://react.dev/
- Rules of React: https://react.dev/reference/rules
- React 19 release notes: https://react.dev/blog/2024/12/05/react-19
- React Compiler: https://react.dev/learn/react-compiler/introduction
- "You Might Not Need an Effect": https://react.dev/learn/you-might-not-need-an-effect
- Dan Abramov on React internals: https://overreacted.io/
- Mark Erikson on React state management: https://blog.isquaredsoftware.com/

## Version notes

React's release cadence has slowed since 18; major changes now arrive through the React Compiler and through Server Component primitives that frameworks adopt.

- When new React 19 features (Actions, `use`, `useActionState`) appear in code, verify against the per-hook page on react.dev rather than older blog posts.
- The React Compiler is stable but opt-in; it is not a default and may not be present in every project.
