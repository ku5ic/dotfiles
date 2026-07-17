---
name: context-gathering
description: Confirms project conventions, existing patterns, and relevant rules were actually checked before a change lands, not just available to check. Use whenever you are about to read or edit any file in a repo for the first time this session, OR the user asks why a change does not match existing conventions, style, or established patterns, even if "context" is not mentioned by name.
---

# Context-gathering discipline

Before the first edit of a session, and before proposing how a change should look, state what was actually checked, not what could have been checked.

## The check

1. Identify the project's own conventions for the area being touched: an existing CLAUDE.md, a similar existing file, a linter or formatter config, or a documented pattern.
2. Read at least one concrete instance of the existing pattern before writing new code that should match it, not just its name or general reputation.
3. State what was checked and what it showed, in one or two sentences, before the change - e.g., "checked how the other three hooks in this file are wired; this one follows the same matcher shape."
4. If no existing convention is found for this specific case, say so explicitly rather than defaulting silently to a generic pattern - an absence of precedent is a finding, not something to paper over.

## What this is not

This is not a mandate to read the entire codebase before every change. It is a mandate to check the specific, relevant precedent for the specific change being made, and to say what was checked. A one-line typo fix needs no convention check; a new module, a new API shape, or a new file needs one.

## Anti-patterns

- `failure`: writing new code in a style or pattern that contradicts an existing, easily-found convention, without having looked for one.
- `failure`: asserting "this matches the existing pattern" without having read a concrete existing instance of that pattern in this session.
- `warning`: reading a convention file (CLAUDE.md, a style guide) but not applying it to the specific change being made.
- `info`: no existing convention found for this specific case - acceptable, as long as it is stated rather than silently assumed away.

## When to load this skill

- Before the first edit of any session (enforced globally, regardless of file type).
- Adding a new file, module, or pattern where an existing equivalent might already exist in the codebase.
- The user asks why something does not match existing style or conventions.

## When not to load this skill

- A change with no plausible existing precedent to check, e.g. the very first file of its kind in a brand-new repo.
- Pure data or content edits with no structural or stylistic choice involved, e.g. fixing a typo in prose.
- These exclusions describe when the check has nothing to add, not an exemption from the global first-operation load: the session-start gate loads this skill unconditionally regardless of task type.

## References

Related: `~/.dotfiles/claude/rules/change-discipline.md` - "Follow the existing pattern or justify leaving it" states the same convention-matching expectation specifically for code changes.

## Maintenance note

Revisit if "relevant precedent" needs a more concrete definition than judgment (e.g., a required minimum number of files checked) after observing this in practice.
