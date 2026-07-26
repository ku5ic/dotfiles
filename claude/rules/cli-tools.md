# Preferred CLI tools

When a deterministic CLI can answer the question, call it before reading files and reasoning. Fewer tokens wins: one CLI call beats a targeted read beats a broad grep beats reasoning from memory. Authoritative inventory of installed tools: `~/.dotfiles/Brewfile`; confirm there before using anything not listed below.

| Question                        | Tool                                | Over                                           |
| ------------------------------- | ----------------------------------- | ---------------------------------------------- |
| Locate code by text             | `rg`                                | grep, find -name, Read walks                   |
| Locate code by shape (AST)      | `sg`                                | rg, when the question is structure not text    |
| Find files/paths                | `fd`                                | find                                           |
| Repo size, language breakdown   | `tokei`                             | reading files to estimate                      |
| Secrets, quick                  | `gitleaks`                          | manual grep                                    |
| Secrets, deep history           | `trufflehog git file://.`           | gitleaks                                       |
| Timing a perf claim             | `hyperfine`                         | opinion                                        |
| JSON                            | `jq` (or `gron` to grep flat paths) | substring matching                             |
| YAML/TOML                       | `yq`                                | manual parsing                                 |
| CSV/TSV                         | `qsv`                               | ad-hoc awk                                     |
| In-place substitution           | `sd 'find' 'repl' file`             | sed -i                                         |
| Buffer stdin for in-place pipes | `cmd \| sponge file`                | temp-file dance                                |
| Fixup commits from staged hunks | `git absorb`                        | rebase -i + fixup                              |
| Git outside cwd                 | `git -C <dir>`                      | cd <dir> && git (triggers a permission prompt) |

Factual question (how big, what secrets, how fast, what is in this JSON): reach for the tool. Interpretive question (is this correct, does this design hold): reading and reasoning is correct.
