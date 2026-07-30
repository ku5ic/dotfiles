#!/usr/bin/env bash
# Resolves the scratch directory for the current context: project-scoped
# when project-root.sh finds a real anchor (git worktree or stack
# sentinel), global fallback otherwise. Single source of truth for
# claude/rules/scratch-conventions.md.
#
# project-name.sh's home/root/unknown categories are not a project signal
# (every directory gets a slug, anchored or not), so this checks
# project-root.sh's own anchor detection directly via --check.
#
# Creates the directory if missing: some callers (agent instructions using
# a bare `>` redirect instead of the Write tool) have no other chance to
# mkdir before their first write.
#
# Project tier lives outside .claude/ on purpose: Claude Code treats .claude/
# as a hardcoded protected directory and always confirms edits there, even
# with an Edit(...) allow rule. scratch/ isn't on that protected list.
#
# Registers each project dir it resolves in scratch-registry.txt so
# scratch-rotate.sh's scheduled (launchd) run can find and prune it later -
# that run has no project cwd of its own, only $HOME.

set -euo pipefail

if "$HOME/.claude/bin/project-root.sh" --check; then
  dir="$("$HOME/.claude/bin/project-root.sh")/scratch"
  registry="$HOME/.claude/logs/scratch-registry.txt"
  mkdir -p "$(dirname "$registry")"
  grep -qxF "$dir" "$registry" 2>/dev/null || echo "$dir" >>"$registry"
else
  dir="$HOME/.claude/scratch"
fi

mkdir -p "$dir"
echo "$dir"
