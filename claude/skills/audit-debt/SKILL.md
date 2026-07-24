---
description: Surface technical debt and architectural risks with severity and remediation path
argument-hint: <file, directory, area name, or a link to an external tracker/doc>
model: sonnet
effort: high
disable-model-invocation: true
---

## Procedure

0. Resolve external context. If $ARGUMENTS contains a URL with little or no inline description, resolve it before anything else: identify which connected service the URL belongs to from its domain, use ToolSearch to find a matching fetch/read tool for that service (e.g. a URL under `app.clickup.com` points at the clickup tools, `notion.so` at the Notion tools, `github.com` at `gh` via Bash or the github tools), and call it to pull the content. Extract the relevant scope and requirements from what comes back. Treat the resolved text as the effective $ARGUMENTS for the rest of this procedure - never hand a bare link to the debt-auditor agent.

Delegate the procedure below (steps 1 onward, through Output file) to the debt-auditor agent (Agent tool, subagent_type: debt-auditor, foreground), passing the resolved arguments from step 0. It executes every step itself and writes the report; relay its returned summary.

1. Stack is in the repo context your startup produced (`agent-context.sh`). Get the scratch directory via `scratch-dir.sh`.
2. Load the patterns skill for the detected stack (react-patterns, django-patterns, etc.) for the anti-pattern reference.
3. Read the target. If $ARGUMENTS is a directory, run `tokei --sort code <path>` to get accurate line counts per language and per file. Read the 5 files with the highest code-line counts (excluding tests, generated files, and lockfiles), plus any `index.ts`, `main.py`, `urls.py`, `routes.ts` equivalents.
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
- **Metric thresholds breached**: files over 500 lines, functions over 50 lines, cyclomatic complexity (nested conditionals deeper than 3, branches greater than 7) in single functions, modules with more than 10 internal imports. Use `tokei` for size and a quick scan for the rest. Each is a smell, not a failure; the audit's value is correlating these with high churn from `git log`.

## Output per finding

- What it is
- Why it is a problem (scale, maintainability, correctness, security, performance, or operability)
- Severity: failure / warning / info (per markdown-report rubric; "failure" here means active liability, not future risk)
- Effort to remediate: small (hours), medium (days), large (weeks)
- Remediation: concrete first step

## Output file

Use markdown-report format. Write to `$(scratch-dir.sh)/debt-<target-slug>-<YYYYMMDD-HHMM>.md`. Print the path.

Sort findings by severity, then by effort (smallest first within each severity) so the quick wins are visible at the top.
