---
name: vue-patterns
description: Vue 3 Composition API patterns, reactivity, single-file components, anti-patterns, and review checklist. Use whenever the project contains `.vue` files, `vue` in `package.json` dependencies, `vite.config.*` with the Vue plugin, OR the user asks about Vue, Vue 3, Composition API, ref, reactive, computed, watch, watchEffect, defineProps, defineEmits, defineSlots, script setup, single-file components, Pinia, even if Vue is not mentioned by name.
---

# Vue patterns

Default assumption: Vue 3 with the Composition API and `<script setup>` syntax. Current stable is Vue 3.5; deltas in 3.5+ (Reactive Props Destructure, `onWatcherCleanup`, `defineModel`) are called out where they matter. Options API is acceptable for legacy code; flag as legacy when reviewed.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                     | Covers                                                                          |
| -------------------------------------------------------- | ------------------------------------------------------------------------------- |
| [reference/reactivity.md](reference/reactivity.md)       | `ref` vs `reactive`, `toRefs`, `shallowRef`, destructuring traps                |
| [reference/components.md](reference/components.md)       | `<script setup>`, `defineProps`/`Emits`/`Slots`/`Model`, defaults (3.5+ vs 3.4) |
| [reference/watchers.md](reference/watchers.md)           | `watch` vs `watchEffect`, options, deep watchers, async cleanup                 |
| [reference/state.md](reference/state.md)                 | `provide`/`inject`, Pinia, composables                                          |
| [reference/anti-patterns.md](reference/anti-patterns.md) | Nine review-time anti-patterns with severity calls                              |

## When to load this skill

- Any task touching `.vue` files (Single-File Components).
- Any task involving Vue Composition API primitives, custom composables, or Pinia stores.
- Code review where the diff includes reactivity, watchers, or component boundary changes.
- Migrations between Vue 3 minor versions (especially 3.4 -> 3.5 for reactive props destructure).

## When not to load this skill

- Vue 2 projects. The Options API is the default and the reactivity model is fundamentally different. Flag the project's Vue major and stop; the patterns here will mislead.
- React projects. Despite surface similarities (component tree, hooks-like primitives), the reactivity models differ.

## References

- Vue docs: https://vuejs.org/guide/introduction.html
- Vue API reference: https://vuejs.org/api/
- Vue 3 changelog: https://github.com/vuejs/core/blob/main/CHANGELOG.md
- Pinia: https://pinia.vuejs.org/
- Vue blog (releases): https://blog.vuejs.org/
- Anthony Fu (core team, Vite/Nuxt contributor): https://antfu.me/
- Eduardo San Martin Morote (Vue Router, Pinia maintainer): https://esm.dev/

## Maintenance note

Vue 3.5 introduced Reactive Props Destructure (replacing the `withDefaults` ergonomic) and `onWatcherCleanup`. Vue 3.4 introduced `defineModel` and watcher `once: true`. Vue 3.3 introduced `defineSlots` and tuple-style `defineEmits` types. When new syntax appears in a code review, check this skill against the current changelog before relying on legacy guidance. Vue 2 reaches end-of-life status; new projects should be Vue 3, and Vue-2-only patterns are out of scope here.
