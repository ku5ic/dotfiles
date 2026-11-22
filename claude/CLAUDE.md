# CLAUDE.md

Global instructions for Claude Code, every repository, on top of the claude-kit rules. Project CLAUDE.md files extend these.

## Skills

`pr` is a name Claude Code reserves, so kit's PR skill only works as `/kit:pr`. A bare `/pr` being unknown is expected, not a kit bug; don't debug it.

## Repo boot

On the first substantive action in a repo:

- No `<repo-context>` block while the project root has a language manifest (package.json, pyproject.toml, go.mod, Cargo.toml, Gemfile, composer.json): say so, the hook should have fired.
- Dirty tree plus a new-feature task: surface it and ask before proceeding.

## Branches

Create branches with `branch_name.sh --checkout <type> [<ISSUE-ID>] "<title>"`, unless the project defines its own convention. Quote the title: an unquoted multi-word title turns its first word into the issue id.

## Browser

Before the first Claude in Chrome action in a session, ask via AskUserQuestion: the default user profile with its logins and cookies, always first and marked recommended, or isolated. Isolated means a separate Chrome profile running the extension, picked with `list_connected_browsers` + `select_browser`, or the Playwright MCP's fresh browser when no such profile is connected. Never pick a browser without asking.

## Diagrams

Research and plan artifacts embed Mermaid. A C4 view comes from the project's `c4-*.mmd` file in the folder `kit code-graph model-dir` prints, edited in place and never drawn ad hoc. It gets the provenance line `/code visual` uses, `Diagram: from <mmd path>`. Every other diagram is drawn, with no provenance line.

## Compaction

When compacting, preserve: the current plan file path and which step is next, every file modified this session, and the check commands run with their last result.
