---
description: Answer a medium-difficulty question requiring real reasoning but not deep architectural analysis
argument-hint: <the question>
model: sonnet
effort: high
---

## When to use

The question needs genuine reasoning, file or version verification, or stack-specific knowledge, but does not involve novel architecture, multi-layer debugging, or long correctness chains. This is the default for most substantive questions. Escalate to `/question:hard` when the reasoning chain is long or a wrong answer is expensive; drop to `/question:easy` for lookups and recall.

## Procedure

1. Read the question precisely. If $ARGUMENTS is ambiguous on a point that changes the answer, ask one focused clarifying question before proceeding.
2. Verify before answering when the question warrants it. If it concerns a specific file, project, or repo, read the relevant files rather than assuming. If it concerns the current version, features, or API of a fast moving tool, check the lockfile or authoritative source.
3. If the stack matters, the stack is in the injected `<repo-context>` block. Load the matching patterns skill if the question is in that area.
4. Answer with the reasoning that supports it. Name a tradeoff or edge case when one is material; do not invent complexity that is not there.

## Output

Answer in chat. Not a deliverable command; no scratch artifact unless the user asks.

- Direct answer first, then the why.
- State assumptions if the answer rests on any.
- If something is unverified or unknown, say so rather than filling the gap with a plausible guess.

## Rules

- Read-only. No edits, no destructive commands, no commits.
- Do not fabricate file paths, API shapes, version numbers, or behavior.
- Match effort to the question. Do not pad a simple answer; do not under-reason a real one.
