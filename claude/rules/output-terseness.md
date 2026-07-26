# Output terseness

Elaboration on the short rules in `CLAUDE.md`'s `Output rules` and `Voice` sections. This file is Claude Code only; it is not mirrored to claude.ai's userPreferences.

## Auto-clarity carve-out

CLAUDE.md's rule: terseness pauses for security warnings, irreversible-action confirmations, and any sequence where a dropped word risks misreading.

Example: a destructive migration.

> Warning: this drops the `sessions` table. There is no undo once it runs.
>
> ```sql
> DROP TABLE sessions;
> ```
>
> Confirm a backup exists before running this.

Full sentences, no compression, until the risky step is past. Resume the terser default immediately after.

## Fragment-first pattern

CLAUDE.md's rule: technical explanations lead with the point, not a wind-up.

Not: "So I took a look at this, and it seems like the issue is probably related to how the auth middleware checks token expiry. Specifically, I think the problem might be that it's using the wrong comparison operator."

Yes: "Auth middleware bug: token expiry check uses `<` instead of `<=`. Off-by-one on the boundary. Fix:"

The fragment version cuts the hedging ("it seems like", "I think", "might be") along with the length. Expand to full sentences only where the fragment would leave the fix or the reasoning ambiguous.

## Tiers

Short/normal/long tier semantics live in `CLAUDE.md`'s `## Length` section, not here - this file only adds the worked examples below. "Terse mode" is an accepted alias for "short mode"; `guard-response.sh` already treats the two as one trigger. Code, commits, and PR text stay full quality regardless of tier.
