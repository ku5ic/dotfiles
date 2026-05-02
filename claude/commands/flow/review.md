---
description: Senior review of recently changed code, stack aware
argument-hint: <optional: commit range, branch, or path>
model: opus
effort: high
---

**Effort: heavy.** Deep review. Read the changed files and their immediate context.

## Procedure

1. Get the project name: `!`project-name.sh``. Stack is in the injected `<repo-context>` block.
2. Mechanical-skip check. If the most recent plan for this project was marked `plan-shape: mechanical` and the implement step's verification passed cleanly (no failures recorded in the implement output), emit a one-line review ("verification passed, no findings, mechanical change per plan-<project-name>-<task-slug>-<HHMM>") and stop. Otherwise proceed to step 3.
3. If the diff exceeds 500 changed lines, propose splitting the review into logical chunks before starting.
4. Determine the review scope:
   - If $ARGUMENTS looks like a commit range (`main..HEAD`, SHA range): review that range
   - If $ARGUMENTS is a path: review that path's current state
   - Otherwise: review `git diff HEAD` (working copy)
5. Run `run-checks.sh` to establish baseline check state. Note any pre-existing failures before reviewing.
6. Load patterns skills matching the detected stack (react-patterns, django-patterns, etc.).
7. Review in this order, skipping categories with no findings. Do not pad.

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

### 8. Code metrics (statically inferable)

Flag findings, not opinions:

- Function size: any function over 50 lines, flag and ask if it earned its length.
- Cyclomatic complexity: nested conditionals more than three deep, or a function with more than seven distinct branches. These are smell thresholds, not hard limits.
- Coupling: a module that imports from more than ~10 internal modules, or a class with more than 7 public methods. Either smell, not failure.
- Cohesion: a class or module whose methods operate on disjoint subsets of fields suggests two responsibilities.
- File size: a file over 500 lines is a candidate for split unless the file is genuinely cohesive (a single config, a single large component with tight internal cohesion).

These are heuristics. Severity is `warning` unless the finding compounds with another category.

### 9. Verification and validation

- Verification (building it right): does the diff implement what the plan said? If the plan moved while implementing, was the plan updated? Drift between plan and code is a `warning`.
- Validation (building the right thing): does the change actually solve the problem stated? If the user asked for X and the change produces Y that is technically X but misses the underlying need, surface it.
- Traceability: can each behavior change in the diff be traced to a line in the plan? If a behavior appears in code but not in the plan, ask why.

### 10. Tests

Did the change come with tests? Are the tests meaningful or shape-checking?

## Output

Use the markdown-report skill format. Write to `~/.claude/scratch/review-<project-name>-<scope-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Severity rubric from markdown-report. Skip sections with no findings. Summary line rates overall health.

## Rules

- Not every file needs a finding. An empty review is a valid result.
- Do not rewrite the code in the review. State the fix as instruction or small snippet.
- Do not flag personal style (semicolons, quote style, etc.) unless it violates the project's lint config.
