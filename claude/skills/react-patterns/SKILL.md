---
name: react-patterns
description: React patterns, anti-patterns, hooks rules, performance, component design, and review checklist for React core (independent of any specific meta-framework). Use whenever the project contains `.jsx` or `.tsx` files, `react` in `package.json` dependencies, OR the user asks about React, hooks, components, JSX, TSX, useState, useEffect, useMemo, useCallback, rendering, hydration, React performance, or any React component work, even if React is not mentioned by name.
---

# React and Next.js patterns

## React: correctness

- Hooks rules: only at top level, only in components or other hooks. No conditional hooks, no hooks in loops.
- Dependency arrays: every value from component scope used inside the effect must be in deps. Stale closures are a failure.
- Key stability: keys on lists must be stable and unique. Index as key only when the list is static and append-only.
- Effect cleanup: any subscription, timer, or event listener must be cleaned up in the return function.
- Conditional rendering: `&&` with numeric falsy (e.g. `items.length && ...`) renders `0`. Use explicit comparison or ternary.

## React: performance

- Memoization costs: `useMemo` and `useCallback` have a cost. Use when a dependent component would otherwise re-render unnecessarily, or when computation is expensive. Otherwise remove.
- `React.memo` only helps if props are referentially stable. Audit parent for inline object and function props.
- Large lists: virtualize at 200+ items. Below that, layout and paint are usually fine.
- `useState` with expensive initializer: use lazy initializer `useState(() => compute())`, not `useState(compute())`.
- Context: changing context value re-renders every consumer. Split contexts by update cadence, not by domain.

## React: structure

- Controlled vs uncontrolled: pick one per field. Mixed state is a bug generator.
- Derived state: compute during render. Do not mirror props or other state in `useState` with an effect. If the data comes from props, it is not state.
- Prop drilling beyond 2 levels: consider composition or context, in that order.
- `useEffect` for synchronization with external systems only. Not for computing derived values. Not for event handlers masquerading as effects.

## Next.js: server and client boundary

- `"use client"` spreads down the import graph. Audit what becomes client code when you mark something client.
- Server components cannot use hooks, event handlers, browser APIs. Client components cannot use async render or direct data fetching.
- Data fetching: prefer server components with direct async. Client fetching only when interactivity demands it.
- Serialization boundary: server components pass serializable props to client components. Functions, class instances, Dates pre-ISO-cast, Maps and Sets all cross at your peril.
- `headers()` and `cookies()`: server only. Using in a client component is a build error; using in shared utility pulls that utility to server-only.

## Next.js: data and caching

- `fetch` in server components: default cache behavior changed between App Router versions. Be explicit with `cache: "no-store"` or `next: { revalidate: N }` when correctness depends on freshness.
- Route segment config: `dynamic`, `revalidate`, `fetchCache` are route wide. Surprising when inherited.
- `generateStaticParams` vs dynamic rendering: check that static pages actually stay static, and that ISR tags are revalidated where mutations happen.
- Metadata API: `generateMetadata` must return serializable metadata. No functions, no class instances.

## Next.js: client bundle

- Importing from a large library in a client component pulls the whole library client-side unless tree-shakable. Audit `lodash`, `date-fns`, icon libraries.
- `next/image`: use it. Raw `<img>` skips optimization and Core Web Vitals suffer.
- `next/font`: use it. Font flash and layout shift regress without it.
- `next/dynamic` with `ssr: false`: use when a component truly cannot render on the server. Overuse defeats SSR benefits.

## Anti-patterns to flag in review

- `useState` with an effect that sets it from props
- `useEffect` that runs a synchronous computation from state
- `any` on a component prop or hook return
- Inline object or array literal passed to a memoized component's props
- `key={index}` on a list that reorders
- `dangerouslySetInnerHTML` with unsanitized input
- `fetch` without error handling in a client component
- Mutating props or state directly
- `useEffect` with empty deps doing work that belongs on mount in a server component

## When to split a component

Split when one of:

- The render function exceeds about 150 lines
- There are two independent concerns that re-render at different cadences
- A subsection has its own state that the parent does not need
- The component is re-used in 2+ places

Do not split just to make things smaller. Premature splitting scatters logic.
