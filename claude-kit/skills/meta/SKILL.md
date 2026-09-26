---
description: Authoring and reflection - sharpen a prompt, refresh reference skills against current releases, or run a retrospective
argument-hint: <prompt|refresh|retro> [kind arguments]
disable-model-invocation: true
---

## Dispatch

The first word of the arguments is the kind; everything after it is the kind's arguments.

| Kind      | Procedure                                          |
| --------- | -------------------------------------------------- |
| `prompt`  | [references/prompt.md](references/prompt.md)       |
| `refresh` | [references/refresh.md](references/refresh.md)     |
| `retro`   | [references/retro.md](references/retro.md)         |

1. Missing or unknown kind: ask via AskUserQuestion with the kinds above as options.
2. Read the kind's reference file and follow it as the procedure.
3. In the reference, the `ARGUMENTS` token (written with a leading dollar sign) means everything after the kind word in the Arguments line below, and a backticked command prefixed with an exclamation mark means run that command via Bash and use its output.

Arguments: `$ARGUMENTS`
