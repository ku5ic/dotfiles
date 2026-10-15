---
name: codebase-visual
description: Explain a codebase visually - a markdown report of Mermaid diagrams built from scc, tokei, git, ast-grep and structurizr, each with a short caption. Shows the shape, the moving parts, the dependencies, the hotspots and the activity. Use when asked to "explain this codebase visually", "draw the architecture", "show me how this repo fits together", "diagram the modules", or for an overview of an unfamiliar repo.
argument-hint: "[repo path or subdirectory] [focus: an entry point or flow to trace]"
---

## Inputs

1. Root: `git -C <path or cwd> rev-parse --show-toplevel`. A subdirectory argument narrows every step to it.
2. Report: the path `kit scratch-dir visual <repo-slug>` prints. Raw tool output goes in a sibling folder named after the report, without `.md`. Nothing is written in the repo outside scratch.
3. Read the project CLAUDE.md and README first. Diagrams name things the way the project does.

## Collect

1. Size: `tokei <root>` for the language mix; `scc --by-file --format json --no-cocomo <root> > <raw>/scc.json` for per-file code lines and complexity.
2. Churn, 12 months: `git -C <root> log --since=12.months --format= --name-only | rg -v '^$' | sort | uniq -c | sed -E 's/^ *([0-9]+) (.*)$/\2\t\1/' > <raw>/churn.tsv`.
3. Hotspots: join the two and score complexity x churn, top 10:

```bash
jq -r --arg root "<root>/" --rawfile churn <raw>/churn.tsv '
  ($churn | split("\n") | map(select(length > 0) | split("\t") | {(.[0]): (.[1] | tonumber)}) | add) as $c
  | [.[].Files[] | (.Location | ltrimstr($root)) as $f | {file: $f, complexity: .Complexity, churn: ($c[$f] // 0)}]
  | map(. + {score: (.complexity * .churn)}) | sort_by(-.score) | .[:10][]
  | [.score, .complexity, .churn, .file] | @tsv' <raw>/scc.json
```

4. Dependencies: ast-grep over the import form of each main language. Keep only edges between the repo's own top-level modules, and list the top external packages apart.

| Language | Pattern                              |
| -------- | ------------------------------------ |
| JS/TS    | `import $$$ from '$SRC'`             |
| Python   | `from $M import $$$` and `import $M` |
| Go       | `import "$P"`                        |
| Lua      | `require($M)`                        |

```bash
ast-grep run -p '<pattern>' -l <lang> --json=compact <root> \
  | jq -r '.[] | [(.file | ltrimstr("<root>/") | split("/")[0]), .metaVariables.single.<VAR>.text] | @tsv' \
  | sort | uniq -c | sort -rn > <raw>/deps.tsv
```

Group by the source's top-level directory and the target's first path segment. Call `ast-grep`, never the deprecated `sg`.

5. Owners: `_GIT_SINCE=<12 months ago> _MENU_THEME=none git-quick-stats -a` for the repo, and the same with `_GIT_PATHSPEC=<dir>` for each top-level directory.
6. Activity: `git -C <root> log --since=12.months --format=%ad --date=format:%Y-%m | sort | uniq -c`.

## Diagrams

Follow the Diagrams rule in CLAUDE.md: a provenance line directly above every fence. Each diagram gets a one- or two-line caption under it saying what to take away from it, never what it shows. At most about 25 nodes per diagram: group or cut before drawing.

1. **Context and containers (C4).** Write `<raw>/workspace.dsl` with people, systems and containers read from the code, each container citing its path in its description. Then `structurizr validate -w <raw>/workspace.dsl` (exit 1 prints the bad line) and `structurizr export -w <raw>/workspace.dsl -f mermaid -o <raw>/mermaid`. Embed `structurizr-<key>.mmd` for the context and container views, marked exported. Never pass flags to `structurizr local`: it takes `--help` as a data directory.
2. **Shape.** A `flowchart TB` of top-level directories, each labelled with its main language and code lines.
3. **Dependencies.** A `flowchart LR` from step 4's edges, the edge label being the import count. Externals collapse into one node per package, top 5 only.
4. **Hotspots.** A `quadrantChart`, x = complexity and y = churn, each scaled 0 to 1 against the max, top 10 files as points. The top-right quadrant is "refactor first".
5. **Main flow**, when a focus is given or the entry point is obvious. A `sequenceDiagram` traced through the code from the entry point, 4 to 8 participants, each named after a real file or module.
6. **Activity.** An `xychart-beta` bar chart of commits per month, plus a `pie` of the language mix.

Diagrams 2 to 6 are drawn. Keep to these diagram types, since the report isn't rendered before it's handed over.

## Report shape

```markdown
# <project>: visual tour

Root: <root>. <files>, <language mix>. Window: 12 months to <date>. Raw data in `<raw folder>`.

## TL;DR

<3 bullets: what this is, the one part to understand first, where the risk sits>

## Context and containers

## Shape

## Dependencies

## Hotspots

## Main flow

## Activity

## Who to ask

- **<dir>**: <author (commits)>
```

Each section is a provenance line, the diagram, then its caption. No prose between diagrams beyond the captions.

## Writing rules

- Plain ASCII, `->` for arrows. Labels use names from the code.
- Prose and data files (Markdown, JSON, YAML) score 0 complexity and never rank as hotspots. When the busiest area is mostly those, say so in TL;DR.
- A skipped diagram (no clear flow, a single-module repo) gets one line saying why, not a placeholder.

## Reply

Report path, the TL;DR's first bullet, one next action.

## Stop

Read-only on the repo. Writes only to the scratch report and its raw folder.
