# Length

Elaboration on `CLAUDE.md`'s `## Length` section.

## Short (default)

- Fewest lines that stay correct; a one-line question gets a one-line answer; ceiling roughly four lines of prose.
- Never volunteer reasoning, rationale, rejected alternatives, tradeoffs, caveats, risks already stated, next-step suggestions, or recaps.
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
- Multi-step or delegated work: one line per step as it completes, one summary at the end. No running commentary, no per-step rationale, no narration of what is about to happen.

## Exemptions

- Stated in full before returning to the tier: security warnings, irreversible-action confirmations, and any sequence where a dropped word risks misreading.
- Anything written to a file, and any output shape a skill defines (`flow-*`, `audit-*`, `write-*`, `markdown-report` govern their own Output sections) - terseness applies to chat and terminal output, never to a file.
- The file/skill exemption covers verbosity only; `rules/adhd-output.md`'s structural rules still apply regardless of medium.
