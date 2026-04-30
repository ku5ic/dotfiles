#!/usr/bin/env bash
# Single source of truth for stack sentinels. Sourced by:
#   - bin/detect-stack.sh
#   - bin/project-root.sh
#   - hooks/inject-context.sh
# CLAUDE.md "Project boot protocol" references STACK_SENTINELS_PROJECT_ROOT.
#
# Adding a sentinel here updates all three consumers and the cache invalidation
# in inject-context.sh. No other edits are required for the shared list to take
# effect; per-stack categorization in detect-stack.sh is separate and must
# remain a subset of STACK_SENTINELS_FULL.

# Full set: every sentinel any consumer cares about. Used by inject-context.sh
# for cache invalidation, and by detect-stack.sh as the canonical union.
# shellcheck disable=SC2034  # consumed by scripts that source this file
STACK_SENTINELS_FULL=(
  package.json
  pyproject.toml
  requirements.txt
  Pipfile
  manage.py
  Gemfile
  Cargo.toml
  go.mod
  pnpm-workspace.yaml
  turbo.json
  nx.json
  lerna.json
)

# Anchor-walk subset: the small, fast list project-root.sh walks ancestors
# with. Mirrors the CLAUDE.md "Project boot protocol" sentinel set. Keep this
# minimal: every entry slows the ancestor walk for repos without that sentinel.
# shellcheck disable=SC2034  # consumed by scripts that source this file
STACK_SENTINELS_PROJECT_ROOT=(
  package.json
  pyproject.toml
  Gemfile
  Cargo.toml
  go.mod
)
