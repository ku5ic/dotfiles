---
description: WCAG 2.2 AA audit of a component, page, or template
argument-hint: <file path, component, or a link to an external tracker/doc>
model: claude-opus-4-8
disable-model-invocation: true
---

## Prerequisites

- $ARGUMENTS should specify the target (file, directory, or component name).
- Frontend surface must exist. If the repo context from your startup (`agent-context.sh`) reports no `js`, no `ruby` with rails, no `python` with django templates, and no HTML files: stop and say so.

## Procedure

0. Resolve external context per `rules/external-context.md`, using the a11y-auditor agent for lookups.

Delegate the procedure below (steps 1 onward, through Scope) to the a11y-auditor agent (Agent tool, subagent_type: a11y-auditor, foreground), passing the resolved arguments from step 0. It executes every step itself and writes the report; relay its returned summary.

1. Stack is in the repo context your startup produced (`agent-context.sh`). Get the scratch directory via `scratch-dir.sh`.
2. Confirm frontend surface exists. If not, stop.
3. Load the wcag-audit skill.
4. Read the target file(s):
   - For React, include the component's direct children if local.
   - For Django templates, include the parent template it extends.
5. Apply the checklist from wcag-audit. Stack adaptation section inside the skill tells you which variants apply.
6. Before finalizing a finding:
   - Check whether project CLAUDE.md documents an explicit, deliberate exception for it. That is the only thing that excuses it.
   - A pattern that repeats across multiple components is not excused by repetition.
   - Flag it once against the shared source and list every consuming location - fixing the shared component resolves all of them.
   - Repetition raises priority; it does not lower it.

## Output

Use the markdown-report format. Write to `$(scratch-dir.sh)/a11y-<target-slug>-<YYYYMMDD-HHMM>.md`.

Rules specific to this audit:

- Cite WCAG criterion on every finding (e.g. 1.3.1, 4.1.2).
- Distinguish Level A, AA, AAA if audit scope is AA: AAA findings go to "Out of scope" unless the user asked for them.
- Items that cannot be statically verified go to the "Cannot be verified statically" section. Do not fabricate verification.
- Print the report path.

## Scope

- Do not modify code during the audit. Audit only.
- Fixes are suggestions in the report, not applied changes.
