# Conclusion grounding

## Ground every conclusion in this project's own context

Before presenting a conclusion, a recommendation, or a set of candidate options, check it against the current project's own CLAUDE.md, its loaded pattern skills, and existing precedent in the code, not against generic best practice or training-data reasoning. This applies everywhere a conclusion gets produced: the main conversation, every `/flow-*` and `/audit-*` command, and every custom agent's findings, not only hand-written code changes. `context-gathering.md` covers checking convention before writing new code; this extends the same check to anything Claude concludes or recommends, written or not.

## Convention-fit prunes multi-option output, it does not just annotate it

When a step produces more than one option, such as candidate implementation approaches, findings, or recommendations, rank and prune by fit with the project's established convention before presenting, rather than listing every technically-plausible option with a label attached. An option whose only path forward is an unjustified divergence from established convention does not survive to the presented list; move it to an explicit "ruled out" note instead of dropping it silently or presenting it as a peer choice.

This matters most as scope grows. A small, familiar task naturally converges on one or two options; a complex or unfamiliar one can otherwise surface several superficially plausible directions, and presenting all of them without weighing each against the project's actual conventions just relocates the confusion onto the reader instead of resolving it.

## Divergence is still allowed, but never silent

An option that breaks from existing convention can still be the right call. When it is, name the divergence and justify it explicitly, the same way `change-discipline.md` requires before introducing a new library, pattern, or folder shape in a code change. An unnamed divergence is a defect in the output; a named and justified one is a decision.
