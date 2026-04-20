---
description: Generate release notes from commits between two refs
argument-hint: <optional: from..to, defaults to last tag..HEAD>
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git describe:*), Bash(git diff:*)
model: haiku
---

**Effort: light.** Grouping and rewriting commits. Does not invent features.

## Procedure

1. Determine the range:
   - If $ARGUMENTS is a range: use it
   - Else: from last tag to HEAD: !`git describe --tags --abbrev=0 2>/dev/null` to `HEAD`
   - If no tags exist: last 30 commits on current branch
2. Pull the commit list: !`git log --oneline --no-merges <range>`
3. For conventional-commits-style history, group by type. Otherwise group by inferred category (user-facing, internal, tooling).
4. Filter out noise: formatting-only commits, CI-only changes, revert pairs that cancel out, chore commits with no user impact.
5. Rewrite each kept commit into a user-facing line. "fix: correct date parsing for non-ISO inputs" becomes "Dates in non-ISO formats now parse correctly."

## Output file

Write to `.claude/scratch/release-notes-<range-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Structure:

```
# Release <version or range>

## Added

<New user-visible capabilities. Imperative and clear. Omit if empty.>

## Changed

<Behavior changes that existing users will notice. Omit if empty.>

## Fixed

<Bug fixes that matter to users. Omit if empty.>

## Deprecated

<APIs or features marked deprecated. Omit if empty.>

## Removed

<Breaking removals. Call out loudly. Omit if empty.>

## Security

<Security-relevant fixes. Include CVE references if any. Omit if empty.>

## Internal

<Infrastructure, tooling, refactors that do not affect users. Keep short or omit.>
```

## Rules

- User-facing language. The audience is users of the project, not the authors.
- No AI signatures. No commit SHAs in the output unless the project convention includes them.
- Skip merge commits, formatting commits, and dependency bumps unless a bump is itself the release reason.
- If the range has nothing worth noting, say so and propose skipping the release.
- If a commit is ambiguous ("fix stuff", "wip"): flag it in an "Unclear" section rather than inventing intent.
