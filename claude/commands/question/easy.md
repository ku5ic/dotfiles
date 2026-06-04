---
description: Answer an easy question - lookup, recall, or a short factual answer
argument-hint: <the question>
model: sonnet
effort: low
---

## When to use

The question is a lookup, a recall, a definition, or a short factual answer where the path to the answer is direct. If the question needs real reasoning, verification across files, or a tradeoff call, use `/question:medium`. If it needs deep analysis, use `/question:hard`.

## Procedure

1. Answer directly. If the question concerns a specific file and you need its contents to answer, read it; otherwise do not reach for tools you do not need.
2. If the stack is relevant to the answer, it is in the injected `<repo-context>` block.
3. If the question turns out to be harder than easy (it needs verification, reasoning across layers, or a tradeoff call), say so and suggest re-running under `/question:medium` or `/question:hard` rather than guessing at this tier.

## Output

Answer in chat, concise. Not a deliverable command; no scratch artifact.

- Just the answer. No preamble, no padding, no closing summary.

## Rules

- Read-only. No edits, no destructive commands, no commits.
- Do not fabricate. If the answer is not known or not verifiable at this tier, say so and point to the right tier.
