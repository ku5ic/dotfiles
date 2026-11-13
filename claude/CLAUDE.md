# CLAUDE.md

Global instructions for Claude Code, every repository. Project CLAUDE.md files extend these.

The claude-kit plugin's rules are the `kit-rules` skill, which a gate makes load before any tool call (output, evidence, change, verify, workflow, subagents, tooling); `rules/voice.md` here adds register and typography. This file holds only what is mine.

## Skills

`pr` is a name Claude Code reserves, so kit's PR skill only works as `/kit:pr`. A bare `/pr` being unknown is expected, not a kit bug; don't debug it.

## Repo boot

On the first substantive action in a repo:

- No `<repo-context>` block while the project root has a language manifest (package.json, pyproject.toml, go.mod, Cargo.toml, Gemfile, composer.json): say so, the hook should have fired.
- Dirty tree plus a new-feature task: surface it and ask before proceeding.

## Branches

Create branches with `branch_name.sh --checkout <type> [<ISSUE-ID>] "<title>"`, unless the project defines its own convention. Quote the title: an unquoted multi-word title turns its first word into the issue id.

## Browser

Before the first Claude in Chrome action in a session, ask via AskUserQuestion: isolated, or the default user profile with its logins and cookies. Isolated means a separate Chrome profile running the extension, picked with `list_connected_browsers` + `select_browser`, or the Playwright MCP's fresh browser when no such profile is connected. Never pick a browser without asking.

## Diagrams

Research and plan artifacts embed Mermaid. A C4 view comes from the project's `c4-*.mmd` file under `~/Architecture/<parent>/<project>/` (layout in `/code visual`), edited in place, never drawn ad hoc; every other diagram is drawn. Directly above each C4 fence, one provenance line: `Diagram: from <mmd path>`. Drawn diagrams carry no provenance line.

## Compaction

When compacting, preserve: the current plan file path and which step is next, every file modified this session, and the check commands run with their last result.
