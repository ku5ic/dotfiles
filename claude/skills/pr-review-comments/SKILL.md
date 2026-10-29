---
name: pr-review-comments
description: Turn code-review and decision-review findings on a PR into a draft review file, then, once the user approves the file, post it as inline GitHub comments at least 30 seconds apart. Use when the user says "draft the review comments", "leave the comments on the PR", "post these as review comments", or "comment on the relevant lines".
argument-hint: "[draft|post] [PR number or URL] [findings: report path or pasted text]"
---

Two modes, run in separate turns: `draft` writes the review file and posts nothing; `post` posts that file once the user has approved it. No mode given: `draft`, unless a draft file for the PR already exists and the user has approved it in this session.

## Inputs

1. Findings, first match wins: a report path or pasted text in the argument; else the latest review points in this session, from `/code-review`, `/decision-review`, both, or plain discussion. Use what's there, merged; don't rerun a review to fill gaps. None at all: run `/code-review <pr>`, then `/decision-review <pr>` on top. This skill never checks out the PR or runs its checks; `/code-review` owns that, with its checkout question.
2. The PR number or URL: from the argument, else from the findings. Neither names it: ask. Resolve owner and repo from the URL, or `gh repo view --json nameWithOwner`.

## Pin the head

1. `gh pr view <n> --json headRefOid,headRefName,title,body,files`.
2. `git fetch origin "pull/<n>/head:refs/heads/pr/<n>"`. The bare `pr/<n>` form is ambiguous with `refs/remotes/pr/<n>`.
3. `git rev-parse refs/heads/pr/<n>` must equal `headRefOid`. Mismatch: stop and say so. Every later read uses that SHA.

zsh traps: write `"${head}:${file}"`, never `$head:src/...` (the `:s` history modifier fires). Never name a variable `path`; it's tied to `PATH`.

## Draft mode

### Verify each point

For every finding, before drafting:

1. Name its decisive claim and trace it to the source at the head SHA: `git show <sha>:<file>`, a sibling file, a library's docs or source. Findings can be wrong, like a claim about a sibling file that turned out false.
2. Confirmed: draft it as a statement or a suggestion. Unconfirmed, like library behavior nobody checked: phrase it as a question. Disproved: drop it and say so in one line.
3. Merge duplicates. One concern per comment.

### Anchor each point

- **Line**: an inline comment on the RIGHT side, on a line inside the diff. Take the line number from `git show <sha>:<file>`, never from hunk offsets: a new or renamed file shows as "new file" in a pathspec-limited `git diff`. Confirm the line falls inside a hunk of `gh pr diff <n>`.
- **File**: a point about a file's location or name is a file-level comment.
- **None**: a point with no line, like cases to try, goes in the summary comment.

### Write each comment

One to three sentences, under ~50 words. Sentence case, plain chat register, no stock phrases ("wdyt", "IMO", "I'd rather"), no @mention, no praise, no summary of the change.

1. Lead with the evidence you checked: a count, a repro and its rate, a `file:line`, the concrete input that breaks it.
2. End with the fix as a question: "Derive it from X instead?", "Worth passing Y there?", "Intended?".
3. Non-blocking points say so up front: "Not a bug, just consistency."
4. Concede what's right in the same comment: "Otherwise the overrides look right to me."
5. Nits start with "Nit," and name the replacement.

Posted examples:

```text
The query falls back to the default view when the URL is empty, but this reads the URL. With a default view searching "zzzqqq", Contexts flashed "You don't have any contexts yet" before "No results" (1 of 2 reloads). Derive it from `useFiltersVariables` output instead?

I went through the 44 callers without `emptyState`. All only render the table when there are rows, except WorkerPools (`WorkerPools/index.tsx:86`). Outside SaaS its `rows` skip the public pool, so with no private pools it'd show a headerless table above its own empty state. Worth passing `emptyState` there?

Not a bug, just consistency. Here it's `!!data && !rows.length`, Tasks and TableSimple check loading. One definition across pages?

Nit, `FiltersLayout` reads well. This one only gates visibility, so maybe `HideWhenEmpty`?
```

The summary comment opens with one line pointing at the inline comments ("API thoughts are inline, most important first."), then one bullet per direct answer to a question the PR description asks, and the unanchored points. Nothing to add beyond the pointer: omit the summary.

### Write the draft file

Write it through Write to `<repo>/.claude/scratch/pr-<n>-review.md` (the `kit scratch-dir` of the PR's repo). Inline comments go most important first. Shape:

```markdown
# PR <n> review draft (not posted)

Anchored to head <short-sha>. Each inline comment has its file and line link, then the text.

## Summary comment (main thread)

<summary body>

## Inline comments

### [<path>:<line>](https://github.com/<owner>/<repo>/pull/<n>/files#diff-<sha256 of path>R<line>)

<body>

### [<path> (file)](https://github.com/<owner>/<repo>/pull/<n>/files#diff-<sha256 of path>)

<body>
```

The diff anchor is `printf '%s' "<path>" | shasum -a 256`. Reply with the file path, the comment count, the dropped points with the reason, and one next action: review the file, then run `post`. Post nothing.

### Review loop

The user edits the file or asks for changes; apply them with Edit. Deleting a section skips that comment. Stay in draft mode until the user says the file is approved.

## Post mode

1. Read the approved draft file. Its "Anchored to head" SHA must equal the current `headRefOid`; moved: stop and say so, offer to re-draft.
2. Every inline anchor still falls inside a hunk of `gh pr diff <n>`.
3. Split the file into one body file per comment under scratch, through Write, text byte-identical to its section with surrounding blank lines trimmed. Drop the "(not posted)" heading and the anchor headings; they are not comment text.
4. One AskUserQuestion: "Post N inline comments and the summary to PR <n>?" Options `Post` and `Cancel`. Nothing is posted without `Post` from this session.

### Post

One comment per API call, at least 30 s apart, in file order, summary last. A batched `POST /pulls/<n>/reviews` can't be paced, so never use it.

- Line: `gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments -f commit_id=<sha> -f path=<file> -F line=<n> -f side=RIGHT -F body=@<body-file>`
- File: `gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments -f commit_id=<sha> -f path=<file> -f subject_type=file -F body=@<body-file>`
- Summary: `gh pr comment <n> --body-file <body-file>`

Run the whole loop as one Bash call with `run_in_background`, `sleep 30` between posts inside it; the harness blocks a foreground `sleep`. Log each response's `html_url` and `created_at` (`--jq`) to a file in scratch. A failed post stops the loop; report it, never retry blind.

30 s sits well under GitHub's secondary limits for content creation (80 per minute, 500 per hour, [docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)). The docs note some endpoints have lower limits without naming them, so a 403 or 429 means stop and report.

### Check, then reply

1. Fetch each posted comment and diff its body against its body file.
2. Inline comments: the returned `line` and `path` match the anchor.
3. Consecutive `created_at` values are at least 30 s apart.

Reply: the PR URL, the posted count, and any mismatch. Ask before deleting the body files; keep the draft file.

## Never

Post in draft mode, approve, request changes, resolve threads, edit or delete existing comments, reply to the author, or fix the PR's code.
