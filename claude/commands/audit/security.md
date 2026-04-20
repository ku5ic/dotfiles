---
description: Security audit covering frontend and backend surface areas
argument-hint: <file, directory, or area name>
allowed-tools: Read, Grep, Glob, Bash($HOME/.claude/bin/detect-stack.sh), Bash(git log:*), Bash(git grep:*)
---

**Effort: heavy.** Defensive review. Assume any input from outside the process boundary is hostile.

## Procedure

1. Run `!`$HOME/.claude/bin/detect-stack.sh``.
2. Load the security-patterns skill. Apply only the sections matching the detected stack.
3. Scope the target:
   - If $ARGUMENTS is a path: audit that path plus any adjacent auth, validation, or boundary code it depends on.
   - If $ARGUMENTS is empty: audit the diff from `main` to `HEAD`.
4. Pass 1: look for the concrete anti-patterns listed in security-patterns (XSS, injection, missing validation, exposed secrets, bad CSP, CSRF gaps).
5. Pass 2: follow data flow for any user input found. Trace from entry point to every sink (DB, file system, template, response body). Flag unchecked paths.
6. Pass 3: check auth and session boundaries. Who is authenticated on this path? Who is authorized? Is either skipped anywhere?
7. Pass 4: dependency surface. If lockfile present, note whether `audit` has been run recently. Do not run audit yourself unless the user has allowed the command.

## Output

Use markdown-report format. Write to `.claude/scratch/security-<target-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Severity rubric for security audits:

- **failure**: actively exploitable or direct secret exposure. Fix before merge.
- **warning**: mitigated but weak (e.g. CSP present but with `unsafe-inline`); or Level A of a broader defense in depth missing
- **info**: hardening opportunity, not currently exploitable

## Rules

- Do not attempt to exploit anything. Do not run payloads.
- Do not log secrets into the report. If you find one, say "secret present at <file>:<line>", not the value.
- If something needs runtime check (CSP headers in production, cookie flags from live response): say so in "Cannot be verified statically". Do not guess.
- If the scope is too large for a single pass: say so, recommend splitting, and audit the most exposed surface first (auth endpoints, user input handlers, admin screens).
