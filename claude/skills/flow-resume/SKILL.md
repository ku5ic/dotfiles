---
description: Resume a partially executed plan from a scratch file
argument-hint: <optional: scratch path or task slug>
model: sonnet
effort: low
disable-model-invocation: true
---

## Procedure

1. Get the scratch directory: `!`scratch-dir.sh``.
2. If $ARGUMENTS specifies a path, read it. Otherwise, find the most recent plan or feature brief: `ls -t "$(scratch-dir.sh)"/plan-\*.md "$(scratch-dir.sh)"/feature-\*.md 2>/dev/null | head -1`.
3. Diff the plan against current code state:
   - Which steps are done (via git log on touched files since the plan timestamp)
   - Which are partially done (working copy changes)
   - Which are not started
4. Report status. Do not implement.
5. Recommend the next concrete action.

## Before context runs out

This is the complementary case to resuming: acting early enough that a resume is easy. If the conversation is running long, before it exhausts, write a scratch note capturing files touched, the step in progress, open questions, and what comes next - use the scratch naming convention. Summarize to the user and stop; do not silently degrade output quality to fit the remaining window. This note is what a later `/flow-resume` reads to pick the work back up.

## Output

Terminal only:

- Plan being resumed (title, file path)
- Step status: done | partial | pending
- Recommended next action
- Any open question surfaced from the plan: ask it via the AskUserQuestion tool (multiple-choice, "Other" for free text) as part of this report, then fold the answer into the recommended next action. If forked, follow CLAUDE.md's forked decision protocol instead of guessing.
