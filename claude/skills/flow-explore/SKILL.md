---
description: Survey requirements and implementation approaches for an obscure or under-specified task using parallel agents
argument-hint: <task description, however vague, or a link to an external ticket/doc>
model: opus
disable-model-invocation: true
context: fork
---

## When to use this

The ask is too thin or the codebase area too unfamiliar to shape a brief or a plan yet - a one-line request, a bare link to a ticket or doc with little inline description, or a task that touches a part of the codebase nobody here has mapped recently. The goal is a findings report surveying what the task likely needs and how it could be built, not a committed brief or plan.

Use `/meta-feature` instead when the ask is already clear enough to shape into acceptance criteria without codebase research.
Use `/flow-plan` instead when the task and a chosen approach are both already confirmed.

## Procedure

0. Resolve external context. If $ARGUMENTS contains a URL with little or no inline description, resolve it before anything else: identify which connected service the URL belongs to from its domain, use ToolSearch to find a matching fetch/read tool for that service (e.g. a URL under `app.clickup.com` points at the ClickUp tools, `notion.so` at the Notion tools, `github.com` at `gh` via Bash or the GitHub tools), and call it to pull the content. Treat the resolved text as the effective $ARGUMENTS for the rest of the procedure - never hand a bare link to a sub-agent. If no connected tool matches the URL's domain, say so and ask for the content pasted inline instead.

1. State the task in one sentence, your own words. Run the requirements-clarity check from `/flow-plan` (testable, unambiguous, complete, consistent) against it. Unlike `/flow-plan`, do not stop on a flag here - explore's job is to investigate the gap, not block on it. Carry every flag into the report.

2. Quick codebase skim: read project CLAUDE.md, grep for existing patterns that resemble the task, identify candidate modules or files. Keep this to a handful of tool calls - enough to name 2-4 plausible implementation directions, not the research itself. If nothing plausible turns up, say so and stop rather than manufacturing directions to fill the fan-out.

3. Fan out. For each candidate direction from step 2, dispatch one scout agent (Agent tool, subagent_type: scout) in the same message as the others so they run in parallel. Give each: the resolved task statement, the specific direction it owns, and instructions to report existing code touching that direction, relevant prior art, every finding cited `file:line`, and whether the direction matches or diverges from this project's established convention for this class of problem (per project CLAUDE.md and any loaded stack pattern skill), citing the precedent it matches or noting there is none. If the resolved input references an unfamiliar external library or API, dispatch one researcher agent (Agent tool, subagent_type: researcher) in the same fan-out message, giving it the specific library or URL and the claims to verify. If only one direction is plausible, dispatch one agent and say so plainly in the report - a single-path finding is a valid outcome, not a shortfall.

4. Synthesize, pruning by convention as you go. For each direction, turn its scout findings into a scope estimate (files/modules touched), a rough risk note, a convention-fit read (matches an existing pattern, or names a divergence with justification - per the project's own conventions, not generic best practice), and how well it addresses the task statement. A direction whose only path forward is an unjustified divergence from established convention does not make the candidate list - move it to Ruled out instead of presenting it as a peer option. This is what keeps the report short on a complex task: convention-fit prunes, it does not just annotate. Among the survivors this stays a survey, not a decision - do not pick a winner. Naming the strongest candidate when one clearly stands out is fine; committing to it with full tradeoffs is `/flow-plan`'s job.

5. Decisions. Any question that came up - which direction looks worth pursuing, a requirement that stayed ambiguous after research, scope that needs the requester's input - ask via the AskUserQuestion tool (multiple-choice, "Other" for free text). Record the resolved answers in the report's Decisions section. Do not leave an open-questions list. If forked, follow CLAUDE.md's forked decision protocol instead of guessing.

## Stop conditions

- No plausible direction found after the skim: report what was checked and stop, ask for more context instead of guessing.
- Investigation scope growing beyond the resolved task statement: surface and ask before expanding.
- A connected tool for a linked resource cannot be found: stop and ask for the content pasted inline.
- Every candidate gets ruled out on convention grounds and none survive: report the conflict between the task and established convention and ask before proceeding, rather than presenting only rejected options or picking one anyway.

## Output

Write a report to `$(scratch-dir.sh)/explore-<scope-slug>-<YYYYMMDD-HHMM>.md`:

```
# Explore: <one-line task>

Generated: <ISO timestamp>
Source: <resolved link, or "inline prompt">

## Task statement

<one or two sentences, your own words>

## Requirements clarity

<flags from the testable/unambiguous/complete/consistent check, or "no gaps found">

## Candidate approaches

### 1. <name>

- Scope: <files/modules>
- Findings: <scout summary, file:line citations>
- Risk: <one line>
- Convention fit: <matches existing pattern <name/citation>, or "no precedent found">
- Fit: <how well it addresses the task statement>

### 2. ...

## Ruled out on convention grounds

<name each: which existing pattern it would violate, unjustified. Omit section if none.>

## Open unknowns

<anything still unclear after research>

## Decisions

<questions resolved via AskUserQuestion, and the answer picked>

## Recommended next step

<"hand off to /meta-feature: <reason>" or "hand off to /flow-plan: <strongest candidate and why>">
```

Print the absolute path. Terminal output: the task statement, how many candidate approaches were found, and the recommended next step only. Everything else goes in the file.

## Stop

Do not shape a brief. Do not write a phased plan. Do not commit to one approach with full tradeoff analysis - that is `/flow-plan`, once a direction is confirmed.
