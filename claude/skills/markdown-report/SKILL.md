---
name: markdown-report
description: Consistent format for audit reports, review output, and workflow artifacts including required sections, severity rubric (failure/warning/info), file naming convention, and summary line rubric. Use whenever a command writes a report to `~/.claude/scratch/` or `docs/`, OR the user asks for a structured audit, review, finding report, or any output requiring the failure/warning/info severity rubric, regardless of domain.
---

# Markdown report format

Use this structure for every report Claude writes to disk. Keep it tight. No padding.

## Required sections

```
# <Report type>: <target>

Generated: <ISO timestamp>
Scope: <file, component, or module>
Stack: <line from $HOME/.claude/bin/detect-stack.sh, if applicable>

## Summary

<One paragraph. What was checked, what was found, overall health in one word.>

## Findings

### <Finding title>

- Severity: <failure | warning | info>
- Location: <file>:<line> or <region>
- What: <problem in one or two sentences>
- Why it matters: <one sentence>
- Fix: <code snippet or concrete instruction>
- Refs: <WCAG criterion, CVE, doc link, etc., if relevant>

### <Next finding>
...

## Cannot be verified statically

<Items that need runtime checks, user testing, or external tools. Omit section if empty.>

## Out of scope

<Things noticed but not part of the task. Omit if empty.>
```

## Rules

- Severity is one of `failure`, `warning`, `info`. Nothing else. Do not invent new levels.
- Sort findings by severity, failures first.
- If a section would be empty, omit it. Do not leave placeholder text.
- Code snippets use fenced blocks with language tag.
- No ASCII decoration, no banner comments, no emoji.
- Use straight quotes, plain ASCII punctuation.
- File naming: `~/.claude/scratch/<kind>-<project-name>-<target-slug>-<YYYYMMDD-HHMM>.md`.
- `<project-name>` comes from `$HOME/.claude/bin/project-name.sh`. Slugified basename of git repo root.
- Always write to `~/.claude/scratch/` (home, absolute), never `.claude/scratch/` (cwd-relative).
- For kinds without a target slug, omit it: `<kind>-<project-name>-<YYYYMMDD-HHMM>.md`.
- Always print the absolute path at the end of execution so the user can open it.

## Summary line rubric

The "overall health in one word" at the end of the Summary helps quick scanning:

- `clean` (no findings)
- `minor` (only info)
- `moderate` (warnings, no failures)
- `serious` (failures present)
- `broken` (multiple critical failures, work should pause)
