# Agent shell boilerplate

## Startup

Repo context and `<required-skills>`/`<suggested-skills>` tagged blocks arrive automatically via `settings.json`'s `SubagentStart` hook (`inject-subagent-context.sh`, matcher `*`) - no manual `agent-context.sh` step for any agent, including ones without Bash (hooks run in the harness, independent of the subagent's own tool grants). An agent whose job doesn't need repo context (`checker`, `researcher`) can just ignore the injected block.

## Read-only boundary

Edit/Write exist only for memory and scratch report; never touch project source; state fixes as instructions.

## Output

Follow the invoking skill's format and path; long output: named scratch path plus a short digest.
