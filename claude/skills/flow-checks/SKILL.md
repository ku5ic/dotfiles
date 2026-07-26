---
description: Run the project's verification checklist via run-checks.sh
argument-hint: <none>
model: sonnet
effort: low
disable-model-invocation: true
context: fork
agent: checker
---

## Procedure

1. Run `run-checks.sh`.
2. Report the trailing summary line (`checks: N passed, M failed, K skipped`). If any failed, also surface the file or label so the user knows where to look.

## Rules

- `run-checks.sh` owns runner detection. It runs only what the project defines (typecheck, lint, format-check, test across JS/TS, Python, Ruby, Rust, Go) and reports anything absent as `SKIP`.
- A `SKIP` is not a failure. If a check is missing entirely (no linter or type checker configured), do not introduce one as part of an unrelated task. If the gap matters to the current work, note it as a "Cannot be verified statically" item.
- Never declare a task complete with failing checks. A non-zero `failed` count means fix it or report and stop.

## On failure

State which check failed and the relevant output, then classify it: in the change just made, or pre-existing. Pre-existing and unrelated to the current work: surface it, do not auto-fix as part of the current task. Pre-existing and on the path of the current work: flag it and ask whether to expand scope to fix it. This skill only reports - whether to fix a failure in the change just made is the caller's decision, not this skill's.

## Stop

Stop after reporting. Do not fix failures unless explicitly asked.
