---
name: nuxt-patterns
description: Nuxt 3+ patterns covering rendering modes, data fetching (useFetch, useAsyncData, $fetch), server routes, SSR-safe state, file-based routing, Nitro runtime, and review checklist. Use whenever the project contains `nuxt.config.ts`, `nuxt.config.js`, `nuxt` in `package.json` dependencies, or `pages/`/`server/`/`composables/` directories at project root, OR the user asks about Nuxt, useFetch, useAsyncData, $fetch, server routes, Nitro, Nuxt SSR, even if Nuxt is not mentioned by name.
---

# Nuxt patterns

Default assumption: Nuxt 4 (current stable, latest 4.4.x as of writing) with Universal Rendering (SSR). Nuxt 3 reached End-of-Life in mid-2024; legacy Nuxt 3 projects are still common and most patterns here apply, but the maintenance note below covers deltas.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                     | Covers                                                                              |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [reference/rendering.md](reference/rendering.md)         | SSR, SPA, SSG, hybrid via `routeRules`, edge rendering                              |
| [reference/data-fetching.md](reference/data-fetching.md) | `useFetch`, `useAsyncData`, `$fetch`, dedup, lazy fetching                          |
| [reference/state.md](reference/state.md)                 | `useState` SSR-safety, module-level leakage, Pinia, composables                     |
| [reference/routing.md](reference/routing.md)             | File-based routes, layouts, route middleware vs server middleware, `definePageMeta` |
| [reference/server.md](reference/server.md)               | Nitro, server routes, validation, `runtimeConfig` and env-var conventions           |

## When to load this skill

- Any task touching `nuxt.config.*`, `pages/`, `server/`, `composables/`, `middleware/`, or `layouts/` at project root.
- Any task involving Nuxt-specific composables (`useFetch`, `useAsyncData`, `useState`, `useRuntimeConfig`, `useRoute`, `useRouter`, `useNuxtApp`).
- Code review where the diff includes server routes, route middleware, or `routeRules` config.
- Migrations from Nuxt 2 -> 3 or Nuxt 3 -> 4.

## When not to load this skill

- Pure Vue projects without Nuxt (no `nuxt.config.*`, no `pages/`). The Vue patterns apply, but Nuxt-specific composables and SSR semantics do not.
- Backend-only TypeScript projects that happen to use h3 or Nitro standalone.

## References

- Nuxt docs: https://nuxt.com/docs
- Nuxt blog (releases): https://nuxt.com/blog
- Rendering concepts: https://nuxt.com/docs/guide/concepts/rendering
- Server engine (Nitro): https://nuxt.com/docs/guide/concepts/server-engine
- Data fetching: https://nuxt.com/docs/getting-started/data-fetching
- `useState`: https://nuxt.com/docs/api/composables/use-state
- `runtimeConfig`: https://nuxt.com/docs/guide/going-further/runtime-config
- Daniel Roe (Nuxt lead): https://roe.dev/
- Anthony Fu (Vite/Nuxt overlap): https://antfu.me/
- Sebastien Chopin (Nuxt creator): https://github.com/atinux

## Maintenance note

Nuxt 4 is the current stable major; Nuxt 4.4 introduced custom `useFetch`/`useAsyncData` factories and other refinements (March 2026). Nuxt 3 reached EOL on June 30, 2024 and no longer receives updates; Nuxt 3 projects should plan a 4 migration. The Nitro runtime and h3 framework underneath are versioned independently and can update without a Nuxt major bump; verify version-sensitive claims against the current docs at https://nuxt.com/docs and the release entries at https://nuxt.com/blog. Vue 2-based Nuxt 2 patterns are out of scope here.
