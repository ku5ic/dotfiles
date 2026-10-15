---
name: code-history
description: Trace the git and PR history of a file or folder and write an ADHD-friendly markdown report with turning points, recurring bugs, broken promises, who to ask, and a short story. Use when asked for the history, background, or "how did we get here" of code.
argument-hint: "<file or folder path, or a component name>"
---

## Inputs

1. Resolve the argument to a real path. A loose name ("Filter ds component") may not match one: search with `fd` and `rg`, pick the match, and state the substitution in the report header.
2. Size the job: `git log --format='%h%x09%ad%x09%an%x09%s' --date=short -- <path> | wc -l`.
3. Resolve the repo slug with `gh repo view --json nameWithOwner` and the default branch with `gh repo view --json defaultBranchRef`.
4. A team decision log connector (Notion or similar) is optional. If one exists, search it for the component name and record whether any entry covers it.

## Collect

Read every commit and every PR description that touches the path. Don't sample.

1. Commit list: `git log --format='%H%x09%ad%x09%an%x09%s' --date=short -- <path>`, saved to the raw folder.
2. PR numbers from subjects, both forms: squash `(#1234)` and older `Merge pull request #1234`.
3. Fetch PRs with batched GraphQL, about 40 aliases per query (`pr1234: pullRequest(number: 1234) { number title body author { login } mergedAt url }`), never one `gh pr view` per PR. Save the raw JSON.
4. Lines changed on the path per commit (`git log --numstat -- <path>`), ranked. The top entries are the structural turning points, found faster than by title. Drop reformat-only ones first: `DFT_CHECK_ONLY=true GIT_EXTERNAL_DIFF=difft git show --ext-diff --format=%h <sha> -- <path>` prints `No syntactic changes.` for a file whose diff is only formatting. Prose files print `Has changes.` either way.
5. For the biggest PRs with empty descriptions, read the squash commit body (it lists sub-commits) and the diffstat on the path. Label that "why" as inferred.

## Digest

1. Strip PR template boilerplate before reading: checklists, "Type of change", tooling notes. Otherwise the signal drowns.
2. Write a chronological digest, one heading per PR linking to it, cleaned body below.
3. Grep the digest for promises and reversals: `temporary`, `for now`, `will be removed`, `TODO`, `in the future`, `revert`. Check each against the current code before calling it unkept.
4. Group fixes by bug class to find the ones that keep coming back.
5. For "Who to ask": `_GIT_PATHSPEC=<path> _GIT_SORT_BY=commits-desc _MENU_THEME=none git-quick-stats -T` gives commits, lines changed and first and last commit per author on the path. Not `-a`: it ignores the pathspec.

## Report shape

```markdown
# <Component>: how we got here

Component: [path](link)
<N> commits, <M> PRs, <first month> to <last month>. Raw descriptions in `digest.md`.

---

## TL;DR

<3 to 5 bullets: what shapes today's code>

---

## Timeline

### <year>: <one-word theme>

- **<Mon>.** <what changed, one line>. [#123](link)

---

## Bugs that keep coming back

- **<class>.** <PR links>

---

## Promised, never done

- <quote of the promise>. [#123](link)

---

## Who to ask

- **[handle](link)**: <what they know> (<commit count>)

---

## The story

<5 to 8 short paragraphs, 2 to 3 sentences each, past tense, like a history lesson: why it was born, what reshaped it, what it's still carrying, where it stands today.>

---

## Caveats

- <empty descriptions, inferred rationale, gaps, decision log result>
```

## Writing rules

- Every PR, file, folder, person and external doc named is an inline markdown link. No reference-style link definitions: a draft with them and a big table was rejected as unreadable.
- People link to their GitHub profile or to the path's commit history filtered by author. Handles, not guessed full names. They/them.
- TL;DR first. One idea per bullet, one or two short lines each. Bold only the key phrase. `---` between sections. No tables with prose in cells. No paragraph over three lines.
- Every claim about why something changed cites its PR. Anything inferred from a diff says so.
- "The story" is the last content section before Caveats, at most about 300 words, and introduces no fact missing from the sections above.
- Plain ASCII: no em dashes, no smart quotes, `->` for arrows.

## Output

- Report at the path `kit scratch-dir history <component-slug>` prints.
- Raw material in a sibling folder named after the report (without `.md`): `prs.json`, `commits.tsv`, `digest.md`.

## Verify before replying

Check by script, not by eye:

1. Every `#<n>` in the report is in the collected PR list and resolves to a PR in this repo.
2. Every linked file or folder exists on the default branch (`git cat-file -e <default>:<path>`).
3. The header counts match `git log -- <path>` and the collected PR list.
4. No TL;DR bullet runs past two lines, and the story is under about 300 words.

Reply with the report path, the headline counts, and one next action.

## Out of scope

- Proposing fixes or refactors.
- Code review of the current state.
- History of code that only imports the path, unless a PR moved code into or out of it.

## Stop

Read-only. Never edit source, never comment on a PR.
