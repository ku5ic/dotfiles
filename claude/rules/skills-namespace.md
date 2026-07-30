# Claude Code skills namespace

Elaboration on `CLAUDE.md`'s `## Claude Code skills namespace` section.

- Commands and skills are one merged system, so the richer skill frontmatter (`disable-model-invocation`, `context: fork`, `agent`) applies.
- The canonical inventory is the output of `/skills` inside Claude Code, not any UI label.

## Hard rules

- Pause after each `/flow-*` step, and after completing any other logical segment, so the user can review (and commit, if applicable) before continuing.
- The stale `cmd-*` naming convention must be corrected to the namespaced form wherever found (docs, workflow guides, `CLAUDE.md`, prompts) on touch.
- Unprefixed references (`/plan`, `/implement`, `/review`) are ambiguous and should be normalized to the full `/<group>-<name>` form.
- Any skill step that would write or state an "Open questions" list instead asks those questions via the AskUserQuestion tool, one question per item, multiple-choice with the built-in "Other" free-text option covering anything that has no discrete options.
- Record the resolved answers in the output (file or terminal) as decisions; do not leave an unresolved list.
