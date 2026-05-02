---
name: javascript-patterns
description: JavaScript language patterns, modern syntax, async handling, module systems (ESM/CJS), error handling, and review checklist for JavaScript code without TypeScript. Use whenever the project contains `.js`, `.mjs`, `.cjs`, or `.jsx` files (and no `tsconfig.json`), `package.json` without TypeScript dependencies, OR the user asks about JavaScript, JS, ECMAScript, async/await, promises, modules, ESM, CommonJS, package.json, npm, pnpm, yarn, bun, or any work in JavaScript code without explicit TypeScript usage, even if "JavaScript" is not mentioned by name.
---

# JavaScript patterns

Default assumption: a project running on the current Node.js Active LTS (Node 24, "Krypton") or a modern browser baseline. If the project also uses TypeScript, the type-aware skill applies on top of these language patterns.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                                   | Covers                                                                           |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| [reference/modules.md](reference/modules.md)                           | ESM and CJS, `package.json` `"type"`, dynamic `import()`, dual-package hazard    |
| [reference/syntax.md](reference/syntax.md)                             | Modern syntax: optional chaining, nullish coalescing, logical assignment, `at()` |
| [reference/async.md](reference/async.md)                               | `async`/`await`, `Promise.*`, `for await...of`, top-level `await`                |
| [reference/errors.md](reference/errors.md)                             | Error subclasses, `Error.cause`, unhandled rejection, `using` (advisory)         |
| [reference/equality-and-numbers.md](reference/equality-and-numbers.md) | `===`, `Number.isNaN`, `Array.isArray`, IEEE 754, `BigInt`                       |
| [reference/collections.md](reference/collections.md)                   | `Map`, `Set`, `WeakMap`, `WeakSet` and when to reach for each                    |
| [reference/jsdoc.md](reference/jsdoc.md)                               | `// @ts-check` plus JSDoc tags for editor-checked types in `.js` files           |
| [reference/anti-patterns.md](reference/anti-patterns.md)               | Twelve review-time anti-patterns with severity calls                             |

## When to load this skill

- Any task touching `.js`, `.mjs`, `.cjs`, or `.jsx` files.
- Any task involving `package.json`, npm / pnpm / yarn / bun workflows, or Node runtime configuration.
- Code review where the diff includes module structure, async control flow, or error handling in JavaScript.
- Migrations between ESM and CJS, or between Node major versions.

## When not to load this skill

- TypeScript projects that already load type-aware patterns (this skill still applies for the language-level rules, but `any`-vs-`unknown`, generics, and tsconfig live elsewhere).
- Projects with no JavaScript surface (pure backends in another language).

## References

- MDN JavaScript reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference
- Node.js packages: https://nodejs.org/api/packages.html
- Node.js ESM: https://nodejs.org/api/esm.html
- Node.js process: https://nodejs.org/api/process.html
- Node.js previous releases (LTS schedule): https://nodejs.org/en/about/previous-releases
- TC39 proposals: https://github.com/tc39/proposals
- 2ality (Axel Rauschmayer): https://2ality.com/
- You Don't Know JS, 2nd ed. (Kyle Simpson): https://github.com/getify/You-Dont-Know-JS

## Maintenance note

ECMAScript ships a new edition each June. New syntax tends to land in V8 and Node within a release cycle of being standardized; TC39 stage 3 proposals can sometimes land in Node behind a flag before reaching stage 4. When new syntax appears in a code review, check this skill against the current MDN page and the current Node Active LTS before relying on legacy guidance here. Dropping support for an older Node major in `engines.node` is a breaking change for downstream consumers; treat it as such.
