---
description: Surface technical debt and architectural risks with severity and remediation path
argument-hint: <file, directory, area name, or a link to an external tracker/doc>
effort: high
disable-model-invocation: true
---

## Procedure

0. Resolve external context per `rules/external-context.md`, using the debt-auditor agent for lookups.

Delegate the procedure below (steps 1 onward, through Output file) to the debt-auditor agent (Agent tool, subagent_type: debt-auditor, foreground), passing the resolved arguments from step 0. It executes every step itself and writes the report; relay its returned summary.

1. Stack is in the repo context your startup produced (`agent-context.sh`). Get the scratch directory via `scratch-dir.sh`.
2. Load the patterns skill for the detected stack (react-patterns, django-patterns, etc.) for the anti-pattern reference.
3. Read the target.
   1. If $ARGUMENTS is a directory, run `tokei --sort code <path>` to get accurate line counts per language and per file.
   2. Read the 5 files with the highest code-line counts (excluding tests, generated files, and lockfiles).
   3. Read any `index.ts`, `main.py`, `urls.py`, `routes.ts` equivalents.
4. Run `git log --oneline -20` on the target to see recent churn. High-churn files are candidates for higher-priority debt.
5. Evaluate across these categories. Skip categories with no findings. Do not pad.

### Categories

- **Architecture**: inappropriate coupling, missing abstraction boundaries, layer violations, circular dependencies
- **Type safety**: escape hatches, runtime assumptions not in types, unsafe casts, `any` in public surface
- **State management**: local state that should be lifted, global state that should be local, derived state stored instead of computed
- **Side effects**: unguarded async, missing cleanup, implicit ordering, hidden I/O
- **Scalability**: works now, breaks at scale (data size, user count, team size)
- **Testing debt**: core paths with no tests, brittle tests, untestable designs
- **Security debt**: authn/authz gaps, input validation, exposed secrets, dependency CVEs (if easy to check)
- **Observability debt**: silently swallowed errors, no logging on critical paths, no telemetry where it matters
- **Dead code and duplication**: unused exports, copy-paste logic with divergent lifecycles
- **Build and dependency health**: deprecated APIs, ejected config, outdated patterns, unmaintained deps
- **Metric thresholds breached**: use `tokei` for size and a quick scan for the rest. Each is a smell, not a failure; the audit's value is correlating these with high churn from `git log`.
  - Files over 500 lines
  - Functions over 50 lines
  - Cyclomatic complexity: nested conditionals deeper than 3, or branches greater than 7, in a single function
  - Modules with more than 10 internal imports

## Output per finding

- What it is
- Why it is a problem (scale, maintainability, correctness, security, performance, or operability)
- Severity: failure / warning / info (per markdown-report rubric; "failure" here means active liability, not future risk)
- Effort to remediate: small (hours), medium (days), large (weeks)
- Remediation: concrete first step

## Output file

Use markdown-report format. Write to `$(scratch-dir.sh)/debt-<target-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Sort findings by severity, then by effort (smallest first within each severity) so the quick wins are visible at the top.

## Rules

- Findings follow `rules/critique.md`: provenance-labeled, report what holds too.
