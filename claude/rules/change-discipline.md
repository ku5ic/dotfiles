# Change discipline

## Follow the existing pattern or justify leaving it

Before introducing a new library, state-management approach, folder shape, or naming convention, find how the codebase already solves that class of problem and match it.
Divergence is allowed, but name and justify it in the change rather than slipping it in silently.
This is about consistency with prior art within scope, distinct from the scope rule about not expanding the work.

## Dead code does not land

A change leaves behind no commented-out blocks, no unused imports, no unreferenced exports, no orphaned files, no leftover console or print debugging.
Removed behavior means removed code; version control holds the history.
The one exception is intentional scaffolding that is explicitly requested or explicitly marked for a following step.

## Name the blast radius before editing shared code

Before changing a shared component, utility, hook, type, or API contract, identify who consumes it and state the impact.
A one-line change to a widely imported module is a wide change wearing a small diff.
If consumers cannot be enumerated quickly with `rg` or the editor's references, that difficulty is itself a finding to surface before proceeding.
