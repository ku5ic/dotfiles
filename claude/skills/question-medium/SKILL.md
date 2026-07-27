---
description: Answers a medium-difficulty question requiring real reasoning, verification, or stack-specific knowledge, but not deep architecture or long correctness chains. Use whenever the question is substantive but routine - not a lookup, not a novel architectural or multi-layer tradeoff - OR the user asks for a considered, verified answer without a full deep-dive, even if "medium" is not mentioned by name.
argument-hint: <the question>
effort: high
---

## When to load this skill

The question needs genuine reasoning, file or version verification, or stack-specific knowledge, but does not involve novel architecture, multi-layer debugging, or long correctness chains. This is the default for most substantive questions.

## When not to load this skill

Escalate to `/question-hard` when the reasoning chain is long, the tradeoffs are architectural, or a wrong answer is expensive. Drop to `/question-easy` for lookups and recall with a direct path to the answer.

## Procedure

1. Read the question precisely. If $ARGUMENTS is ambiguous on a point that changes the answer, ask one focused clarifying question before proceeding.
2. Verify before answering when the question warrants it. If it concerns a specific file, project, or repo, read the relevant files rather than assuming. If it concerns the current version, features, or API of a fast moving tool, check the lockfile or authoritative source.
3. If the stack matters: the `<repo-context>` block carries it when this runs inline; forked (no hook injection reaches the subagent), so absent that block, identify the stack from the project's own config directly. Load the matching patterns skill if the question is in that area.
4. Answer with the reasoning that supports it. Name a tradeoff or edge case when one is material; do not invent complexity that is not there.

## Output

Answer in chat. Not a deliverable command; no scratch artifact unless the user asks.

- Direct answer first, then the why.
- State assumptions if the answer rests on any.
- If something is unverified or unknown, say so rather than filling the gap with a plausible guess.

## Anti-patterns

- `failure`: answering an architectural or multi-layer question at this tier instead of escalating to `/question-hard` - underpowers a question where a wrong answer is expensive.
- `warning`: verifying nothing when the question referenced a specific file, version, or API - defaulting to memory instead of the check this tier requires.
- `warning`: over-reasoning a question that was actually a lookup - suggesting a downward escalation to `/question-easy` is fine.
- `info`: a tradeoff turned out not to be material after checking - correctly not naming one is not a violation.

## Rules

- Read-only. No edits, no destructive commands, no commits.
- Do not fabricate file paths, API shapes, version numbers, or behavior.
- Match effort to the question. Do not pad a simple answer; do not under-reason a real one.

## References

Internal tiering scheme, not external literature: see the `question` group entry in `~/.dotfiles/claude/CLAUDE.md`'s "Claude Code skills namespace" section for how easy/medium/hard map to model and effort.
