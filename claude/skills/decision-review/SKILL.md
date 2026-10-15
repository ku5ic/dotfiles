---
name: decision-review
description: Challenge a proposed or finished change the way a senior reviewer would, decision first and code second. Works on a plan, an investigation report, a ticket, a diff, or a PR, and is most useful before the change is written. Use when the user says "decision review", "review the decision", "what would a reviewer ask", "what will the reviewer push back on", "challenge this plan/report/PR", "poke holes in this", "is this change needed", or "pre-review before I ask for review". Read-only, never edits or posts.
argument-hint: "[plan or report path | ticket URL | PR number | branch | nothing]"
---

## Inputs

Resolve the artifact, first match wins:

1. A file path: a plan or a report.
2. A ticket URL: fetch it with the matching connector.
3. A PR number or branch: `gh pr view <n> --json title,body,files` and `gh pr diff <n>`.
4. Nothing: the current plan file in plan mode, else the newest report in `kit scratch-dir`, else `kit git-base --diff`.

If the artifact links a ticket, fetch that too; the "why" lives there. Read the project's CLAUDE.md and load the pattern skills it suggests.

ADRs, when they exist: run `adr list` from the repo root if it has an `.adr-dir`, else from `~/architecture/<repo-name>`. `rg` them for the units and terms the artifact touches; a hit feeds steps 2 and 4.

Mode follows the input:

- **Pre-change** (plan, report, ticket): check against the files and symbols the artifact names, read from the repo.
- **Post-change** (diff, PR): check against the diff.

## Decision pass (blocking)

Run in this order. Answer each from the repo first; only what the repo can't answer becomes a question.

1. **Purpose.** Is the why stated in one human sentence? Is the change needed at all?
2. **What changes vs before.** Compare current and proposed behavior: what's shown, hidden, or allowed, and under which conditions. `git log -S` or blame on the old behavior to learn why it existed before replacing it.
3. **Blast radius and root cause.** Count consumers of every shared unit touched: `kit blast-radius` for JS/TS and Python, an `ast-grep` call or import pattern for other languages, `rg` as the last fallback. Is the fix at the root, or in a shared layer whose other callers aren't broken?
4. **Domain meaning.** Which fields, states, or terms does the change assume a meaning for? Are they used that way elsewhere?
5. **Existing solution.** Does the repo already have something that does this?
6. **Usage.** Does every new export, option, or field have a consumer in this change?
7. **Breaking it.** List cases to try in the running thing: lots of data and none, state transitions, repeat and retry, interruption, small screens or non-TTY output. Don't run them. Pre-change: does the plan's verification cover them?
8. **Scope and dependencies.** Does part of this belong in a ticket, an upstream change, or a redesign? Is an upstream contract or design the change relies on actually in place?

## Convention pass (non-blocking)

Only from the project's own rules, CLAUDE.md, and loaded pattern skills, never generic taste. One line each, prefixed "a nit", with the replacement for a rename. Pre-change, check only the paths, names, and structure the artifact proposes.

## Filter

Drop every question the repo or the artifact already answers. Keep 3 to 7 blocking questions. Fewer is fine when the change is sound.

## Output

Terminal only, no file. Blocking questions first, then nits. Anchor each to `file:line` (post-change) or the artifact's section or step (pre-change). End with one verdict line:

- Post-change: `LGTM, a few non blocking nits` / `LGTM, but <blocker>` / `let's discuss first: <decision>`
- Pre-change: `go` / `go after: <question>` / `let's discuss first: <decision>`

Pre-change example:

```text
step 2: why a new cache layer? the list endpoint already returns etag, is it enough to use it?
step 3: the plan changes the shared formatter, 14 callers use it and only one is broken. I'd rather fix it in the caller, wdyt?
context: the old behavior hid archived items on purpose (commit a1b2c3, "hide archived from export"). is that still wanted?
verification: no case for an empty list or a slow upstream

a nit, step 2: the new module name doesn't follow the folder naming in CLAUDE.md

let's discuss first: cache layer vs etag
```

Post-change example:

```text
report/export:42 previously the export action was hidden for read-only users, now it's shown but disabled. intended?
report/export:88 the new include-drafts option is added but nothing passes it
what happens with 10k rows? the old version paginated

a nit, report/export:12 the comment restates the code, I'd remove it

LGTM, but the read-only case
```

## Voice

Lowercase, short, one concern per line. Questions over commands. "IMO", "wdyt", "I'd rather", "a nit". Concede when the artifact already answers a point ("I see, makes sense"). No lecture, no praise, no summary of the change.

## Stop

Read-only. Never edit, never comment on a PR or ticket, never approve.
