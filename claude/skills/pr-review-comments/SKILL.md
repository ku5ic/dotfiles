---
name: pr-review-comments
description: Turn code-review and decision-review findings on a PR into inline GitHub comments, previewing each for approval and posting them at least 30 seconds apart. Use when the user says "leave the comments on the PR", "post these as review comments", or "comment on the relevant lines".
argument-hint: "[PR number or URL] [findings: report path or pasted text]"
---

## Inputs

1. Findings, first match wins: a report path or pasted text in the argument; else the latest review points in this session, from `/code-review`, `/decision-review`, both, or plain discussion. Use what's there, merged; don't rerun a review to fill gaps. None at all: run `/code-review <pr>`, then `/decision-review <pr>` on top. This skill never checks out the PR or runs its checks; `/code-review` owns that, with its checkout question.
2. The PR number or URL: from the argument, else from the findings. Neither names it: ask. Resolve owner and repo from the URL, or `gh repo view --json nameWithOwner`.

## Pin the head

1. `gh pr view <n> --json headRefOid,headRefName,title,body,files`.
2. `git fetch origin "pull/<n>/head:refs/heads/pr/<n>"`. The bare `pr/<n>` form is ambiguous with `refs/remotes/pr/<n>`.
3. `git rev-parse refs/heads/pr/<n>` must equal `headRefOid`. Mismatch: stop and say so. Every later read uses that SHA.

zsh traps: write `"${head}:${file}"`, never `$head:src/...` (the `:s` history modifier fires). Never name a variable `path`; it's tied to `PATH`.

## Verify each point

For every finding, before drafting:

1. Name its decisive claim and trace it to the source at the head SHA: `git show <sha>:<file>`, a sibling file, a library's docs or source. Findings can be wrong, like a claim about a sibling file that turned out false.
2. Confirmed: draft it as a statement or a suggestion. Unconfirmed, like library behavior nobody checked: phrase it as a question. Disproved: drop it and say so in one line.
3. Merge duplicates. One concern per comment.

## Anchor each point

- **Line**: an inline comment on the RIGHT side, on a line inside the diff. Take the line number from `git show <sha>:<file>`, never from hunk offsets: a new or renamed file shows as "new file" in a pathspec-limited `git diff`. Confirm the line falls inside a hunk of `gh pr diff <n>`.
- **File**: a point about a file's location or name is a file-level comment.
- **None**: a point with no line, like cases to try, is a general PR comment.

## Draft

- Voice: the decision-review skill's Voice section, plus `rules/output.md` section 4. Lowercase, short, questions over commands.
- Nits start with "a nit:".
- Write each body to its own file under `kit scratch-dir`, through Write, so the posted text is byte-identical to the preview.

## Approve

AskUserQuestion, one question per comment, at most 4 per call:

- Options `Post` and `Skip`. Both carry the same preview: `path:line` (or `path (file)`, or `PR (general)`), a blank line, then the exact body.
- "Other" is an edited body: rewrite that comment's file with the edited text, and post it unchanged.
- Nothing is posted without a `Post` or an edit from this session.

## Post

One comment per API call, at least 30 s apart. A batched `POST /pulls/<n>/reviews` can't be paced, so never use it.

- Line: `gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments -f commit_id=<sha> -f path=<file> -F line=<n> -f side=RIGHT -F body=@<body-file>`
- File: `gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments -f commit_id=<sha> -f path=<file> -f subject_type=file -F body=@<body-file>`
- General: `gh pr comment <n> --body-file <body-file>`

Run the whole loop as one Bash call with `run_in_background`, `sleep 30` between posts inside it; the harness blocks a foreground `sleep`. Log each response's `html_url` and `created_at` (`--jq`) to a file in scratch. A failed post stops the loop; report it, never retry blind.

30 s sits well under GitHub's secondary limits for content creation (80 per minute, 500 per hour, [docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)). The docs note some endpoints have lower limits without naming them, so a 403 or 429 means stop and report.

## Check, then reply

1. Fetch each posted comment and diff its body against its approved file.
2. Inline comments: the returned `line` and `path` match the anchor.
3. Consecutive `created_at` values are at least 30 s apart.

Reply: each posted comment's URL, then skipped ones by anchor only, then the dropped points with the reason. Ask before deleting the body files.

## Never

Approve, request changes, resolve threads, edit or delete existing comments, reply to the author, or fix the PR's code.
