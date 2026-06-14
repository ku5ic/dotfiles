---
description: Merge open Dependabot PRs and resolve reported security vulnerabilities
argument-hint: <optional: ecosystem filter (npm, pip, github-actions) or PR number>
model: sonnet
effort: high
---

## Preconditions

1. Stack is in the injected `<repo-context>` block. Project name: `!`project-name.sh``.
2. Require `gh`. If absent: stop and report. Confirm auth with `gh auth status`; if unauthenticated, stop.
3. Confirm the repo has a GitHub remote (`git remote get-url origin`). If not, stop; this command is GitHub-only.
4. Record the current branch and dirty state. If the working tree is dirty, stop and surface; do not operate over uncommitted work.
5. Detect the package manager from the lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `bun.lockb`, `poetry.lock`, `requirements.txt`, `uv.lock`). This determines lockfile-refresh and audit commands. Do not introduce a different manager.

## Phase 1: inventory

1. List open Dependabot PRs: `gh pr list --author "app/dependabot" --state open --json number,title,headRefName,mergeable,mergeStateStatus,labels`.
2. List open security advisories: `gh api repos/{owner}/{repo}/dependabot/alerts -f state=open` (paginate). If the endpoint 404s (alerts disabled or no access), note it and continue with PRs only.
3. Run the ecosystem audit for cross-check:
   - npm/pnpm/yarn/bun: the manager's `audit` (`pnpm audit --json`, `npm audit --json`, etc).
   - pip/poetry/uv: `pip-audit` if present, else note "pip-audit not installed" and skip.
4. If $ARGUMENTS scopes to an ecosystem or a PR number, filter to that. Otherwise process all.
5. Classify each Dependabot PR by semver bump from its title: patch, minor, major. Dependabot encodes this (`Bump x from 1.2.3 to 1.2.4`).

## Phase 2: triage and present

Before mutating anything, produce a plan and stop for approval (this is a `flow:*` step; pause discipline applies).

Group the PRs:

- **Auto-merge candidates**: patch and minor bumps, `mergeable: MERGEABLE`, no conflicts.
- **Conflicted**: `mergeStateStatus` is `DIRTY` or `mergeable: CONFLICTING`. These need a rebase.
- **Hold for confirmation**: major bumps, and any PR touching a dependency flagged as a breaking change in its own release notes if reachable.

Map each open security alert to a PR if one exists. Flag alerts with no corresponding PR; those need a manual bump.

Present the grouped plan as a short table (advisory severity, package, current -> target, bump type, action). Wait for approval before Phase 3.

## Phase 3: resolve conflicts

For each conflicted PR, prefer Dependabot's own rebase over hand-merging:

1. Comment `@dependabot rebase` via `gh pr comment <n> --body "@dependabot rebase"`. Poll `mergeStateStatus` for up to a reasonable window.
2. If still conflicting after rebase, the conflict is real (usually competing lockfile edits). Resolve locally:
   - `gh pr checkout <n>`
   - `git rebase origin/<default-branch>`
   - On lockfile conflict: take the incoming dependency change, then regenerate the lockfile with the detected manager (`pnpm install --lockfile-only`, `npm install --package-lock-only`, `poetry lock --no-update`, etc) so it is internally consistent rather than a hand-merged hybrid.
   - On manifest conflict (`package.json`, `pyproject.toml`): merge both edits, keeping the higher compatible version, then regenerate the lockfile.
   - `git add` the resolved files, `git rebase --continue`.
3. Do not force push to a shared branch you do not own. Dependabot branches are bot-owned; pushing the rebased branch back is acceptable, but confirm before `git push --force-with-lease` to the Dependabot branch.

## Phase 4: verify then merge

Never merge on green PR status alone. Run the project's own checks against each candidate before merging.

For each auto-merge candidate and each resolved-conflict PR, in turn:

1. `gh pr checkout <n>`.
2. Reinstall against the PR's lockfile (`pnpm install --frozen-lockfile` or the manager equivalent).
3. Run `/flow:checks` (or `run-checks.sh`). If any check fails, do not merge: record the failure, leave the PR open, and move on.
4. If checks pass: merge with the project's merge style. Default to `gh pr merge <n> --squash --delete-branch` unless the repo convention differs (read recent merge commits to detect rebase/merge preference).
5. After each merge, return to the default branch and pull before processing the next PR, so later PRs rebase onto the just-merged state. Re-check mergeability; a merge can newly conflict a sibling PR.

Process highest-severity security PRs first, then the rest.

## Phase 5: advisories without a PR

For each open alert with no Dependabot PR (common for transitive deps or disabled PR creation):

1. Identify the offending package and the fixed version range from the advisory.
2. If it is transitive: add an override (`pnpm.overrides`, `resolutions` for yarn/npm, constraint for pip) pinning to the fixed version. State this as a manual config edit and confirm before touching `package.json` / `pyproject.toml`.
3. Regenerate the lockfile. Run `/flow:checks`.
4. This is a real code change, not a bot merge: create a branch, commit, and open a PR with `gh pr create`. Do not push to a protected branch. Stop before merging your own PR; that is the user's call.

## Phase 6: report

Use markdown-report format. Write to `~/.claude/scratch/deps-<project-name>-<YYYYMMDD-HHMM>.md`. Print the path.

Record, per PR/alert: package, version delta, bump type, advisory severity if any, action taken (merged / held / failed checks / manual PR opened), and for failures the exact failing check. End with a "Still open, needs you" section listing every major bump held, every PR that failed checks, and every advisory left unresolved.

## Rules

- Do not merge major-version bumps autonomously. Hold and confirm.
- Do not merge any PR whose `/flow:checks` run failed, regardless of GitHub's mergeability status.
- Do not push to or merge into a protected branch (`main`, `master`, `develop`) directly. Dependabot merges target it through the PR; your own fix PRs do not get merged by this command.
- Do not `git push --force` to a shared branch. `--force-with-lease` to a bot-owned Dependabot branch only, after confirmation.
- Do not add, upgrade, or override a dependency outside the scope of a reported advisory or an open Dependabot PR. No opportunistic bumps.
- If the audit and the Dependabot alerts disagree on severity, trust the GitHub advisory (`dependabot/alerts`) over the local `audit` output; the latter lags.
- One operation per Bash call. No chaining.
