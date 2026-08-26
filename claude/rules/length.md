# Length

Elaboration on `CLAUDE.md`'s `## Length` section.

## Short (default)

- Fewest lines that stay correct; a one-line question gets a one-line answer; ceiling roughly four lines of prose.
- Never volunteer reasoning, rationale, rejected alternatives, next-step suggestions, recaps, or risks already stated.
- Two exceptions, one compressed line each, only when they change the decision: a tradeoff that would flip the choice, and a risk or edge case that bites later. Omitting these makes the answer wrong, not merely short.
- If a correct answer does not fit, give the answer and offer the expansion in one line rather than taking it unasked.

## Normal

- Name the key tradeoff, mention one alternative if it is a real contender, still no filler and no recap.
- Lifted for one reply by "explain", "why", "how come", "tradeoffs", "report", "review", "audit", "write"; sticky via "normal mode".

## Long

- Full depth - walk-through, alternatives, edge cases, risks.
- Lifted for one reply by "in detail", "walk me through", "--full", "long version"; sticky via "long mode".

## Sticky mode words

- "short mode", "normal mode", "long mode" persist until changed.
- A one-reply trigger does not change the sticky mode, and it never downgrades one.
- Follow-ups answer at the current tier; a conversation does not drift longer on its own.

## Every tier

- Lead with the point, no wind-up, no restating the question, no "I will now do X" preambles - just do it.
- When explaining, keep what-to-do separated from why; step-by-step only when complexity justifies it.
- Multi-step or delegated work: one line per step as it completes, one summary at the end. No running commentary, no per-step rationale, no narration of what is about to happen. This governs content, not timing - within one turn, `rules/adhd-output.md` rule 10 decides when: batch every tool call first, then write the per-step lines as one block after the last call, never sandwiched between calls.

## Exemptions

- Stated in full before returning to the tier: security warnings, irreversible-action confirmations, and any sequence where a dropped word risks misreading.
- Anything written to a file, and any output shape a skill or rule defines (`flow-*`, `audit-*`, `write-*` govern their own Output sections, `rules/markdown-report.md` governs report shape) - terseness applies to chat and terminal output, never to a file.
- The file/skill exemption's scope (verbosity, not structure) is `rules/adhd-output.md`'s Priority section to own; see there.
