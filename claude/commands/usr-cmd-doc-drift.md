---
name: doc-drift
description: Detect documentation drift between code and all markdown docs in the project
---

Analyze the following for documentation drift between the code at $ARGUMENTS and the markdown documentation pulled below.

## Markdown documentation found in this project

```!
find . -name '*.md' \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  | sort \
  | xargs -I{} sh -c 'echo "### {}" && cat "{}" && echo'
```

## Code to check

$ARGUMENTS

---

Check:

1. Inline comments and JSDoc - do they still accurately describe what the code does? Flag stale parameter descriptions, incorrect return type docs, outdated behavior descriptions, and comments that describe code that no longer exists
2. External markdown docs - do they match the current implementation? Flag outdated usage examples, incorrect configuration instructions, missing documentation for new features, and documented features that have been removed or renamed
3. Type signature drift - where JSDoc types conflict with actual TypeScript types, or where TypeScript exists but JSDoc has not been aligned or removed
4. Example drift - code examples in docs that would fail or behave differently if run against the current implementation

For each finding:

- Location (file and line if available)
- What the documentation says
- What the code actually does
- Severity: blocking (actively misleads), moderate (partially outdated), minor (cosmetic or trivial gap)

Do not flag missing documentation as drift unless something previously documented has been removed or changed.
