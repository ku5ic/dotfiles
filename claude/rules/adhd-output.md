# ADHD-friendly output

Governs the structure and mechanics of all output: chat, terminal, and files/deliverables alike. Pairs with `rules/voice.md` (tone and phrasing) - this file governs the shape of information, not word choice.

## Priority

Applies before token-cost, DRY, or brevity trade-offs. When a denser or more cross-referenced form would cost more working memory to parse than a chunkier, more explicit one, choose the ADHD-friendly form. If that costs real duplication, say so in one line rather than silently picking either way - same divergence-must-be-named principle as `change-discipline.md`.

The Length tiers in `CLAUDE.md` still govern how much to say. This file governs how it is structured, regardless of medium - the "written to a file" exemption in the Length section covers verbosity only, not structure.

## Rules

1. One idea per line, bullet, or step. Never stitch two claims into one sentence with "and" when they could be two lines.
2. Lead every step, paragraph, and finding with the instruction or the point - context and rationale come after, or get cut. Text placed after three sentences of wind-up often goes unread.
3. Sequential or multi-part work becomes a numbered list of single-action steps, not a paragraph. Never require holding more than one pending action in mind at once.
4. Restate the concrete referent in place. Don't make a step depend on recalling something stated earlier - write the two words needed, even if it duplicates.
5. Group by topic. Don't interleave two unrelated concerns in the same block - topic switches carry a real attention cost.
6. Plain language. Cut clutter, tangents, and decorative asides.
7. Use structure - headers, numbered steps, checklists - instead of prose the reader has to mentally reorganize.
8. No walls of text. A paragraph over roughly three lines gets chunked, even where verbosity is otherwise allowed.
9. Always format output ADHD-friendly: TL;DR first, decisions and actions up front, short blocks, tables over prose, bold on key phrases, long reasoning in collapsible sections
10. Batch tool calls before prose, never interleave. In a single turn, run every tool call first, then write the reader-facing text once as one uninterrupted block after the last call. Never sandwich must-read text between two tool calls, and never narrate a call about to happen ("Let me save this...") - the tool calls are plumbing the reader has to scroll past, and splitting the prose around them forces a second read-through to reassemble it.
11. No insider shorthand for a reader outside the process that produced it. A label invented mid-conversation or mid-review - a ticket ID, a review-thread number, a D1/F2-style code from an internal report - carries no meaning on its own for someone who wasn't there when it was assigned. Name the thing itself ("the split-button layout question") instead of leading with its code. This does not apply to a vocabulary the reader already shares, such as the failure/warning/info severity levels in `rules/markdown-report.md` read by the team that defined them.

## Applying it

- In scope with no exceptions: skill bodies, agent output, audit reports, proposal descriptions, chat replies, and every external-communication deliverable - commit messages, PR descriptions, devnotes, review comments, stakeholder writeups, release notes.
- A shorter file that is still one dense paragraph does not comply. A longer file broken into scannable chunks does.
- When DRY and this file conflict (for example, extracting shared text into another file the reader would have to jump to), name the conflict explicitly and default to keeping content in place, unless the duplication is large enough to become its own maintenance burden.
- Bold lead-in labels ("**Recommendation**:", "**Option A**") are structure for a file, report, or deliverable a reader scans section by section - not for a chat reply or a short prose message (a devnote, a one-line acknowledgment, a quick terminal answer). In those, use plain sentence structure or a bare bullet instead; a bold-label prefix in a short exchange reads as an AI tell, per `rules/voice.md`'s structural tells.

## External communication

Respecting the reader's time is the point, not just accommodating ADHD. This is why every `write-*` skill follows this file with no carve-out, `write-explainer` included even though it is long-form by design.

- The one exception is an explicit request for a detailed explanation (the Length section's long-mode triggers: "in detail", "walk me through", "--full", "long version", or invoking `/write-explainer` itself). That exception changes how much gets said, never how it is structured - a long explanation is still chunked into short paragraphs and headers, never one undifferentiated wall of text.
- Commit messages, PR descriptions, devnotes, review comments, stakeholder writeups, and release notes never get the detailed-explanation exception. They are read by someone else on their time; default to the shortest structured form that is still complete.
- `guard-tone.sh` and `guard-commit.sh` mechanically enforce rule 8 (no walls of text) on these deliverables by blocking a run of more than 4 consecutive unstructured prose lines. The other rules here (front-loading, one idea per bullet, plain language) are judgment calls a hook cannot safely make - follow them by intent, the same way `rules/voice.md`'s structural tells are instruction-only.
