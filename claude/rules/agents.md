# Agents

Elaboration on `CLAUDE.md`'s `## Agents` section.

## Model and effort pins

A skill or agent pins `model:`/`effort:` frontmatter only when it diverges from the session default in `settings.json` - not to restate it. `doctor.sh`'s frontmatter lint flags a pin equal to the session default as `redundant-pin`.

| Work type                                                | Where it runs         | Pin              |
| -------------------------------------------------------- | --------------------- | ---------------- |
| Design, critique, adversarial review, fault localization | inline skill or agent | `model: opus`    |
| Execution against a written spec                         | inline skill          | `effort: xhigh`  |
| Mechanical: grep, fetch, run a script                    | agent                 | `model: haiku`   |
| Prose from material already in hand                      | skill                 | `model: haiku`   |
| Mixed judgment and mechanical work                       | agent                 | no pin (inherit) |

A skill may set `model:` or `effort:`, never both - Claude Code silently drops the model override when both are present on a skill (upstream bug; agents are unaffected). `doctor.sh` enforces this as `model-effort-pair`.

## Spawn discipline

A subagent costs its own request budget against the 5h session window, so default to doing the work directly. Reach for one only when:

- The task matches an agent's specialty.
- It needs isolation from the main context (a broad multi-file sweep, a read-only audit).
- It genuinely parallelizes across independent items.

Not as a reflexive first move for something a single Read or Grep call would answer. Override for the built-in Explore-agent guidance: spawn `Explore` only past 5 unresolved queries, not 3.

## Nested delegation

An agent invoked via the Agent tool finishes its own task rather than spawning further subagents - this applies inside an agent's own execution, not just at the point the main session spawns one. Nested spawning is allowed only when all three hold:

- The delegating agent is a specialized one (a defined specialty in its own frontmatter), never a generic catch-all (`claude`, `general-purpose`).
- The sub-task genuinely falls outside the delegating agent's own tool grant or specialty - not a task it could do itself with the tools it already has.
- At most one subagent per invocation - no chains, no fan-out from inside an agent.

None of the agents under `claude/agents/` grant the `Agent` tool today, so this is a ceiling for future agent design, not a fix to an existing leak - the generic catch-alls are the only ones with wildcard tool access able to spawn at all, and they are exactly the case this rule tells to prefer doing the work directly.

## Two operational facts

1. Agents inherit the CLAUDE.md hierarchy and git status automatically, but do NOT receive the main session's `SessionStart` hook injection (`inject-context.sh`) - instead every subagent gets the same content via a `SubagentStart` hook (`inject-subagent-context.sh`, matcher `*`), per `rules/agent-shell.md`. `guard-skills` is the enforcement floor for reading or editing agents either way.
2. Forked skills (`context: fork`) run their whole body in a subagent; only `flow-checks` names one via `agent: <name>`. Most agent work instead comes from an inline skill body dispatching via the Agent tool, including `flow-implement`, which keeps its phase-boundary stops in the main conversation. `flow-plan` is forked (`context: fork`) despite using `AskUserQuestion` internally - its clarity-gate and Decisions steps follow the forked decision protocol below instead.

## Forked decision protocol

1. A forked skill has no access to the AskUserQuestion tool.
2. A step that would otherwise ask via AskUserQuestion instead stops and returns the question(s) and options under a `## Needs decision` heading, rather than guessing or silently deferring the answer in prose.
3. On a task-notification whose result carries that heading, ask the question(s) via AskUserQuestion in the main conversation, then resume the same agent via SendMessage with the resolved answer(s) so it can finish the rest of its procedure.

## Verify agent-claimed work before building on it

An agent's report describes what it intended to do, not necessarily what it did - a subagent can report a fully fabricated result (a convincing diff, passing tests, a clean lint run) for work that never happened. Before trusting "I changed/found X" enough to act on it:

- Claimed edits: `git status` or `git diff --stat` for the touched paths.
- Claimed findings: spot-check at least one cited `file:line` directly.

This is a cheap check against a real failure mode, not general distrust of every agent result - reserve it for claims you are about to build on (commit, report to the user, or hand to another agent), not every intermediate status update.
