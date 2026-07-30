---
description: Reframe a technical finding or proposal for a non-technical audience
argument-hint: <technical content, or path to a file with it>
model: haiku
disable-model-invocation: true
context: fork
---

## Procedure

1. Get the scratch directory: `!`scratch-dir.sh``.
2. Read the input. If $ARGUMENTS looks like a file path, read the file. Otherwise treat $ARGUMENTS as the content directly.
3. Identify the audience implied by the input or default to PM-level.
4. Reframe.

## Output file

Write to `$(scratch-dir.sh)/stakeholder-<topic-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Structure:

```
# <Topic>

**Audience**: <CEO | PM | client | leadership>

## Situation

<What is going on, in plain language. No jargon unless defined.>

## Why it matters

<Business or user impact. Not the technical mechanism.>

## Options

<Only if there is a decision to make. One line per option with its tradeoff. Otherwise omit.>

## Recommendation

<What you propose, in one or two sentences, with the core reason.>
```

## Length guidance

- CEO brief: under 200 words total. One screen.
- PM writeup: 300 to 500 words.
- Client note: 200 to 300 words, more context on next steps.

## Rules

- Replace jargon with plain language without oversimplifying to the point of being inaccurate.
- Keep tradeoffs intact. Do not hide risk or complexity, just express it in outcomes.
- Tone: direct, professional, confident. Not apologetic, not hedged.
- Do not invent context. If something in the input is ambiguous, note it as an open question rather than guessing.
- No padding. If a section has nothing meaningful, omit it.
- Follows `rules/adhd-output.md`, no exception: each section short and chunked - a non-technical reader has the least patience for a wall of text.
