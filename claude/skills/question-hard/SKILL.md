---
description: Answers a hard question requiring deep reasoning, cross-layer analysis, or architectural judgment. Use whenever the question involves novel architectural tradeoffs, multi-layer debugging, subtle correctness or concurrency reasoning, or security or performance analysis with non-obvious interactions, OR the user asks for a rigorous, deep-dive, or high-stakes answer, even if "hard" is not mentioned by name.
argument-hint: <the question>
model: opus
context: fork
---

## When to load this skill

The question involves novel architectural tradeoffs, multi-layer debugging, subtle correctness or concurrency reasoning, security or performance analysis with non-obvious interactions, or anything where a wrong answer is expensive and the reasoning chain is long.

## When not to load this skill

If the question is routine, use `/question-medium` or `/question-easy` instead - reserve this tier for genuinely deep or high-stakes reasoning.

## Procedure

1. Restate the question internally as a precise problem, not as the user phrased it. If $ARGUMENTS is ambiguous on a point that changes the answer, ask one focused clarifying question before proceeding. Do not ask about points that do not change the answer.
2. Establish ground truth before reasoning. If the question concerns a specific file, project, or repo, read the relevant files. If it concerns the current state of a fast moving tool, framework, library, or API, verify against the lockfile or authoritative source. Do not answer architectural or version-sensitive questions from memory.
3. If the stack matters: the `<repo-context>` block carries it when this runs inline; forked (no hook injection reaches the subagent), so absent that block, identify the stack from the project's own config directly. Load the patterns skill matching it if the question is in that area.
4. Reason explicitly. Name the assumptions the answer rests on. Where there is a tradeoff, state both sides and the axis that decides between them. Where there is a risk or edge case, surface it rather than smoothing it over.
5. Separate what is established fact (read from source, verified) from what is inference. Mark inference as inference.

## Output

Answer in chat. This is not a deliverable command; do not write a scratch artifact unless the user asks for one.

- Lead with the direct answer to the question, then the reasoning behind it.
- Keep "what to do" separated from "why".
- State assumptions explicitly. If the answer depends on something unread or unverified, say so rather than guessing.
- For a recommendation, name the tradeoff and the conditions under which the other choice would win.

## Anti-patterns

- `failure`: reasoning from memory on an architectural or version-sensitive claim instead of verifying against source - the exact failure mode this tier exists to prevent.
- `failure`: presenting inference as established fact, or vice versa, without marking which is which.
- `warning`: invoking this tier for a question that turns out to be routine - note it and suggest `/question-medium` for next time rather than padding the answer to justify the tier.
- `info`: the reasoning chain turned out shorter than expected after establishing ground truth - a short correct answer at this tier is not a violation.

## Rules

- This is a read-only command. Do not edit code, do not run destructive commands, do not commit.
- Do not fabricate file paths, API shapes, version numbers, or behavior. "I have not verified this" is a valid and required answer when true.
- An honest "this depends on X which I have not read, confirm and I will continue" beats a confident wrong answer.

## References

Internal tiering scheme, not external literature: see the `question` group entry in `~/.dotfiles/claude/CLAUDE.md`'s "Claude Code skills namespace" section for how easy/medium/hard map to model and effort.
