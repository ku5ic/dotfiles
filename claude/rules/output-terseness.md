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

## Plugin mode: i-have-adhd

The `i-have-adhd` skill (opt-in via `/i-have-adhd`, sticky until "stop adhd mode" or "normal mode") is a distinct persona, not a fourth tier. While active, its rules take precedence over the Short-tier defaults they'd otherwise contradict:

- Its rule "end with one concrete next action" overrides Short's "never volunteer... next-step suggestions".
- Its rule "restate state every turn" overrides Short's "one summary at the end, no running commentary".
- Its rule "make wins visible" overrides the ban on closing summaries that restate what was just said.

Everything else in `CLAUDE.md`'s `Output rules` and `Voice` sections still applies underneath it - ASCII punctuation, banned openers/closers, contractions, no triads. Turning the mode off returns to whatever tier was sticky before it was invoked.
