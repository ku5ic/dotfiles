---
name: fix-sizing
description: Right-sizes a bug fix to its actual defect before any edit lands, catching oversized blast radius and overengineered solutions early. Use whenever you are about to read or edit any file in the course of diagnosing, fixing, or patching reported behavior, OR the user asks about scope creep, overengineering, blast radius, or why a change touched more than expected, even if "fix-sizing" is not mentioned by name.
---

# Fix-sizing discipline

Before proposing or applying a fix, name the minimal change that resolves the reported defect, then compare it to what is actually about to be edited. When the two diverge, say so before touching code.

## The check

1. State the defect in one sentence: what is broken, observed how.
2. Name the minimal fix: the smallest change that would resolve exactly that defect, nothing else.
3. Compare the minimal fix to the fix about to be applied. If they match, proceed.
4. If the intended fix is larger - more files, new abstractions, adjacent refactors, unrelated cleanup - name the excess explicitly and the reason for it (e.g., "the minimal fix is one line, but it also requires updating three call sites because the function signature changes"). A named, justified excess is fine. An excess with no stated reason is not.
5. If the excess has no justification, stop and ask before proceeding, rather than shipping the larger version by default.

## What "minimal" means here

Minimal is measured against the defect, not against caution. A one-line fix to a one-line bug is minimal. A one-line fix to a bug that is a symptom of a genuinely broken abstraction is not minimal if it papers over the real problem - in that case the right-sized fix might legitimately be larger, and that is the justification to state, not skip past.

## Anti-patterns

- `failure`: touching files unrelated to the reported defect without naming why, in the same change.
- `failure`: introducing a new abstraction (interface, config layer, helper module) to fix a single call site, without stating why the abstraction is needed now rather than when a second call site appears.
- `warning`: refactoring the surrounding code "while in there" as part of a bug-fix change.
- `warning`: describing a fix as "cleanup" or "improvement" when the actual ask was a specific defect.
- `info`: a fix that is smaller than expected because the defect was smaller than it first appeared - not a violation, just worth noting when it happens.

## When to load this skill

- Before the first edit of any session (enforced globally, regardless of file type).
- Any bug fix, patch, or "make X work" request, before deciding what to touch.
- A proposed diff is growing beyond the file or function the bug report named.

## When not to load this skill

- Pure feature work with no reported defect - sizing a net-new feature is a scoping conversation, not this check.
- Refactors explicitly requested as refactors, not fixes - the "minimal fix" framing does not apply when there is no defect to be minimal against.

## Maintenance note

Revisit if "minimal fix" needs a more concrete measure than judgment (e.g., a file-count threshold) after observing this in practice.
