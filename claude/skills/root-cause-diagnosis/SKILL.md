---
name: root-cause-diagnosis
description: Determines whether a failure is a defect in a dependency (a third-party library, an internal shared module, or any package the current code does not own) or a misuse of it, before proposing a fix, so the fix lands at the right layer. Use whenever a bug involves a library, framework, or internal shared module behaving unexpectedly, OR the user asks whether something is "a bug in the library" versus "how we're using it," even if "root cause" is not mentioned by name.
---

# Root-cause diagnosis discipline

Before fixing a bug that involves a dependency - a third-party library, an internal shared module, or any package this code does not own - determine whether the failure is a defect in that dependency or a misuse of it. Name which one it is before writing the fix.

## The check

1. Read the dependency's actual contract for the behavior in question: its documentation, type signatures, or source, not memory or assumption.
2. Compare the observed failure against that contract. Does the call site match the documented usage: correct arguments, correct order, correct version, correct configuration?
3. If the call site deviates from the contract, this is misuse. Fix the call site, not the dependency.
4. If the call site matches the contract and the dependency still misbehaves, this is a candidate defect. Check the dependency's issue tracker or changelog for a known, matching report before concluding it is a fresh bug.
5. If diagnosis is genuinely inconclusive after steps 1-4, say so explicitly rather than picking a fix at random:
   - The contract is ambiguous.
   - The behavior is undocumented.
   - A minimal reproduction is needed and has not been built yet.

   A stated "inconclusive, here is what a reproduction would need to confirm" is a valid outcome of this check.

6. State the diagnosis - misuse or defect, and the evidence for it - before proposing the fix. The fix location follows from the diagnosis:
   - Misuse: fix the call site.
   - Genuine defect: a workaround at the boundary, isolated rather than spread through the codebase, plus a note that it is a workaround and not a permanent fix.

## Scope

This applies to any dependency the current code does not own or control: a third-party package pulled from a registry, and an internal shared module or package within a monorepo, alike. The same misdiagnosis risk, fixing the wrong layer, applies to both; ownership boundary, not registry origin, is what matters.

## Failing tests after a refactor

The same misuse-vs-defect question applies to a test that starts failing after a refactor, with the test itself as the dependency under suspicion:

1. Do not silently adjust the assertion to match the new output. That is fixing the wrong layer without a diagnosis.
2. Ask whether the behavior the test asserts on actually changed on purpose. A test asserting on user-visible output (error messages, API responses, returned values) is almost always guarding real behavior, not incidental detail.
3. State the diagnosis before touching either side: "intentional behavior change, update the test" or "production code broke, fix the code" - the same explicit call this skill requires for a dependency defect.

## Anti-patterns

- `failure`: patching around unexpected dependency behavior in application code without first checking the dependency's documented contract for that behavior.
- `failure`: assuming "it's a library bug" without checking the issue tracker or changelog for a known, matching report.
- `warning`: treating a workaround for a genuine dependency defect as the permanent fix, with no note that it should be revisited when the dependency is patched.
- `warning`: skipping this check because the dependency is "probably fine" - a fix aimed at the wrong layer costs more to unwind later than the diagnosis costs now.
- `info`: diagnosis concludes misuse more often than defect - expected; most "library bugs" are usage errors, not evidence the check is unnecessary.

## When to load this skill

- Before the first edit of any session (enforced globally, regardless of file type).
- Any bug report that involves a third-party library, framework, or internal shared module behaving unexpectedly.
- Before adding a workaround, polyfill, or monkey-patch for dependency behavior.

## When not to load this skill

- Bugs entirely within code this session owns and controls, with no dependency involved.
- Feature work with no reported failure to diagnose.
- These exclusions describe when the check has nothing to add, not an exemption from the global first-operation load: the session-start gate loads this skill unconditionally regardless of task type.

## References

Repo-specific discipline, not a citation of external literature. The closest documented parallel is standard defect-triage practice: verify against the dependency's contract before attributing a failure to it.

## Maintenance note

Revisit if a case emerges where the misuse-vs-defect framing does not cleanly apply (e.g., a dependency with genuinely contradictory documentation, or a defect only reproducible in this codebase's specific configuration) - add a third diagnosis outcome only if repeated cases actually need it, not preemptively.
