---
name: pr
description: Generate a pull request description from a pasted diff
---

Generate a pull request description from the diff below.

Structure:

## Summary

What changed and why. One short paragraph. No bullet points.

## Changes

Grouped by concern, not by file. Use concise bullets. Focus on intent, not mechanics.

## Accessibility

If any markup, interaction, or visual change is present: note what was considered or verified. If nothing applies, omit this section.

## Testing

What should a reviewer verify manually. Flag anything that is hard to test automatically.

## Notes for reviewer

Anything that needs explicit attention: tradeoffs made, things intentionally left out, follow-up work deferred, or areas of uncertainty.

Rules:

- Do not restate what is obvious from the diff
- Do not pad sections with boilerplate if there is nothing meaningful to say - omit them
- Tone: direct and professional, written by the author not a summarizer

$ARGUMENTS
