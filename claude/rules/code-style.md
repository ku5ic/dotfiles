# Code style

Elaboration on `CLAUDE.md`'s `## Code Style` line.

- No decorative comments. No banners, dividers, or section headers made of symbols like `===`, `---`, `***`, `###`, or similar.
- ASCII box drawing characters (`x`, `+`, `-`, `|`, `->`, `<-`) are allowed only when actually constructing a diagram inside a comment or doc. Not as decoration.
- Comment only when something is not obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, behavior that would surprise a reader.
  - If removing the comment would not confuse a future reader, do not write it.
  - One line, not a paragraph - a why that needs more than a line belongs in the commit message or PR description, not the source.
  - Remove comments that restate the code.
- Match the existing code style of the file and the project. If Prettier, ESLint, Biome, or similar config exists, conform to it.
- Prefer idiomatic patterns for the framework in use over generic patterns.
- Meaningful names. No Hungarian notation. No single letter variables except loop indices.
- Readability and explicitness over cleverness.
- Simplicity and unnecessary-abstraction avoidance: see the `ponytail` plugin (enabled globally).
