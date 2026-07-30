---
description: Security audit covering frontend and backend surface areas
argument-hint: <file, directory, area name, or a link to an external tracker/doc>
model: claude-opus-4-8
disable-model-invocation: true
---

## Procedure

0. Resolve external context per `rules/external-context.md`, using the security-auditor agent for lookups.

Delegate the procedure below (steps 1 onward, through Rules) to the security-auditor agent (Agent tool, subagent_type: security-auditor, foreground), passing the resolved arguments from step 0. It executes every step itself and writes the report; relay its returned summary.

1. Stack is in the repo context your startup produced (`agent-context.sh`). Get the scratch directory via `scratch-dir.sh`.
2. Load the security-patterns skill. Apply only the sections matching the detected stack.
3. Scope the target:
   - If $ARGUMENTS is a path: audit that path plus any adjacent auth, validation, or boundary code it depends on.
   - If $ARGUMENTS is empty: audit the diff from `main` to `HEAD`.
4. Pass 0: deterministic secret scan. Run `gitleaks detect --no-banner --redact -v --source . --log-level error` against the working tree. If $ARGUMENTS scopes to a path, narrow with `--source <path>`. Record findings as failure severity, citing file, line, and rule ID; gitleaks `--redact` masks the value. If nothing reported, note "gitleaks: no findings" and proceed to Pass 1.
5. Pass 1: look for the concrete anti-patterns listed in security-patterns (XSS, injection, missing validation, exposed secrets, bad CSP, CSRF gaps).
6. Pass 2: follow data flow for any user input found. Trace from entry point to every sink (DB, file system, template, response body). Flag unchecked paths.
7. Pass 3: check auth and session boundaries. Who is authenticated on this path? Who is authorized? Is either skipped anywhere?
8. Pass 4: dependency surface. If lockfile present, note whether `audit` has been run recently. Do not run audit yourself unless the user has allowed the command.
9. Before finalizing a finding, check whether project CLAUDE.md documents an explicit, deliberate accepted-risk decision for it - that is the only thing that excuses it. A vulnerable pattern that repeats across call sites is not excused by repetition; flag it once against the shared source (a shared auth helper, a common validator) and list every consuming location, since fixing the shared code resolves all of them and repetition raises priority, it does not lower it.

## Output

Use markdown-report format. Write to `$(scratch-dir.sh)/security-<target-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Severity rubric for security audits:

- **failure**: actively exploitable or direct secret exposure. Fix before merge.
- **warning**: mitigated but weak (e.g. CSP present but with `unsafe-inline`); or Level A of a broader defense in depth missing
- **info**: hardening opportunity, not currently exploitable

## Rules

- Do not attempt to exploit anything. Do not run payloads.
- Do not log secrets into the report. If you find one, say "secret present at <file>:<line>", not the value.
- If something needs runtime check (CSP headers in production, cookie flags from live response): say so in "Cannot be verified statically". Do not guess.
- If the scope is too large for a single pass: say so, recommend splitting, and audit the most exposed surface first (auth endpoints, user input handlers, admin screens).
