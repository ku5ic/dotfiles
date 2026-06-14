---
description: Merge open Dependabot PRs and reconcile GitHub security alerts
argument-hint: <optional: ecosystem filter, PR number, or "--fix-transitive">
model: sonnet
effort: high
---

General core, best-effort tail. Package-manager agnostic.

The core (Phases 1-4) is ecosystem-agnostic: GitHub normalizes Dependabot PRs and security alerts identically across ecosystems, so merging PRs and reconciling alerts works the same everywhere. The tail (Phase 5) is opt-in.

This command names no specific package manager, lockfile, or manifest. The package manager and stack are already injected at session start (`<tooling>` block: `package-manager: <pm>`; `<repo-context>` block: stack and location). Read them from there. For any install, audit, tree query, lockfile regen, or override, derive the correct command from that manager at runtime. Do not detect the stack, do not re-list lockfiles, do not hardcode any tool's syntax. All check-running goes through `run-checks.sh`.

## Preconditions

1. Stack and package manager are in the injected `<repo-context>` and `<tooling>` blocks. Project name: `!`project-name.sh``.
2. Require `gh`. If absent: stop and report. Confirm auth: `gh auth status`. If unauthenticated, stop.
3. Resolve the repo slug: `gh repo view --json nameWithOwner -q .nameWithOwner`. Call it `<slug>`. If this fails there is no GitHub remote; stop, this command is GitHub-only.
4. Base branch: `!`git-base.sh``. Merge target and rebase base; do not re-derive it.
5. Working tree must be clean. If `git status --porcelain` is non-empty, stop and surface.

## Phase 1: inventory

### 1a. Dependabot PRs

`gh pr list --author "app/dependabot" --state open --json number,title,headRefName,mergeable,mergeStateStatus,labels`.

Classify each PR by semver bump from its title (`Bump x from 1.2.3 to 1.2.4`): patch, minor, major.

### 1b. Dependabot alerts (authoritative for severity; audit is only a cross-check)

Fetch all alerts with one bare GET and filter `state` client-side in jq. Do not pass `-f state=open`: `-f` sends a body field and makes gh issue a POST, which this read-only endpoint rejects with 404. Do not use a bare `?state=open` either; an unquoted `?` is a zsh glob. Let gh follow the Link header with `--paginate`; never construct `page`/`first`/`last`, removed for these endpoints on 2025-10-14.

```
gh api "repos/<slug>/dependabot/alerts" --paginate \
  --jq '.[] | select(.state=="open") | {number, severity: .security_vulnerability.severity, cvss: .security_advisory.cvss.score, ghsa: .security_advisory.ghsa_id, pkg: .dependency.package.name, ecosystem: .dependency.package.ecosystem, scope: .dependency.scope, relationship: .dependency.relationship, manifest: .dependency.manifest_path, fixed: .security_vulnerability.first_patched_version.identifier, range: .security_vulnerability.vulnerable_version_range}'
```

Field paths are verified against a live payload. The `ecosystem` field identifies each alert's ecosystem; use it. `state` is one of `open`, `fixed`, `dismissed`, `auto_dismissed`; only `open` is actionable.

Branch on the outcome (read it with `--include` and the `HTTP/2 <code>` line):

- 200: alerts are authoritative for severity. Continue.
- 404 on this bare GET: alerts are unavailable for the repo (disabled, or not visible to the token). Record "GitHub Dependabot alerts unavailable for <slug>" (name the slug) and fall through to audit-only, flagging every severity "from local audit, may understate". Do not assert "disabled" as fact. A 404 that appears only when a filter is attached but not on the bare GET is a malformed request; re-issue the bare GET.
- 403: token lacks scope. A classic PAT needs `repo` or `security_events`. Stop and tell the user to run `gh auth refresh -s security_events`.
- Any other non-2xx: stop and surface status and body.

### 1c. Native audit (cross-check only, optional)

A cross-check that may surface advisories GitHub has not yet alerted on. Using the injected package manager, run that ecosystem's native audit if one exists. If the manager has no native audit or its audit tool is not installed, note that and rely on the GitHub alerts alone. A missing audit tool is not an error.

If $ARGUMENTS scopes to an ecosystem or PR number, filter to it.

## Phase 2: triage and present

Stop for approval before mutating (`flow:*` pause discipline).

Severity is from 1b when available; where audit and alerts disagree, trust the alert. Map each open alert to a PR by package and fixed version. Annotate `relationship` and `scope`; runtime + direct + critical/high is the priority tier.

Group PRs:

- Auto-merge candidates: patch/minor, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`.
- Conflicted: `mergeStateStatus: DIRTY` or `mergeable: CONFLICTING`.
- Hold for confirmation: major bumps, and any runtime-scope bump whose advisory flags a breaking change.

Flag open alerts with no PR. By default these are reported, not fixed (see Phase 5).

Present a table: severity, package, ecosystem, scope, relationship, current -> fixed, bump, source (alert / PR / both), action. Wait for approval.

## Phase 3: resolve conflicts

1. `gh pr comment <n> --body "@dependabot rebase"`. Poll `mergeStateStatus`.
2. If still conflicting, resolve locally:
   - `gh pr checkout <n>`
   - `git rebase <base>` (base from Precondition 4)
   - Lockfile conflict: take the incoming dependency change, then regenerate the lockfile with the injected manager's lockfile-only install. Never hand-merge a lockfile.
   - Manifest conflict: merge both edits keeping the higher compatible version, then regenerate the lockfile.
   - `git add` resolved files, `git rebase --continue`.
3. Dependabot branches are bot-owned. Confirm before `git push --force-with-lease`. Never force push a branch you do not own.

## Phase 4: verify then merge

Never merge on GitHub mergeability alone. Verify each candidate first.

Per candidate, in turn:

1. `gh pr checkout <n>`.
2. Reinstall against the PR's lockfile using the injected manager's reproducible (frozen/locked) install mode.
3. Run `!`run-checks.sh``. On a non-zero failed count: do not merge, record the failing label, leave the PR open, move on. `run-checks.sh` owns runner detection across every stack; do not reimplement it.
4. On pass: merge with the project's convention (read recent merges). Default `gh pr merge <n> --squash --delete-branch`.
5. After each merge, return to base and pull before the next PR. Re-check mergeability; a merge can newly conflict a sibling.

Process priority-tier alerts first.

## Phase 5: manual remediation of alerts with no PR (opt-in, best-effort)

Skipped unless $ARGUMENTS contains `--fix-transitive`. Without it, alerts with no Dependabot PR are reported in Phase 6 and left for the user; manual transitive remediation is ecosystem-specific and easy to get wrong unattended.

When invoked, for each open alert with no PR, work in this order and stop at the first that applies:

1. Fixed version from `security_vulnerability.first_patched_version.identifier`. If null, there is no patched release; record "no fix available" and leave open.
2. Prefer the real fix: bump the parent. Using the injected manager's dependency-tree query, find the direct dependency that pulls the vulnerable transitive in. If a newer version of that direct dependency depends on a fixed version of the transitive, bump the direct dependency. This resolves the alert through normal resolution and leaves no standing pin.
3. Only if no parent bump resolves it (parent abandoned, or its latest still pulls the vulnerable range), apply the transitive-pin mechanism for the injected manager. Determine that mechanism from the manager itself; if you are not certain the ecosystem supports a transitive pin, stop and hand back to the user with the alert details rather than guessing. A transitive pin is debt: it persists even after the ecosystem moves on. Record every pin applied.
4. If neither applies and the advisory is not reachable in this project's usage, record it for dismissal rather than forcing a change.

After any manifest edit: confirm before writing, regenerate the lockfile with the manager's lockfile-only install, verify with the manager's tree query that the tree resolved to the fixed version, then run `!`run-checks.sh``. Real code change: branch, commit, `gh pr create`. Do not push to a protected branch. Stop before merging your own PR.

## Phase 6: report

markdown-report format. Write to `~/.claude/scratch/deps-<project-name>-<YYYYMMDD-HHMM>.md`. Print the path.

Per PR/alert: package, ecosystem, scope, relationship, version delta, bump, severity, action (merged / held / failed checks / parent bumped / pinned / manual PR opened / no fix available / left for user). If alerts were unavailable, state the severity source and name the slug. End with "Still open, needs you": every major bump held, every PR that failed checks, every open alert with no PR (and, if Phase 5 ran, every transitive pin applied so the debt is visible).

## Rules

- Package-manager agnostic. Name no specific manager, lockfile, or manifest. Read the manager from the injected `<tooling>` block (fall back to the manifest in `<repo-context>` for ecosystems without one) and derive every install/audit/tree/regen/pin command from it at runtime. Do not detect the stack.
- Core (Phases 1-4) is ecosystem-agnostic. Read the `ecosystem` field on each alert; never assume a default ecosystem.
- Phase 5 is opt-in (`--fix-transitive`) and best-effort. Without the flag, report alerts with no PR and stop.
- In Phase 5, prefer a parent bump over a transitive pin. A pin is the fallback, not the default, and it is standing debt; record every one. If the ecosystem's pin mechanism is uncertain, stop and hand back rather than guess.
- Do not re-derive the base branch. Use `git-base.sh` (Precondition 4). All checks go through `run-checks.sh`.
- Severity is from the GitHub alert list when available, not local audit.
- Fetch alerts with a bare GET and filter `state` in jq. Never `-f state=open` (POST -> 404), never unquoted `?state=open` (zsh glob).
- 404 on the bare GET means alerts unavailable (name the slug, fall back to audit-only), not a proven "disabled". 403 means missing scope. Handle differently.
- Only `state == "open"` alerts are actionable. `fixed`, `dismissed`, `auto_dismissed` are not.
- Do not merge major-version bumps autonomously. Hold and confirm.
- Do not merge any PR whose `run-checks.sh` reported a failure.
- Do not push to or merge into a protected branch directly.
- `--force-with-lease` only to a bot-owned Dependabot branch, after confirmation.
- No opportunistic bumps. Touch only deps named in an open alert or open Dependabot PR.
- One operation per Bash call. No chaining.
