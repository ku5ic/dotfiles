---
name: next-app-router-patterns
description: Next.js App Router patterns covering server/client boundary, data fetching and caching, server actions, streaming, parallel and intercepting routes, edge vs node runtime, and review checklist. Use whenever the project contains `next.config.js`, `next.config.mjs`, `next.config.ts`, an `app/` directory with `page.tsx`/`page.jsx`/`layout.tsx`/`layout.jsx`/`route.ts`, OR `next` in `package.json` dependencies, OR the user asks about Next.js, App Router, server components, client components, server actions, route handlers, parallel routes, intercepting routes, streaming, generateMetadata, generateStaticParams, even if Next.js is not mentioned by name.
---

# Next.js App Router patterns

Default assumption: Next.js 16 (current stable as of writing) with the App Router. Pages Router patterns are out of scope. Cache Components is the new caching model in 16 (opt-in via `cacheComponents: true`); the previous caching model is still supported when the flag is off.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                             | Covers                                                                                 |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| [reference/server-and-client.md](reference/server-and-client.md) | `"use client"` propagation, server vs client constraints, serialization, `server-only` |
| [reference/caching.md](reference/caching.md)                     | Cache Components vs previous model, `fetch` defaults, segment config, revalidation     |
| [reference/server-actions.md](reference/server-actions.md)       | Server Functions, `"use server"`, form actions, validation, revalidation               |
| [reference/streaming.md](reference/streaming.md)                 | `loading.tsx`, `<Suspense>`, error boundaries, Partial Prerendering                    |
| [reference/routing.md](reference/routing.md)                     | File conventions, dynamic segments, parallel/intercepting routes, metadata             |
| [reference/runtime.md](reference/runtime.md)                     | Node vs Edge, Proxy (renamed from Middleware in v16), runtime config                   |
| [reference/client-bundle.md](reference/client-bundle.md)         | `next/image`, `next/font`, `next/dynamic`, tree-shaking and bundle audits              |

## When to load this skill

- Any task touching files under `app/` (`page.tsx`, `layout.tsx`, `route.ts`, `loading.tsx`, etc.).
- Any task involving `next.config.*`, `proxy.ts` / `middleware.ts`, or Next-specific imports (`next/cache`, `next/server`, `next/image`, `next/font`, `next/dynamic`, `next/navigation`, `next/headers`).
- Code review where the diff includes server/client boundary changes, cache directives, server actions, or route segment configuration.
- Migrations from Pages Router to App Router, or between Next.js majors.

## When not to load this skill

- Pages Router projects (`pages/` only, no `app/` directory). The patterns differ enough that this skill would mislead.
- React projects without Next.js (use the React skill alone).

## References

- Next.js docs: https://nextjs.org/docs
- App Router structure: https://nextjs.org/docs/app/getting-started/project-structure
- Caching (Cache Components): https://nextjs.org/docs/app/getting-started/caching
- Caching (previous model): https://nextjs.org/docs/app/guides/caching-without-cache-components
- Server and Client Components: https://nextjs.org/docs/app/getting-started/server-and-client-components
- Mutating Data: https://nextjs.org/docs/app/getting-started/mutating-data
- `proxy.js`: https://nextjs.org/docs/app/api-reference/file-conventions/proxy
- Next.js blog: https://nextjs.org/blog
- Lee Robinson (Vercel DX): https://leerob.io/
- Vercel Engineering: https://vercel.com/blog

## Maintenance note

Next.js ships major releases roughly yearly and minor releases monthly. File conventions, cache defaults, and directive names have shifted multiple times: PPR went from preview to stable in 16, `middleware` was renamed to `proxy` in 16, `fetch` default cache behavior changed in 15. Verify any version-sensitive claim against the current docs at https://nextjs.org/docs and the release entries at https://nextjs.org/blog before relying on it. The Pages Router still exists in 16 but is not covered here.
