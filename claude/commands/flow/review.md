---
description: Senior review of recently changed code, stack aware
argument-hint: <optional: commit range, branch, or path>
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash($HOME/.claude/bin/project-name.sh)
---

**Effort: heavy.** Deep review. Read the changed files and their immediate context.

## Procedure

1. Get the project name: `!`$HOME/.claude/bin/project-name.sh``. Stack is in the injected `<repo-context>` block.
2. If the diff exceeds 500 changed lines, propose splitting the review into logical chunks before starting.
3. Determine the review scope:
   - If $ARGUMENTS looks like a commit range (`main..HEAD`, SHA range): review that range
   - If $ARGUMENTS is a path: review that path's current state
   - Otherwise: review `git diff HEAD` (working copy)
4. Load patterns skills matching the detected stack (react-patterns, django-patterns, etc.).
5. Review in this order, skipping categories with no findings. Do not pad.

### 1. Correctness

Logic errors, edge cases, null and undefined handling, async pitfalls, race conditions.

### 2. Types (TypeScript or Python type hints)

Escape hatches (`any`, `unknown` with unsafe cast, `# type: ignore`), missing generics, inaccurate return types, runtime assumptions not expressed in types.

### 3. Accessibility

If UI changed: defer to the wcag-audit skill for depth. Only flag the obvious here (missing alt, missing label, broken keyboard path).

### 4. Security

If user input, auth, or external data involved: defer to security-patterns for depth. Flag obvious issues here.

### 5. Design principles

SOLID, DRY, KISS applied with judgment. Flag actual problems, not preferences. Duplication with divergent lifecycles is not a DRY violation.

### 6. Performance

React re-renders, bundle cost, N+1 queries, unbounded loops, missing pagination. Defer depth to perf audit if needed.

### 7. Maintainability

Names, abstractions, hidden coupling, implicit dependencies.

### 8. Tests

Did the change come with tests? Are the tests meaningful or shape-checking?

## Output

Use the markdown-report skill format. Write to `~/.claude/scratch/review-<project-name>-<scope-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Severity rubric from markdown-report. Skip sections with no findings. Summary line rates overall health.

## Rules

- Not every file needs a finding. An empty review is a valid result.
- Do not rewrite the code in the review. State the fix as instruction or small snippet.
- Do not flag personal style (semicolons, quote style, etc.) unless it violates the project's lint config.
