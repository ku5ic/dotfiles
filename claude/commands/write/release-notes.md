---
description: Generate release notes from commits unique to the current branch vs its base
argument-hint: <optional: explicit range like main..HEAD, or base branch name>
allowed-tools: Bash(git log:*), Bash(git branch:*), Bash(git-base.sh:*)
model: haiku
---

**Effort: light.** Grouping and rewriting commits. Does not invent features.

## Context

Current branch: !`git branch --show-current`

Detected base: !`git-base.sh "$ARGUMENTS"`

Commits on this branch but not on the base: !`git log --oneline --no-merges "$(git-base.sh "$ARGUMENTS")..HEAD"`

## Procedure

1. Interpret $ARGUMENTS:
   - If it looks like an explicit range (`ref..HEAD`, `sha1..sha2`): trust it. Pull commits with `git log --oneline --no-merges $ARGUMENTS`.
   - If it is a single ref (e.g. `develop`): the Context block already used it as the base.
   - If empty: the Context block used the auto-detected base.
2. The commit list in the Context block is authoritative unless $ARGUMENTS specified an explicit range.
3. For conventional-commits-style history (subjects like `feat:`, `fix:`, `chore:`), group by type. Otherwise group by inferred category (user-facing, internal, tooling).
4. Filter out noise: formatting-only commits, CI-only changes, revert pairs that cancel out, chore commits with no user impact.
5. Rewrite each kept commit into a user-facing line. "fix: correct date parsing for non-ISO inputs" becomes "Dates in non-ISO formats now parse correctly."

## Output file

Write to `.claude/scratch/release-notes-<branch-or-range-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Structure:

```
# Release <branch or range>

Base: <detected base branch or explicit range>
Range: <base>..HEAD (N commits)

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
- If `git-base.sh` failed (exit 1, empty output): note that in the report and fall back to last 30 commits by running `git log --oneline --no-merges -30` explicitly.
