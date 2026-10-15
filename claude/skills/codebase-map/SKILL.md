---
name: codebase-map
description: Map an unfamiliar codebase before changing it - rank files by complexity times churn, name who to ask per area, count patterns with ast-grep, and write a short report out of tree under ~/architecture/<project>/. Use when asked for a codebase map, hotspots, "where is the risk", "where do I start", or before planning a large change in an unfamiliar repo.
argument-hint: "[repo path] [ast-grep pattern ...]"
---

## Inputs

1. Root: `git -C <path or cwd> rev-parse --show-toplevel`. Project slug `<p>`: its basename.
2. Output dir: `~/architecture/<p>/map-<YYYYMMDD>/` for raw data, report beside it as `~/architecture/<p>/map-<YYYYMMDD>.md`. Never write inside the repo.
3. Optional ast-grep patterns from the arguments, or rules in `~/architecture/<p>/sgconfig.yml` when it exists.

## Collect

Raw tool output goes to the raw dir, not the report.

1. Size and complexity: `scc --by-file --format json --no-cocomo <root> > <raw>/scc.json`.
2. Churn, last 12 months: `git -C <root> log --since=12.months --format= --name-only | rg -v '^$' | sort | uniq -c | sed -E 's/^ *([0-9]+) (.*)$/\2\t\1/' > <raw>/churn.tsv`.
3. Rank, score = complexity x churn, top 10:

```bash
jq -r --arg root "<root>/" --rawfile churn <raw>/churn.tsv '
  ($churn | split("\n") | map(select(length > 0) | split("\t") | {(.[0]): (.[1] | tonumber)}) | add) as $c
  | [.[].Files[] | (.Location | ltrimstr($root)) as $f | {file: $f, complexity: .Complexity, code: .Code, churn: ($c[$f] // 0)}]
  | map(. + {score: (.complexity * .churn)}) | sort_by(-.score) | .[:10][]
  | [.score, .complexity, .churn, .code, .file] | @tsv' <raw>/scc.json
```

4. Owners per hotspot: `git -C <root> shortlog -sn --no-merges HEAD -- <file> | head -2`. Owners per top-level area: `_GIT_PATHSPEC=<dir> _GIT_SINCE=<12 months ago> _MENU_THEME=none git-quick-stats -a`.
5. Patterns, when given: `ast-grep run -p '<pattern>' -l <lang> --json=compact <root> | jq length` per pattern, or `ast-grep scan -c ~/architecture/<p>/sgconfig.yml --json=compact <root> | jq 'group_by(.ruleId) | map({rule: .[0].ruleId, count: length})'`. Call `ast-grep`, never the deprecated `sg`.
6. Repo shape: `tokei <root>` for the language mix, one line in the report.

## Diagram

Follow the Diagrams rule in CLAUDE.md.

- `~/architecture/<p>/current/workspace.dsl` exists: `structurizr export -w <dsl> -f mermaid -o <raw>/mermaid`, embed the container view (`structurizr-<key>.mmd`), mark it exported.
- Otherwise draw a `flowchart` of the top-level directories, each hotspot as a node under its directory, marked drawn.

## Report shape

```markdown
# <project>: codebase map

Root: <root>. <N> files, <languages, one line>. Churn window: 12 months to <date>. Raw data in `map-<date>/`.

## TL;DR

<3 bullets: where the risk sits, who to ask, where to start reading>

## Hotspots

| # | file | score | complexity | commits | code lines | ask |

## Areas

- **<dir>**: <owner (commits)>, <one line on what lives there>

## Patterns

| pattern | count |

## Diagram

## Next

- code-history on: <top 3 hotspot paths>
```

## Writing rules

- Plain ASCII, `->` for arrows. No paragraph over three lines.
- A score is a ranking signal, not a verdict: a generated or vendored file in the top 10 gets dropped and named once under TL;DR.
- Owners are git author names as git prints them. They/them.
- Prose and data files (Markdown, JSON, YAML) score 0 complexity and never rank. When the highest-churn area is mostly those, name it as a blind spot under TL;DR.

## Reply

Report path, the top hotspot with its score, one next action: usually code-history on the top 3. Never run code-history unasked; it reads every PR on the path.

## Stop

Read-only on the repo. Writes only under `~/architecture/<p>/`.
