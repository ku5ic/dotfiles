# ADHD-friendly output

Governs the structure and mechanics of all output: chat, terminal, and files/deliverables alike. Pairs with `rules/voice.md` (tone and phrasing) - this file governs the shape of information, not word choice.

## Priority

Applies before token-cost, DRY, or brevity trade-offs. When a denser or more cross-referenced form would cost more working memory to parse than a chunkier, more explicit one, choose the ADHD-friendly form. If that costs real duplication, say so in one line rather than silently picking either way - same divergence-must-be-named principle as `change-discipline.md`.

The Length tiers in `CLAUDE.md` still govern how much to say. This file governs how it is structured, regardless of medium - the "written to a file" exemption in the Length section covers verbosity only, not structure.

## Rules

1. One idea per line, bullet, or step. Never two claims stitched into one sentence with "and" when they could be two lines.
2. Lead every step, paragraph, and finding with the instruction or the point. Context and rationale come after, or get cut - attention can lapse mid-paragraph, so anything placed after three sentences of wind-up may never be read ("phantom reading": text is visually processed but not retained during demanding reading tasks in ADHD).
3. Sequential or multi-part work becomes a numbered list of single-action steps, not a paragraph. Never require holding more than one pending action in mind at a time.
4. Restate the concrete referent in place. Don't make a step depend on recalling something stated earlier in the same file or a different one - write the two words needed, even if it duplicates. Externalizing information instead of relying on memory is the standard compensating strategy for ADHD's working-memory deficit.
5. Group by topic. Don't interleave two unrelated concerns in the same block or paragraph - each topic switch carries a measurable attention cost in ADHD (larger task-switching costs than neurotypical controls, especially when the switch requires reorienting attention).
6. Plain language. Cut clutter, tangents, and decorative asides - identified by W3C's cognitive-accessibility guidance (COGA) as the single highest-leverage change for cognitive accessibility, and disruptive elements are called out as especially costly for ADHD readers specifically.
7. Use structure to carry organization - headers, numbered steps, checklists - instead of prose the reader has to mentally reorganize. The structure is the external scaffold; don't make the reader build their own.
8. No walls of text. A paragraph over roughly three lines gets chunked, even in a file or report where verbosity is otherwise allowed.

## Applying it

- In scope with no exceptions: skill bodies, agent output, audit reports, proposal descriptions, chat replies, and every external-communication deliverable - commit messages, PR descriptions, devnotes, review comments, stakeholder writeups, release notes.
- A shorter file that is still one dense paragraph does not comply. A longer file broken into scannable chunks does.
- When DRY and this file conflict (for example, extracting shared text into another file the reader would have to jump to), name the conflict explicitly and default to keeping content in place, unless the duplication is large enough to become its own maintenance burden.

## External communication

Respecting the reader's time is the point, not just accommodating ADHD. This is why every `write-*` skill follows this file with no carve-out, `write-explainer` included even though it is long-form by design.

- The one exception is an explicit request for a detailed explanation (the Length section's long-mode triggers: "in detail", "walk me through", "--full", "long version", or invoking `/write-explainer` itself). That exception changes how much gets said, never how it is structured - a long explanation is still chunked into short paragraphs and headers, never one undifferentiated wall of text.
- Commit messages, PR descriptions, devnotes, review comments, stakeholder writeups, and release notes never get the detailed-explanation exception. They are read by someone else on their time; default to the shortest structured form that is still complete.
- `guard-tone.sh` and `guard-commit.sh` mechanically enforce rule 8 (no walls of text) on these deliverables by blocking a run of more than 4 consecutive unstructured prose lines. The other rules here (front-loading, one idea per bullet, plain language) are judgment calls a hook cannot safely make - follow them by intent, the same way `rules/voice.md`'s structural tells are instruction-only.

## Sources

- Barkley, R. - working memory as a primary deficit in ADHD; ADHD framed as a performance disorder (the person knows what to do but cannot reliably execute it); externalizing information ("making the invisible visible") as the standard compensating strategy for both working-memory and time-blindness deficits.
- Reading research on text chunking: segmenting text into meaningful chunks reduces the number of units that must be held and integrated during reading, lowering cognitive load and comprehension overwhelm.
- "Phantom reading" in ADHD: text is processed visually but not retained during demanding reading tasks, linked to unreliable suppression of the brain's default-mode network.
- Task-switching research: ADHD is associated with measurably larger task-switching costs than neurotypical controls, most pronounced when a switch requires reorienting attention between features.
- W3C Cognitive and Learning Disabilities Accessibility Task Force (COGA): plain language and uncluttered design are identified as the most effective cognitive-accessibility interventions; disruptive or cluttered elements are named as especially costly for users with ADHD or anxiety.
