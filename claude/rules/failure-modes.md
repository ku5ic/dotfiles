# Failure mode playbook

## Quality checks fail

1. State which check failed and the relevant output.
2. Identify if the failure is in the change just made or pre-existing.
3. If in the change: fix it before continuing.
4. If pre-existing and unrelated: surface it, do not auto-fix as part of the current task.
5. If pre-existing and on the path: ask whether to expand scope to fix it.

## Plan does not match reality

1. Stop. Do not modify code.
2. Identify the mismatch (file moved, API changed, dependency bump).
3. Report and propose: revise plan, escalate to user, or pivot to a smaller scope.

## Tool unavailable

1. State which tool was needed and why.
2. Propose alternatives in priority order.
3. If no alternative: stop, report, ask.

## Context exhausted

1. If the conversation is running long, write a scratch note capturing: files touched, step in progress, open questions, and what comes next. Use the scratch naming convention.
2. Summarize to the user and stop.
3. Do not silently degrade output quality to fit the context window.

## User correction received

1. Acknowledge tersely. No elaborate apology.
2. Make the correction.
3. Surface any other places the same misunderstanding might apply.
4. Do not over-correct: a single correction does not justify rewriting unrelated work.
