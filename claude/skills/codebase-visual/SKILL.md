---
name: codebase-visual
description: Explain a codebase visually - a markdown report of Mermaid diagrams built from scc, tokei, git, ast-grep and structurizr, each explained with a takeaway, the why, and what to watch out for. Shows the shape, the moving parts, the dependencies and upward imports, the hotspots and their owners, hidden change coupling, the activity, and the tricky parts. Use when asked to "explain this codebase visually", "draw the architecture", "show me how this repo fits together", "diagram the modules", or for an overview of an unfamiliar repo.
argument-hint: "[repo path or subdirectory] [focus: an entry point or flow to trace] [since: git date, asked if omitted]"
---

## Inputs

1. Root: `git -C <path or cwd> rev-parse --show-toplevel`. A subdirectory argument narrows every step to it.
2. Report: the path `kit scratch-dir visual <repo-slug>` prints. Raw tool output goes in a sibling folder named after the report, without `.md`. Nothing is written in the repo outside scratch.
3. Read the project CLAUDE.md and README first. Diagrams name things the way the project does.
4. Window: the `since:` argument, any date git's `--since` takes (`6.months`, `2026-01-01`). Without one, ask with AskUserQuestion before collecting: `12.months` (Recommended), `6.months`, `3.months`, all history; "Other" takes a custom date. Every `<since>` below is this value; for all history, drop `--since` and `_GIT_SINCE`.

## Collect

1. Size: `tokei <root>` for the language mix; `scc --by-file --format json --no-cocomo <root> > <raw>/scc.json` for per-file code lines and complexity.
2. History, walked once for churn, activity and coupling: `git -C <root> log --since=<since> --format='--%H %ad' --date=format:%Y-%m --name-only --relative -- . > <raw>/gitlog.txt`. On a subdirectory run, `<root>` is that subdirectory: `--relative -- .` keeps the history to it, with paths relative to it like scc, ast-grep and `git ls-files` print them. Churn over the window: `rg -v '^(--|$)' <raw>/gitlog.txt | sort | uniq -c | sed -E 's/^ *([0-9]+) (.*)$/\2\t\1/' > <raw>/churn.tsv`.
3. Hotspots: join the two and score complexity x churn, top 10:

```bash
jq -r --arg root "<root>/" --rawfile churn <raw>/churn.tsv '
  ($churn | split("\n") | map(select(length > 0) | split("\t") | {(.[0]): (.[1] | tonumber)}) | add) as $c
  | [.[].Files[] | (.Location | ltrimstr($root)) as $f | {file: $f, complexity: .Complexity, churn: ($c[$f] // 0)}]
  | map(. + {score: (.complexity * .churn)}) | sort_by(-.score) | .[:10][]
  | [.score, .complexity, .churn, .file] | @tsv' <raw>/scc.json
```

4. Dependencies, with the scripts in this skill's folder:

```bash
<skill dir>/scripts/imports.sh <root> > <raw>/imports.tsv
python3 -I <skill dir>/scripts/deps.py <root> <raw>/imports.tsv <raw> [split dir]
```

`imports.sh` lists every import as `file<TAB>import text` with ast-grep rules for JS/TS, Python, Go, Rust, Java, Kotlin, Scala, C#, PHP, C/C++, Swift, Ruby, Lua, Dart and Elixir. It works whatever the quote style. For a language it doesn't cover, append rows with `rg -n --no-heading` on that language's import keyword, as file and statement text. Call `ast-grep`, never the deprecated `sg`.

`deps.py` is language-agnostic: it resolves relative paths, dotted names (`a.b.c`, `..x`), `from pkg import sub` to the submodule, Rust `crate::`/`super::` and grouped uses (`crate::{a, b}`), PHP namespaces, Go module paths from every `go.mod`, Dart `package:` imports of a package in this repo, Elixir modules to their snake_case files, TS `./a.js` to `a.ts`, and source roots it detects (`src` for a TS baseUrl, `src/main/java`). Whatever matches no tracked file, or names a registry dependency in a tracked manifest of the importing file's ecosystem (`package.json`, `Cargo.toml`, `pyproject.toml`, `requirements*.txt`, `Gemfile`, `go.mod`, plus the Python stdlib), is an external package. A Go import outside every module path is always external. `externals.tsv` marks each package `declared` (in a manifest) or `undeclared`. The split dir is found by descending while one directory holds over 80% of the importing files, so `src` becomes `src/views`, `src/ds`, and a Java tree becomes its feature packages; pass it to override. Rewrite path aliases with a prefix (`@/x`, `~/x`) to the directory form in `imports.tsv` first. It prints the split dir and main source root: check both. It writes `deps.tsv` (count, source, target), `externals.tsv`, `imports-resolved.tsv`, and `upward.tsv`: edges whose reverse direction carries more production imports (tests and stories don't vote), with the top production files named.

5. Owners: `_GIT_SINCE=<since> _GIT_IGNORE_AUTHORS='\[bot\]' _GIT_SORT_BY=commits-desc _MENU_THEME=none git-quick-stats -T` for the repo, and the same with `_GIT_PATHSPEC=<dir>` for each module. Not `-a`: it ignores the pathspec. The ignore pattern drops bots such as `github-actions[bot]`, so only people are listed. Per hotspot: `git -C <root> log --since=<since> --format=%an -- <file> | rg -v '\[bot\]' | sort | uniq -c | sort -rn`; a top author at 70% or more means one person carries that file.
6. Activity: `rg -o '^--\S+ (\S+)' -r '$1' <raw>/gitlog.txt | sort | uniq -c`.
7. Change coupling: `python3 -I <skill dir>/scripts/coupling.py <raw>/gitlog.txt <raw>/imports-resolved.tsv <raw>/coupling.tsv`. Each row is shared commits, degree (shared over the less-changed file's commits), `imports` or `no-import`, and both paths. A `no-import` pair at degree 0.5 or more is hidden coupling: duplicated logic, a list kept in sync by hand, or a registry like a flags file.
8. Read before writing. For each hotspot, upward edge, hidden-coupling pair, and the main flow, read the code and `git -C <root> log --since=<since> --format='%h %s' -- <file> | head -15`. This is where the Why and Watch out prose comes from; a section without it is a chart with a label.

## Diagrams

Follow the Diagrams rule in CLAUDE.md: a provenance line directly above every exported fence, none on drawn ones. At most about 25 nodes per diagram: group or cut before drawing, and follow Readability below. The prose under each diagram follows Report shape.

1. **Context and containers (C4).** The model lives outside the run, in `<arch>` = `~/Architecture/<parent>/<project>/`, where `<parent>` is the name of the folder holding the repo root and `<project>` is the repo name from `git remote get-url origin` (the root folder name without a remote). The parent keeps two clones or forks of one repo name apart. A subdirectory run uses `<arch>/scopes/<subdirectory>/` as its `<arch>`: its fingerprint covers only that scope, so it never reads, edits or replaces the whole-repo model. It holds `workspace.dsl`, `fingerprint.txt` and `mermaid/`, and is reused across runs.
   - Fingerprint: the module list (`cut -f2,3 <raw>/deps.tsv | tr '\t' '\n' | sort -u`), then the declared external packages (`awk -F'\t' '$3 == "declared" {print $2}' <raw>/externals.tsv | sort`). A stdlib import, a C header or a transitive package changes nothing; a new manifest dependency does. Without a parsed manifest (Java, C#), the fingerprint is the modules alone. Write it to `<raw>/fingerprint.txt`.
   - `<arch>/workspace.dsl` exists, `diff <arch>/fingerprint.txt <raw>/fingerprint.txt` is empty, and every path a container description cites still exists: reuse it as is. Skip to the export.
   - Fingerprint differs or a cited path is gone: edit the DSL in place for what the diff shows (a new module, a removed path, a new SaaS dependency). Keep everything else, since it may hold hand edits. Then copy the new fingerprint over.
   - No `<arch>/workspace.dsl`: write it with people, systems and containers read from the code, each container citing its path in its description, and copy the fingerprint over.
   - After any write: `structurizr validate -w <arch>/workspace.dsl` (exit 1 prints the bad line). Always: `structurizr export -w <arch>/workspace.dsl -f mermaid -o <arch>/mermaid`, then embed `structurizr-<key>.mmd` for the context and container views, marked exported. Never pass flags to `structurizr local`: it takes `--help` as a data directory. Preview with `structurizr local <arch>`.
   - Say in the report's header line whether the model was reused, updated (and with what), or created.
2. **Shape.** A `flowchart TB` of the modules (the split dir's children inside a subgraph, other top-level directories beside it), each labelled with its main language and code lines.
3. **Dependencies.** A `flowchart LR` from `deps.tsv`, the edge label being the import count. Externals collapse into one node per package, top 5 only. Upward edges from `upward.tsv` are drawn in terracotta with `linkStyle <indexes> stroke:#c8664a,stroke-width:3px`. Under it, a table of upward edges with production imports: edge, production imports and files, one example file.
4. **Hotspots.** A `quadrantChart`, x = complexity and y = churn, each scaled 0 to 1 against the max, top 10 files as points. The top-right quadrant is "refactor first". Write the maximum as `1`: the parser rejects `1.00`. Under it, a table: file, complexity, churn, top owner with their share.
5. **Change coupling.** A `flowchart LR` of the top 8 `no-import` pairs from `coupling.tsv`, nodes named after the file (its folder when the file is `index`), edge label = shared commits, nodes in the `hot` class. Skip it with one line when no pair reaches degree 0.5.
6. **Main flow**, when a focus is given or the entry point is obvious. A `sequenceDiagram` traced through the code from the entry point, 4 to 8 participants, each named after a real file or module.
7. **Activity.** An `xychart-beta` bar chart of commits per month, plus a `pie` of the language mix.

Diagrams 2 to 7 are drawn. Keep to these diagram types; Render below checks each one parses.

### Readability

- Every fence starts with the init line from Colors. `useMaxWidth: false` makes a large graph render at full size with a scroll, instead of shrinking to the page width. For an exported view, that line goes above the `.mmd` content, which otherwise stays verbatim.
- Large C4 views get split, not shrunk. In the DSL: `autolayout tb` on any view with more than 8 elements, and a container view over 12 elements gets broken into 2 or 3 views. Each one keeps a cluster of containers with `include <ids>`, plus the externals that cluster touches. Each view is embedded under its own provenance line.
- Node labels run 1 to 4 words. Paths and detail go in the prose, the table, or the DSL description.
- Edges carry a label only when it adds information: a count, a verb that isn't "uses".

### Colors

One muted palette everywhere: slate blue for the repo's own parts, sage for people, sand for external systems, terracotta for risk.

In `workspace.dsl`, tag external systems `"External"` and put this in `views`. The Mermaid export carries it into each node's `style` line:

```text
styles {
    element "Element" {
        background #e8eef6
        color #1f3550
        stroke #4a6fa5
    }
    element "Person" {
        background #e4efe6
        color #23422d
        stroke #5b8a6b
    }
    element "External" {
        background #f4eee5
        color #4a3d2c
        stroke #a8875e
    }
}
```

The init line on every fence, exported or drawn. It themes edges, quadrants, pie slices and bars to match:

```text
%%{init: {"theme": "base", "flowchart": {"useMaxWidth": false, "nodeSpacing": 50, "rankSpacing": 70}, "themeVariables": {"fontSize": "18px", "fontFamily": "Inter, system-ui, sans-serif", "primaryColor": "#e8eef6", "primaryTextColor": "#1f3550", "primaryBorderColor": "#4a6fa5", "lineColor": "#7b8794", "secondaryColor": "#e4efe6", "tertiaryColor": "#f4eee5", "quadrant1Fill": "#f6e1d8", "quadrant2Fill": "#f4eee5", "quadrant3Fill": "#eef1f4", "quadrant4Fill": "#e8eef6", "quadrantPointFill": "#c8664a", "pie1": "#4a6fa5", "pie2": "#5b8a6b", "pie3": "#a8875e", "pie4": "#c8664a", "pie5": "#8a7bb0", "pie6": "#5f9ea0", "pie7": "#b0a58f", "xyChart": {"plotColorPalette": "#4a6fa5"}}}}%%
```

In drawn flowcharts, mark external nodes with `classDef ext fill:#f4eee5,stroke:#a8875e,color:#4a3d2c` and hotspot nodes with `classDef hot fill:#f6e1d8,stroke:#c8664a,color:#5a2a1c`.

## Report shape

```markdown
# <project>: visual tour

Root: <root>. <files>, <language mix>. Window: <since> to <date>. Raw data in `<raw folder>`. Model: `<arch>/workspace.dsl`, <reused | updated: what changed | created>.

## TL;DR

<3 bullets: what this is, the one part to understand first, where the risk sits>

## Context and containers

## Shape

## Dependencies

## Hotspots

## Change coupling

## Main flow

## Activity

## Tricky parts

- <non-obvious behavior, file:line, what breaks if you miss it>

## Who to ask

- **<dir>**: <author (commits)>
```

Each diagram section is the provenance line for an exported view, the diagram, its table if the diagram has one, then three labelled parts:

- **Takeaway**: one line, what to conclude, never what the chart shows.
- **Why**: 2 to 4 sentences on why the code is shaped this way or keeps changing, from the code and commit subjects read in Collect step 8. Cite `file:line` or a short commit hash.
- **Watch out**: 1 to 3 bullets on the trap: what bites someone changing this part, and where.

Activity takes only a Takeaway. Tricky parts holds 3 to 6 findings from the reading that fit no diagram: an ordering dependency, a workaround, an implicit contract, a flag that gates a whole area.

## Writing rules

- Explain what, why, and the trap. A why comes from code, a commit message or a PR; when it's inferred, say "likely" and name the evidence. Never invent a reason from a file name.
- Short paragraphs, 4 lines at most. The reader skims; the Takeaway lines alone should tell the story.
- Plain ASCII, `->` for arrows. Labels use names from the code.
- Prose and data files (Markdown, JSON, YAML) score 0 complexity and never rank as hotspots. When the busiest area is mostly those, say so in TL;DR.
- A skipped diagram (no clear flow, a single-module repo) gets one line saying why, not a placeholder.

## Render

Before replying, render every diagram: `mmdc -i <report>.md -o <raw>/render/out.md`. Each chart prints a check or an error with its line. Fix each failing fence in the report and rerun until all pass. If `mmdc` is missing, say the diagrams weren't rendered.

## Reply

Report path, the TL;DR's first bullet, one next action.

## Stop

Read-only on the repo. Writes only to the scratch report, its raw folder, and `<arch>`.
