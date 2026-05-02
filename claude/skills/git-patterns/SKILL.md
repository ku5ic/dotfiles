---
name: git-patterns
description: >
  Git workflow patterns covering Conventional Commits, interactive rebase,
  branch strategy, recovery with reflog, bisect, worktrees, and stash. Use
  whenever a project uses git, or the user asks about commit messages, rebase,
  branch strategy, merge conflicts, git history, or recovering lost commits,
  even if "git" is not mentioned by name.
---

# Git Patterns

## When to load this skill

- User asks about commit message format, rebase, squash, or fixup
- User asks about branch naming or branch strategy
- User asks about recovering lost commits or undoing changes
- User is resolving merge conflicts
- User asks about git bisect, worktrees, or stash

## When not to load this skill

- GitHub Actions or CI pipeline configuration
- GitOps / infrastructure deployment pipelines

---

## Conventional Commits

Conventional Commits give machines and humans a consistent way to parse commit history and derive semver bumps.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types and semver mapping

| Type       | SemVer bump | When to use                          |
| ---------- | ----------- | ------------------------------------ |
| `feat`     | MINOR       | New user-facing feature              |
| `fix`      | PATCH       | Bug fix                              |
| `docs`     | none        | Documentation only                   |
| `style`    | none        | Formatting, no logic change          |
| `refactor` | none        | Code restructure, no behavior change |
| `perf`     | none        | Performance improvement              |
| `test`     | none        | Adding or fixing tests               |
| `chore`    | none        | Build tooling, dependency updates    |
| `ci`       | none        | CI configuration                     |

### Breaking changes

Two equivalent ways to signal a breaking change (maps to MAJOR bump):

```
feat!: remove deprecated /v1 endpoints

BREAKING CHANGE: /v1/users and /v1/orders are removed. Use /v2 equivalents.
```

Or with scope:

```
feat(auth)!: require OAuth2 for all API calls
```

### Examples

```
feat(payments): add Stripe webhook signature verification

fix(auth): prevent session fixation on password reset

chore(deps): bump django from 5.0.4 to 5.0.6

docs(api): document rate limit headers
```

---

## Interactive rebase

Use interactive rebase to clean up commit history before merging.

```bash
git rebase -i HEAD~4        # Edit the last 4 commits
git rebase -i main          # Edit everything since branching from main
```

### Interactive rebase commands

| Command  | Short | What it does                                     |
| -------- | ----- | ------------------------------------------------ |
| `pick`   | `p`   | Keep the commit as-is (default)                  |
| `reword` | `r`   | Keep changes, edit the commit message            |
| `edit`   | `e`   | Pause to amend the commit (files + message)      |
| `squash` | `s`   | Merge into previous commit, concatenate messages |
| `fixup`  | `f`   | Merge into previous commit, discard this message |
| `drop`   | `d`   | Delete the commit                                |
| `exec`   | `x`   | Run a shell command after this commit            |

### Common patterns

**Squash a work-in-progress commit into the feature commit:**

```
pick a1b2c3 feat(orders): add order cancellation
fixup d4e5f6 wip
fixup g7h8i9 fix typo
```

**Test that each commit builds:**

```
pick a1b2c3 feat(orders): add order cancellation
exec make test
pick b2c3d4 feat(orders): add cancellation emails
exec make test
```

**During a rebase:**

```bash
git rebase --continue    # after resolving conflicts or editing
git rebase --abort       # undo the rebase entirely
git rebase --edit-todo   # re-open the rebase todo list
```

---

## Branch strategy

Keep `main` (or `master`) always deployable. Do all work on feature branches.

```
main                  <- production-ready at all times
feat/add-payments     <- feature branch
fix/login-redirect    <- bug fix branch
chore/bump-deps       <- maintenance branch
```

Branch naming: `<type>/<slug>` or `<type>/<TICKET-ID>/<slug>`.

Never force-push to `main`. Never commit directly to `main` without a review if the project has CI.

---

## Recovering lost work

### reflog

`reflog` records every time HEAD moved. Use it to find commits that appear lost after a bad rebase or reset.

```bash
git reflog                    # show recent HEAD positions
git reflog show branch-name   # show reflog for a specific branch
```

Recover a commit from reflog:

```bash
git checkout -b recovery HEAD@{3}   # create a branch at that position
git cherry-pick <sha>               # or cherry-pick the specific commit
```

### Undo the last commit (keep changes staged)

```bash
git reset --soft HEAD~1
```

### Undo the last commit (discard changes)

```bash
git reset --hard HEAD~1
```

Only use `--hard` when you are certain you do not need the changes.

---

## Bisect

Binary-search through history to find the commit that introduced a bug.

```bash
git bisect start
git bisect bad              # current commit is broken
git bisect good v1.4.0      # this tag was known good

# git checks out a midpoint commit
# test it, then mark it:
git bisect good
# or
git bisect bad

# repeat until git identifies the first bad commit
git bisect reset            # return to HEAD when done
```

Automate with a test script:

```bash
git bisect start HEAD v1.4.0
git bisect run make test    # exits 0 = good, non-zero = bad
```

---

## Worktrees

`git worktree` lets you check out multiple branches simultaneously in separate directories. Useful for reviewing a PR while staying mid-edit on another branch.

```bash
git worktree add ../hotfix-branch hotfix/urgent-fix
git worktree list
git worktree remove ../hotfix-branch
```

Each worktree shares the same `.git` directory but has its own working tree and HEAD.

---

## Stash

Stash saves dirty working tree state to a stack without committing.

```bash
git stash push -m "wip: payment form validation"
git stash list
git stash pop               # apply most recent and remove from stack
git stash apply stash@{2}   # apply specific entry, keep on stack
git stash drop stash@{2}    # delete a specific entry
```

Stash only tracked files by default. Add `-u` to include untracked files.

---

## .gitignore patterns

Common patterns:

```gitignore
# Python
__pycache__/
*.pyc
.venv/
.env

# Node
node_modules/
.next/
dist/

# Editors
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Secrets - always add these
*.pem
*.key
.env.local
.env.*.local
```

Track a file that is already ignored:

```bash
git add -f path/to/file
```

Check why a file is being ignored:

```bash
git check-ignore -v path/to/file
```

---

## Anti-patterns

**failure: force-pushing to a shared branch**
`git push --force` on `main` or any branch other people are using rewrites history and destroys their local branches. Use `--force-with-lease` if you must force-push to your own remote branch; it fails if someone else pushed since your last fetch.

**failure: committing secrets**
If a secret lands in git history, rotate it immediately regardless of whether you think the repo is private. `git rm` does not remove it from history; the secret is still in every clone.

**warning: merge commit spam on feature branches**
Merging `main` into a feature branch repeatedly to stay up to date produces a messy history. Prefer `git rebase main` on the feature branch to keep a linear history before merge.

**warning: squashing a merge commit into a feature commit**
Interactive rebase cannot squash across a merge commit. Resolve by rebasing onto `main` first to linearize history, then squash.

**warning: committing with `--no-verify`**
Skipping pre-commit hooks bypasses linting, type checks, and secret scanning. Only use if you understand exactly which hook is blocking you and why it is safe to skip in that moment.

**info: no `.gitignore` for secrets patterns**
An `.env` or `*.key` file not listed in `.gitignore` will eventually be committed by accident. Add secret file patterns before any other work in a new repo.

---

## References

- https://www.conventionalcommits.org/en/v1.0.0/
- https://git-scm.com/docs/git-rebase
- https://git-scm.com/docs/git-reflog
- https://git-scm.com/docs/git-bisect
- https://git-scm.com/docs/git-worktree
