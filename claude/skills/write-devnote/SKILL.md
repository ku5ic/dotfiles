---
description: Explain a completed change's key reasoning in a few sentences, developer to developer
argument-hint: <optional: which decision to focus on>
model: haiku
disable-model-invocation: true
---

## Procedure

1. Look at the current diff (`git diff` / `git diff --cached`) and the conversation so far.
2. Identify the one or two decisions that were not obvious from the diff alone:
   - An assumption got checked instead of trusted.
   - A simpler option was passed over for a reason.
   - Something turned out different from what was expected going in.

   Skip anything that's just "what changed" - the diff already says that.

3. If $ARGUMENTS names a specific decision, focus on only that one.
4. If nothing non-obvious happened (the change is mechanical, or the diff already speaks for itself), say so in one line instead of padding.

## Output

2-4 sentences. Plain language, developer to developer - assume the reader is a peer engineer who doesn't need the mechanism re-explained, just the reasoning. No headers, no bullet list, no restating the diff, no hedging, no "Summary:" preamble. Print directly to the terminal, not a file.

## Rules

- Say what turned out to be true and why, not what was built.
- If something was verified empirically instead of assumed, that's the interesting part - lead with it.
- Cut every sentence that's only there to sound complete.
- Voice: first person, as the developer who made the change - "I checked X, turned out Y" - never third-person narration of the change ("This commit does X", "The change adds Y").
- No AI language. Hard stop: no sycophantic openers/closers, no hedging filler ("it's worth noting", "basically"), no em dashes or smart quotes, no AI signatures. Must read like the developer wrote it, not like a summary of the developer's work.
- Follows `rules/adhd-output.md`, no exception: 2-4 sentences is already the chunk-sized form this rule wants, so the length cap and the rule reinforce each other, not two things to balance.
