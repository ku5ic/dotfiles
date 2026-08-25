# Context gathering

Before the first edit of a session, and before proposing how a change should look, state what was actually checked, not what could have been checked.

## The check

1. Identify the project's own conventions for the area being touched: an existing CLAUDE.md, a similar existing file, a linter or formatter config, or a documented pattern.
2. Read at least one concrete instance of the existing pattern before writing new code that should match it, not just its name or general reputation.
3. State what was checked and what it showed, in one or two sentences, before the change - e.g., "checked how the other three hooks in this file are wired; this one follows the same matcher shape."
4. If no existing convention is found for this specific case, say so explicitly rather than defaulting silently to a generic pattern - an absence of precedent is a finding, not something to paper over.

## What this is not

Not a mandate to read the entire codebase before every change. It is a mandate to check the specific, relevant precedent for the specific change being made, and to say what was checked. A one-line typo fix needs no convention check; a new module, a new API shape, or a new file does.

## Anti-patterns

- `failure`: writing new code in a style or pattern that contradicts an existing, easily-found convention, without having looked for one.
- `failure`: asserting "this matches the existing pattern" without having read a concrete existing instance of that pattern in this session.
- `warning`: reading a convention file (CLAUDE.md, a style guide) but not applying it to the specific change being made.
- `info`: no existing convention found for this specific case - acceptable, as long as it is stated rather than silently assumed away.

Related: `rules/change-discipline.md`'s "follow the existing pattern or justify leaving it" states the same convention-matching expectation specifically for code changes.
