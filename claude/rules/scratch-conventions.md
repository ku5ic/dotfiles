# Scratch artifact naming

All commands that write to `$HOME/.claude/scratch/` use this pattern:

~/.claude/scratch/<kind>-<project-name>-<scope-slug>-<YYYYMMDD-HHMM>.md

If the kind has no scope slug:

~/.claude/scratch/<kind>-<project-name>-<YYYYMMDD-HHMM>.md

`<project-name>` is the output of `$HOME/.claude/bin/project-name.sh`.
It is the slugified basename of the git repo root: lowercased, leading dots
stripped, non-alphanumeric characters replaced with dashes, collapsed dashes,
trimmed. Outside a git working tree it returns the slug of $PWD basename
(e.g. "tmp" for /tmp, "dotfiles" for ~/.dotfiles).

When reading "the most recent X" of a kind, always filter by the current
project name:

ls -t ~/.claude/scratch/<kind>-<project-name>-\*.md | head -1

Never read across projects. If no artifact exists for the current project,
run the predecessor command first.

All scratch goes to `$HOME/.claude/scratch/` (home, absolute), never
`.claude/scratch/` (cwd-relative).

Retention: artifacts older than 30 days are pruned by `$HOME/.claude/bin/scratch-rotate.sh`. Run manually (`scratch-rotate.sh`) or wire to launchd. Pass a custom retention window as the first argument: `scratch-rotate.sh 14`.
