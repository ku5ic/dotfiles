---
name: vue-patterns
description: Vue 3 patterns - the Composition API, reactivity, single-file components, anti-patterns, and review checklist. Use whenever the project contains `.vue` files, `vue` in `package.json`, or a `vite.config.*` with the Vue plugin, OR the user asks about Vue, its reactivity primitives, `script setup`, or Pinia, even if Vue is not mentioned by name.
---

# Vue patterns

Default assumption: Vue 3 with the Composition API and `<script setup>` syntax.

- Current stable is Vue 3.5; deltas in 3.5+ (Reactive Props Destructure, `onWatcherCleanup`, `defineModel`) are called out where they matter.
- Options API is acceptable for legacy code; flag as legacy when reviewed.
- Adapt advice to the version in the project's `package.json` or lockfile.

## Reference files

| File                                                     | Covers                                                                          |
| -------------------------------------------------------- | ------------------------------------------------------------------------------- |
| [reference/reactivity.md](reference/reactivity.md)       | `ref` vs `reactive`, `toRefs`, `shallowRef`, destructuring traps                |
| [reference/components.md](reference/components.md)       | `<script setup>`, `defineProps`/`Emits`/`Slots`/`Model`, defaults (3.5+ vs 3.4) |
| [reference/watchers.md](reference/watchers.md)           | `watch` vs `watchEffect`, options, deep watchers, async cleanup                 |
| [reference/state.md](reference/state.md)                 | `provide`/`inject`, Pinia, composables                                          |
| [reference/anti-patterns.md](reference/anti-patterns.md) | Nine review-time anti-patterns with severity calls                              |

## Out of scope

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

## Version notes

- Vue 3.5 introduced Reactive Props Destructure (replacing the `withDefaults` ergonomic) and `onWatcherCleanup`.
- Vue 3.4 introduced `defineModel` and watcher `once: true`.
- Vue 3.3 introduced `defineSlots` and tuple-style `defineEmits` types.
- When new syntax appears in a code review, check this skill against the current changelog before relying on legacy guidance.
- Vue 2 reaches end-of-life status; new projects should be Vue 3, and Vue-2-only patterns are out of scope here.
