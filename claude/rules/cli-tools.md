# Preferred CLI tools

When a deterministic CLI exists for a question, call it instead of reading files and reasoning. The tools below are installed via Brewfile and permitted in settings.json. Before using any CLI not in this list, confirm it appears in `~/.dotfiles/Brewfile` - that is the authoritative inventory of what is installed on this machine. When multiple tools could answer the same question, prefer the one that uses fewer tokens: a single CLI call beats a targeted file read; a targeted file read beats a broad grep; any of these beats model reasoning from memory.

- `rg` for code search and locating, over `grep`, `find -name`, or `Read` walks.
- `sg` (ast-grep) for syntax-aware structural code search and rewrite. Prefer over `rg` when the question is about code shape, not text: "find every useEffect with an empty dep array", "rename this call pattern". `sg` understands AST; `rg` matches strings.
- `fd` for filename and path search, over `find`.
- `tokei` for repo size, language breakdown, and largest-file selection. One call replaces "read several files to estimate".
- `gitleaks` for quick secret detection. `trufflehog git file://.` for deeper history scanning and broader credential coverage.
- `hyperfine` for command-level timing measurement. Use it when a perf claim needs a number, not an opinion.
- `jq` for JSON inspection and transformation, over substring matching on raw output. `yq` for YAML and TOML. `gron` to flatten JSON into greppable `path = value` lines when writing a jq path blind is slower than grepping.
- `sd 'find' 'replace' file` for in-place substitution, over `sed -i`. Safer syntax, no quoting footguns.
- `qsv` for CSV/TSV operations (select, join, stats, frequency). The CSV counterpart to `jq`.
- `sponge` (from moreutils) to buffer stdin before writing: `cmd | sponge file` avoids the temp-file pattern and is safe for in-place pipeline rewrites.
- `git absorb` to auto-generate fixup commits from staged hunks, over manual `rebase -i` + fixup.
- `git -C <dir> <subcmd>` for any git operation outside the current working directory. Do not `cd <dir> && git ...`; the chain triggers a permission prompt that `git -C` avoids.

Rule: if the question is factual (how big, what secrets, how fast, what is in this JSON), reach for the tool. If the question is interpretive (is this code correct, does this design hold up), reading and reasoning is correct.
