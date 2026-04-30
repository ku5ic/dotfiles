---
description: Run the project's verification checklist via run-checks.sh
---

**Effort: light.** Wrapper. Reports pass/fail and stops.

## Procedure

1. Run `!`$HOME/.claude/bin/run-checks.sh``.
2. Report the trailing summary line (`checks: N passed, M failed, K skipped`). If any failed, also surface the file or label so the user knows where to look.

## Stop

Stop after reporting. Do not fix failures unless explicitly asked.
