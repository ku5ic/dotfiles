---
name: typescript-patterns
description: TypeScript patterns, strictness flags, type-safety anti-patterns, and review checklist covering any vs unknown, satisfies operator, branded types, discriminated unions, generic constraints, and module boundaries. Use whenever the user writes, reviews, or audits TypeScript code, asks about types, type errors, type narrowing, generics, tsconfig, or any work in a .ts or .tsx file, even if "TypeScript" is not mentioned by name.
---

# TypeScript patterns

Default assumption: a TypeScript project with `strict` mode enabled. If `strict` is off, that itself is a finding.

## Strictness flags

The "should be on" set. Each gets a one-line behavior summary; severity for projects with the flag off is `warning` (or `failure` for `strict` itself).

- `strict` (since 2.3): umbrella for the strict-mode family. Off is a `failure`; everything else compounds on it.
- `noUncheckedIndexedAccess` (since 4.1): adds `undefined` to indexed access on records and arrays. Without it, `arr[0]` types as the element instead of `T | undefined`.
- `exactOptionalPropertyTypes` (since 4.4): an optional property `{ x?: T }` means `T | absent`, not `T | undefined`. Catches code that assigns explicit `undefined` to an optional.
- `verbatimModuleSyntax` (since 5.0): emits exactly the import/export shape you wrote; type-only imports must say so. Replaces the deprecated `importsNotUsedAsValues` and `preserveValueImports`.
- `isolatedModules`: every file must be transpilable in isolation. Required when Babel, swc, or esbuild handle transpilation; turning it on at the type layer surfaces problems at typecheck rather than at bundle time.
- `noImplicitOverride` (since 4.3): subclass methods that override must use the `override` keyword. Catches drift when the parent class renames or removes a method.
- `noFallthroughCasesInSwitch` (since 1.8): every non-empty `case` requires `break`, `return`, or `throw`. Combine with discriminated-union exhaustiveness for free.
- `forceConsistentCasingInFileNames` (since 2.0): import paths must match the on-disk casing. Default `true` since 5.0; explicit on older configs is fine.

## Type expressions

- `unknown` over `any`. `any` opts out of the type system; `unknown` keeps the burden of proof at the call site. `any` is allowed only as a documented escape hatch with `// eslint-disable-next-line @typescript-eslint/no-explicit-any` plus a one-line reason comment.
- `as` casts: a smell unless paired with a type guard (`x is Foo`) or `satisfies`. `as unknown as X` chains earn a `failure` unless commented; the double escape hatch defeats the type system.
- `satisfies` (since 4.9) vs annotation: `satisfies` validates compatibility while preserving the inferred narrow type; an annotation widens. Use `satisfies` when you want the literal/inferred specificity to survive; use an annotation when widening is the point.

```ts
// annotation widens: routes.home is `string`
const routes: Record<string, string> = {
  home: "/",
  signin: "/auth/signin",
};

// satisfies preserves: routes.home is the literal "/"
const routes = {
  home: "/",
  signin: "/auth/signin",
} satisfies Record<string, string>;
```

- Discriminated unions over enums for shared API contracts. The discriminator is a literal `kind` (or `type`) field; `switch` over it gives free exhaustiveness. Enums are fine for closed sets inside a single module; they cross service or language boundaries badly.
- Branded types for IDs and money: zero runtime cost, structural mismatch enough to keep them apart.

```ts
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };

function asUserId(s: string): UserId {
  // validate s here (length, prefix, schema)
  return s as UserId;
}
```

The brand exists only at the type level. Construct branded values at boundaries (parsers, decoders, schema validators), not throughout the codebase.

- Generic constraints: `<T extends Record<string, unknown>>` over bare `<T>` when the helper indexes into `T`. Bare generics that are immediately indexed produce confusing errors at the call site.
- Return types on internal functions: inference is fine. On exported / public-API functions: explicit return types stop unintended widening as the implementation drifts.

## Narrowing

- `typeof x === "string"` for primitive narrowing. Works for `string`, `number`, `boolean`, `bigint`, `symbol`, `undefined`, `function`, `object`.
- `"key" in obj` for object-shape narrowing without committing to a class hierarchy. The cleanest way to distinguish two object types that do not share a discriminator.
- `instanceof Foo` for class-tagged values. Rare in modern TS outside DOM and Node built-ins; class hierarchies are not where most narrowing happens.
- User-defined type predicates: `function isFoo(x: unknown): x is Foo { ... }`. Use over `as` when the check has real runtime work that deserves a name. The body of the predicate is unverified by the compiler; a buggy predicate lies to the type system.
- Discriminator narrowing on unions: `if (msg.kind === "error") { /* msg.error is now in scope */ }`. Keep the discriminator a string literal (`"error" | "ok"`), not an enum.
- Exhaustiveness check: end a `switch` over a union with `default: { const _exhaustive: never = value; throw new Error("unhandled"); }`. Adding a new variant becomes a typecheck error, not a runtime surprise.

## Module boundaries

- `import type { Foo } from "..."` for type-only imports; `export type { Foo }` for type-only re-exports. Required when `verbatimModuleSyntax` is on; recommended even without it for legibility.
- Inline form (since 4.5): `import { run, type Result } from "./mod"` mixes value and type in one statement. Safe under `verbatimModuleSyntax`.
- Project references for monorepos: `composite: true` per package, `references` array on the consumer's `tsconfig.json`. Implies `declaration: true` and disciplined `rootDir` / `include`. See https://www.typescriptlang.org/docs/handbook/project-references.html.
- Circular imports: detect with tooling (`madge`, `dependency-cruiser`). `tsc` happily compiles a cycle; the tool catches it before it becomes a runtime hazard. Resolve by extracting a shared module rather than reordering imports.

## Common patterns

- Built-in utility types over hand-rolled: `Pick`, `Omit`, `Partial`, `Required`, `Readonly`. Hand-rolled equivalents drift.
- Extract types from values, not the other way around: `ReturnType<typeof fn>`, `Parameters<typeof fn>`, `Awaited<T>`. Reduces duplication at module boundaries; brittle when the source signature changes (the failure mode is loud, which is the point).
- Mapped types with `as` clauses to rename keys: `{ [K in keyof T as \`on${Capitalize<K & string>}\`]: () => void }`. Useful for deriving event-handler shapes from a state type.
- Template literal types for string-shape constraints: `type Pixels = \`${number}px\``. Compile-time only; pair with a runtime validator if the value crosses a network or storage boundary.
- Conditional types: useful but slow to compile and hard to read. Reach for them only when overloads or plain unions cannot do the job.
- `infer` in conditional types: extract a type from a generic shape (return type, parameter type, awaited type). Useful and dense; document the intent.

```ts
type Awaited<T> = T extends Promise<infer U> ? U : T;
```

## Anti-patterns to flag in review

- `any` on a public API surface without an escape-hatch comment: `failure`. Public types are contracts; `any` voids the contract silently.
- `as` cast where a type guard or `satisfies` would work: `warning`. Casts hide errors; predicates and `satisfies` surface them.
- `as unknown as X` to silence the compiler: `failure` unless a comment explains why no narrower path exists and what runtime check protects the boundary.
- Bare `as any` mid-expression: `failure`. At least `as unknown as X` announces the double escape; `as any` hides inside an expression and degrades downstream inference.
- `// @ts-nocheck` at the file head: `failure`. Disables typechecking for the whole file. Replace with targeted `// @ts-expect-error` lines or fix the underlying issue.
- `// @ts-ignore` over `// @ts-expect-error`: `warning`. `@ts-expect-error` (since 3.9) fails the build when the suppressed error goes away, forcing cleanup; `@ts-ignore` rots silently.
- Enum used in an API contract crossed with another team or service: `warning`. Discriminated unions or string-literal unions serialize cleanly; enums embed an integer-or-string ambiguity that breaks across runtimes.
- `Function`, `Object`, or `{}` as a parameter type: `failure`. `{}` means "any non-null, non-undefined value" (including `0`, `""`, primitives), NOT "an empty object". Use `Record<string, unknown>` for "any object", `unknown` for "any value", `Record<string, never>` for "actually empty".
- `namespace` keyword in `.ts` source: `warning`. Pre-modules era. Acceptable only in ambient declarations in `.d.ts`.
- Exported function with no explicit return type: `info`. Inference is fine internally; the public surface should pin the contract so callers do not silently track implementation drift.
- Tuple-shaped literal without `as const`: `info`. `[1, 2]` infers as `number[]`; `[1, 2] as const` infers as `readonly [1, 2]`. Choose deliberately.
- Excessive type acrobatics: a generic helper that takes more than a few minutes to read is debt. `warning`. Consider whether a simpler shape with a runtime helper would carry the same invariant.

## tsconfig in review

When reviewing a TypeScript project's `tsconfig.json`:

- `strict: true` plus the strictness-flag set above. `strict: false` is `failure`; each missing additional strictness flag is `warning`.
- `target`: matches the runtime. For Node 20+, `es2022` or newer; for browsers, leave the bundler in charge with a sane floor (`es2020` or `es2022`).
- `module` and `moduleResolution`: `"nodenext"` for both on modern Node. For bundled code, `module: "preserve"` or `"esnext"` paired with `moduleResolution: "bundler"`. Use `"node16"` for libraries publishing dual ESM/CJS. Avoid the legacy `"node"` / `"node10"` on new projects.
- `paths` aliases: must match the runtime resolver. A `paths` alias that compiles cleanly but the runtime cannot resolve at execution is a `failure`; bundlers, `tsx`, and runtime path mappers each need their own wiring.
- `skipLibCheck: true`: commonly enabled. Tradeoff is faster compile vs missing `.d.ts` errors from dependencies. Acceptable in most projects; not a finding on its own.
- `composite: true` on monorepo packages that participate in project references. Without it, `tsc --build` orchestration falls apart.

## When to load this skill

- Any task touching `.ts` or `.tsx` files.
- Any task involving `tsconfig.json`.
- Code review where the diff includes type definitions, generic helpers, or module boundary changes.
- Migrations from `.js` to `.ts`.

## When not to load this skill

- Pure `.js` or `.jsx` work in a project with no TypeScript adoption.
- Trivial type imports from a known-good third-party package.
- React or Next.js specific TypeScript patterns: load `react-patterns`.
- Tailwind-specific styling questions: load `tailwind-patterns`.

## References

- TypeScript handbook: https://www.typescriptlang.org/docs/handbook/
- tsconfig reference: https://www.typescriptlang.org/tsconfig
- Release notes index: https://www.typescriptlang.org/docs/handbook/release-notes/overview.html
- `satisfies` operator (4.9): https://devblogs.microsoft.com/typescript/announcing-typescript-4-9/
- `verbatimModuleSyntax` (5.0): https://devblogs.microsoft.com/typescript/announcing-typescript-5-0/
- typescript-eslint rules (`no-empty-object-type`, `prefer-ts-expect-error`, `no-explicit-any`): https://typescript-eslint.io/rules/

When TypeScript evolves (5.x minor releases, 6.x, 7.x), reconcile this skill against the current handbook before trusting deltas above. As of writing, 6.0 is the last release of the JavaScript-based compiler; 7.0 is the native (Go) port and may shift defaults around module resolution and strictness.
