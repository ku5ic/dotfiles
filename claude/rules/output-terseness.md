# Output terseness

Elaboration on the short rules in `CLAUDE.md`'s `Output Rules` and `Output discipline`. This file is Claude Code only; it is not mirrored to claude.ai's userPreferences.

## Auto-clarity carve-out

CLAUDE.md's rule: terseness pauses for security warnings, irreversible-action confirmations, and any sequence where a dropped word risks misreading.

Example: a destructive migration.

> Warning: this drops the `sessions` table. There is no undo once it runs.
> ```sql
> DROP TABLE sessions;
> ```
> Confirm a backup exists before running this.

Full sentences, no compression, until the risky step is past. Resume the terser default immediately after.

## Fragment-first pattern

CLAUDE.md's rule: technical explanations lead with the point, not a wind-up.

Not: "So I took a look at this, and it seems like the issue is probably related to how the auth middleware checks token expiry. Specifically, I think the problem might be that it's using the wrong comparison operator."

Yes: "Auth middleware bug: token expiry check uses `<` instead of `<=`. Off-by-one on the boundary. Fix:"

The fragment version cuts the hedging ("it seems like", "I think", "might be") along with the length. Expand to full sentences only where the fragment would leave the fix or the reasoning ambiguous.

## Terse mode

On request ("terse mode", "shortest version", "just the answer"): compress further than the CLAUDE.md defaults. Drop remaining connective prose, answer in the fewest fragments that stay unambiguous, skip examples unless asked.

Code, commits, and PR text stay full quality regardless of mode.

Off on "normal mode" or "stop terse mode". Persists until then; no automatic revert after a topic change.

## Relation to Response length

`CLAUDE.md`'s `## Response length` section predates this file's `Terse mode` by name but not by intent: the four-line ceiling described there is the default floor-to-ceiling behavior for every response, not a target to approach. `Terse mode` compresses further below that default: fragments over sentences, no connective prose, examples dropped unless asked. `Terse mode` still requires an explicit request to turn on and stays on until explicitly turned off, exactly as described above.
