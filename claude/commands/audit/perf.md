---
description: Performance audit focused on statically detectable issues
argument-hint: <file, directory, or area name>
---

**Effort: heavy.** Static analysis. Does not run benchmarks. Flags what is likely slow, names what to measure.

## Procedure

1. Run `!`$HOME/.claude/bin/detect-stack.sh``. Get the project name: `!`$HOME/.claude/bin/project-name.sh``.
2. Load the patterns skill for the detected stack (react-patterns, django-patterns, etc.) for the anti-pattern reference.
3. Review the target across these categories. Skip categories with no findings.

### Frontend (React and Next.js)

- Unnecessary re-renders: inline object or function props to memoized components, context value churn, parent re-renders that include large subtrees
- Missing memoization where it actually matters (measurably expensive computation, or stable reference needed by memo child)
- Key stability on lists that reorder
- Effect waterfalls: multiple sequential effects that could be one or parallel
- Client bundle bloat: client components importing large libraries, server-only logic leaking to client via shared utilities, unused but imported modules
- Next.js: unintended client component propagation, wrong cache or revalidate config for correctness, missing `next/image` or `next/font`
- Core Web Vitals where statically inferable: CLS from missing dimensions, LCP from above-the-fold client-side rendering

### Backend (Django, Node APIs)

- N+1 queries: missing `prefetch_related`, `select_related`, or ORM equivalent
- Unbounded queries: missing pagination, `.all()` on large tables
- Synchronous I/O in async contexts
- Missing indexes on filtered or ordered columns (static inference from query shape)
- Serialization cost: deep nested serializers, recursive expansions
- Cache misuse: caching with key collisions, caching before query filtering

### General

- Unbounded loops
- Accidental O(n^2) via nested iteration over the same collection
- Reading a whole file when streaming is possible
- Blocking operations in request path

## Output per finding

- Location
- What: the specific pattern
- Why it matters: estimated impact (render count, query count, payload size)
- Verification: how to measure, if not statically obvious (e.g. "profile with React DevTools, expect re-render on every parent state change")
- Fix: concrete code change or pattern switch

## Output file

Use markdown-report format. Write to `~/.claude/scratch/perf-<project-name>-<target-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

## Rules

- Do not claim measured improvement. This command does not run anything.
- Flag what to measure, not what to assume.
- Ignore micro-optimizations that change code without measurable benefit.
