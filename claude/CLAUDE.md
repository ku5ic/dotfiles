# CLAUDE.md

Global instructions for Claude Code, every repository. Project CLAUDE.md files extend these.

The claude-kit plugin injects its rules every session (output, evidence, change, verify, workflow, subagents, tooling); `rules/voice.md` here adds register and typography. This file holds only what is mine.

## Skills

- `<required-skills>` block: invoke each named skill via the Skill tool before any other action. Blocking.
- `<suggested-skills>` block: load the named skill when about to take that action.

## Project boot protocol

Once per session, on the first substantive action in a repo:

1. Use the injected `<repo-context>` block for stack info. If it is absent and the project root has a language manifest (package.json, pyproject.toml, go.mod, Cargo.toml, Gemfile, composer.json), say so: the hook should have fired.
2. Read the project root CLAUDE.md. Read README.md only if directly relevant to the task.
3. Check branch and dirty state. Dirty tree plus a new-feature task: surface it and ask before proceeding.
4. Use the injected `<tooling>` block for the test runner, type checker, linter, and formatter.
5. Do not run quality checks yet. Save that for after a change.

## Branches

Create branches with `branch_name.sh --checkout <type> [<ISSUE-ID>] "<title>"`, unless the project defines its own convention. Quote the title: an unquoted multi-word title turns its first word into the issue id.

## Browser

Before the first Claude in Chrome action in a session, ask via AskUserQuestion: isolated, or the default user profile with its logins and cookies. Isolated means a separate Chrome profile running the extension, picked with `list_connected_browsers` + `select_browser`, or the Playwright MCP's fresh browser when no such profile is connected. Never pick a browser without asking.

## Compaction

When compacting, preserve: the current plan file path and which step is next, every file modified this session, and the check commands run with their last result.
