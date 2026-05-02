---
description: Resume a partially executed plan from a scratch file
argument-hint: <optional: scratch path or task slug>
model: sonnet
effort: medium
---

**Effort: light.** Reorientation, not work.

## Procedure

1. Get the project name: `!`project-name.sh``.
2. If $ARGUMENTS specifies a path, read it. Otherwise, find the most recent plan or feature brief for this project: `ls -t ~/.claude/scratch/plan-<project-name>-*.md ~/.claude/scratch/feature-<project-name>-*.md 2>/dev/null | head -1`.
3. Diff the plan against current code state:
   - Which steps are done (via git log on touched files since the plan timestamp)
   - Which are partially done (working copy changes)
   - Which are not started
4. Report status. Do not implement.
5. Recommend the next concrete action.

## Output

Terminal only:

- Plan being resumed (title, file path)
- Step status: done | partial | pending
- Recommended next action
- Open questions surfaced from the plan that need answers before continuing
