---
name: tailwind-patterns
description: Tailwind CSS v4 patterns and v3-vs-v4 deltas. Load when implementing, reviewing, or auditing Tailwind code, especially when the project uses v4's CSS-first config without a tailwind.config.js.
---

# Tailwind patterns

Default assumption in this dotfiles project: Tailwind v4 with CSS-first config. If the project has a `tailwind.config.js` it is v3 and the v3 section applies; otherwise v4.

## v4 vs v3 at a glance

- v4 setup: a single `@import "tailwindcss"` in the main CSS file. No `@tailwind base / components / utilities` directives.
- v4 config: lives in CSS via the `@theme` directive. No `tailwind.config.js`. Theme tokens become CSS custom properties automatically.
- v4 content detection: automatic. The compiler scans the project for class names; you do not configure `content` paths.
- v4 plugins: still work, but most v3 plugins (typography, forms, container queries) are now built in. Check before installing.
- v4 build: ~5x faster. The Oxide engine replaces PostCSS for the core compile step.

## Setting up v4 correctly

```css
/* app/globals.css or equivalent */
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.7 0.15 250);
  --font-display: "Inter", sans-serif;
  --spacing-page: 4rem;
  --breakpoint-3xl: 1920px;
}
```

- Theme keys follow the pattern `--<namespace>-<name>`. Namespaces: `color`, `font`, `text`, `spacing`, `breakpoint`, `radius`, `shadow`, `animate`, etc.
- Defining a key generates the corresponding utility (`text-brand`, `font-display`, `p-page`, `3xl:`).
- Use `oklch()` for new colors; v4's default palette is OKLCH-based for better wide-gamut support.

## v3 patterns to avoid in v4

- `tailwind.config.js`: do not create one in a v4 project. Move config into `@theme` blocks. If the file exists in a v4 project, it is dead code.
- `@tailwind base; @tailwind components; @tailwind utilities;`: v3 directive triple. v4 replaces these with a single `@import "tailwindcss"`.
- `theme.extend`: v3 JS shape. In v4, all CSS-defined `--<namespace>-<name>` tokens extend the default theme automatically.
- `content: [...]`: v3 path config. v4 auto-detects.
- `@layer utilities { ... }` for arbitrary utility classes: still works, but prefer defining custom utilities with the `@utility` directive in v4 for better tree-shaking.

## Using theme values from CSS

- `--theme(--color-brand)`: read a theme value in plain CSS.
- `--alpha(var(--color-brand) / 50%)`: compute an alpha-modified color in v4. v3 used `theme()` helper differently.

## Variants and modifiers

- v4 variant order: `hover:focus:bg-blue-500` applies hover AND focus, just like v3. No change.
- New in v4: `not-` variant prefix (`not-hover:opacity-50`), `nth-child(n)` shorthand (`*:rounded-md`), starting-style variants (`starting:opacity-0` for entry animations).
- Container queries are built in: `@container` on the parent, `@sm:flex` etc. on children. No plugin install.

## Anti-patterns to flag in review

- Hardcoded hex colors (`text-[#ff0000]`) when an existing theme token would work. Use the token; if missing, add it to `@theme`.
- `@apply` chains longer than three utilities. They obscure the cascade and inhibit tree-shaking. Use a CSS class with raw properties instead, or compose at the markup level.
- Conditional `@apply` inside `@media` or selector blocks: works, but readability falls off fast. Inline utilities or extract a component.
- `dark:` everywhere instead of a `[data-theme="dark"]` strategy when the project has a theme toggle. v4 supports both; pick one.
- `animate-[...]` arbitrary values when a named animation exists. Define `--animate-<name>` in `@theme` and reuse.
- Missing `text-` size on body copy (relying on browser default 16px). Always set the base size explicitly.

## Verifying which version is in use

```sh
# v4: postcss config has @tailwindcss/postcss, OR vite plugin @tailwindcss/vite
rg '@tailwindcss/(postcss|vite)' package.json

# v4 config in CSS
rg '@import "tailwindcss"' --type css

# v3 sentinel: a tailwind.config.js or .ts
fd -t f 'tailwind.config'
```

If both `tailwind.config.js` and `@import "tailwindcss"` are present, the project is mid-migration. Treat as v4 but expect leftover v3 patterns.

## When to load this skill

- Any task touching Tailwind class names, theme tokens, or CSS imports in a Tailwind project.
- Migrations from v3 to v4.
- Code review where the diff includes `tailwind.config.*` or files importing Tailwind utilities.

## When not to load this skill

- Pure utility-class additions (e.g. adding `mt-4`) on a known-good v4 project. Just write the class.
- Non-Tailwind CSS work.

## References

- v4 release post: https://tailwindcss.com/blog/tailwindcss-v4
- v3-to-v4 upgrade guide: https://tailwindcss.com/docs/upgrade-guide
- v4 docs: https://tailwindcss.com/docs

When v4 evolves (4.1, 5.x), reconcile this skill against the current upgrade
guide before trusting the deltas above.
