# Conclusion grounding

Ground every conclusion, recommendation, and candidate list in this project's own CLAUDE.md, loaded pattern skills, and code precedent, not generic best practice. Applies wherever a conclusion is produced: main conversation, every `/flow-*` and `/audit-*`, every agent's findings.

Convention-fit prunes multi-option output before presenting, it does not just annotate it. An option whose only path forward is an unjustified divergence from established convention moves to an explicit "ruled out" note; it is not presented as a peer choice and not dropped silently.

Divergence is still allowed when it is the right call - named and justified, same as `change-discipline.md` requires for code. An unnamed divergence is a defect; a named and justified one is a decision.
