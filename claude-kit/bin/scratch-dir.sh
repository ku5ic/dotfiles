#!/usr/bin/env bash
# Resolves the scratch directory for the current context: project-scoped
# when project-root.sh finds a real anchor (git worktree or stack
# sentinel), global fallback otherwise. Single source of truth for
# rules/tooling.md. The resolution lives in _lib.sh's kit_dir.
#
# Creates the directory if missing: some callers (agent instructions using
# a bare `>` redirect instead of the Write tool) have no other chance to
# mkdir before their first write.
#
# Both tiers live under .claude/ so scratch sits beside plans/ and tasks/.
# Claude Code gates .claude/ writes behind its own confirmation; a project's
# settings.json carries Edit()/Write() allows for these paths. If the prompts
# come back regardless, move the project tier back to <root>/scratch - that
# was the previous arrangement, and that gating was the reason for it.

set -euo pipefail

# shellcheck source=_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

kit_dir scratch
