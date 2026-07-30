---
description: Answers an easy question - a lookup, recall, or short factual answer with a direct path to the answer. Use whenever the question needs no cross-file verification, reasoning chain, or tradeoff call, OR the user explicitly asks for a quick, low-effort, or shallow answer, even if "easy" is not mentioned by name.
argument-hint: <the question>
effort: low
---

## When to load this skill

The question is a lookup, a recall, a definition, or a short factual answer where the path to the answer is direct.

## When not to load this skill

If the question needs real reasoning, verification across files, or a tradeoff call, use `/question-medium` instead. If it needs deep analysis, cross-layer reasoning, or architectural judgment, use `/question-hard`.

## Procedure

1. Answer directly. If the question concerns a specific file and you need its contents to answer, read it; otherwise do not reach for tools you do not need.
2. If the stack is relevant to the answer:
   - Running inline: the `<repo-context>` block carries it.
   - Forked (no hook injection reaches the subagent), so that block is absent: identify the stack from the project's own config (`package.json`, `pyproject.toml`, etc.) instead.
3. If the question turns out to be harder than easy (it needs verification, reasoning across layers, or a tradeoff call), say so and suggest re-running under `/question-medium` or `/question-hard` rather than guessing at this tier.

## Output

Answer in chat, concise. Not a deliverable command; no scratch artifact.

- Just the answer. No preamble, no padding, no closing summary.

## Anti-patterns

- `failure`: answering from assumption when the question actually needed a file read or a version check - a confidently wrong shallow answer is worse than escalating.
- `warning`: reasoning through a tradeoff or multi-step chain at this tier instead of escalating to `/question-medium` or `/question-hard`.
- `info`: the question turned out to be a genuine lookup after all - staying at this tier was correct, not a sign the check was unnecessary.

## Rules

- Read-only. No edits, no destructive commands, no commits.
- Do not fabricate. If the answer is not known or not verifiable at this tier, say so and point to the right tier.

## References

Internal tiering scheme, not external literature: see the `question` group entry in `~/.dotfiles/claude/CLAUDE.md`'s "Claude Code skills namespace" section for how easy/medium/hard map to model and effort.
