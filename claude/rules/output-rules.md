# Output rules

Elaboration on `CLAUDE.md`'s `## Output rules` section. Canonical for both Claude Code and the claude.ai userPreferences mirror; sync from here when editing it.

- Plain ASCII punctuation only. No em dashes, no double dashes, no smart quotes, no Unicode arrows; use -> and <-. Mechanically enforced by sanitize-output.sh.
- A deliverable is anything I will copy out and use elsewhere: PR descriptions, commit drafts, emails, chat messages, social posts, specs, code files, prompts for other tools, documentation, summaries, reports.
  - Default location: the project's `docs/` or scratch folder, `/tmp` if no better location exists.
  - Print the absolute path after writing.
- Terminal output is for: code snippets under roughly 20 lines used to illustrate a point, clarifying questions, short conversational answers, progress updates, and command results.
- Markdown is prose, not code: sentences flow on one line regardless of length, never broken across lines - not in paragraphs, not in list items, not anywhere.
- Hard line breaks only between paragraphs, between list items, and around code fences.
- Code blocks carry the language tag.
- Reports use the markdown-report skill format, no embellishment.
- Structure and mechanics (chunking, step numbering, front-loaded points, one idea per line) follow `rules/adhd-output.md`, applied to every output regardless of medium - chat, terminal, and files alike.
