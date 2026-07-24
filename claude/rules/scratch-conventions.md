# Scratch artifact naming

Scratch artifacts resolve to the directory printed by `scratch-dir.sh`: project-scoped at `<project-root>/.claude/scratch/` when the current directory is a recognized project, `$HOME/.claude/scratch/` everywhere else. "Recognized project" means `project-root.sh --check` succeeds - a git worktree, or a stack sentinel matched during the ancestor walk - not merely "isn't `$HOME` or `/`".

One naming pattern, regardless of which tier `scratch-dir.sh` resolves to - the directory itself is what scopes an artifact to a project, not the filename:

$(scratch-dir.sh)/<kind>-<scope-slug>-<YYYYMMDD-HHMM>.md

If the kind has no scope slug:

$(scratch-dir.sh)/<kind>-<YYYYMMDD-HHMM>.md

Outside any recognized project, `scratch-dir.sh` falls back to `~/.claude/scratch/`, shared across every unrelated session and project running from a non-project cwd. Artifacts there are not disambiguated by filename - only by content and timestamp. This is a rare case (it only triggers when cwd has no git worktree and no stack-sentinel ancestor) and not worth a second filename shape for.

When reading "the most recent X" of a kind, always filter within the resolved scratch directory:

ls -t "$(scratch-dir.sh)"/<kind>-\*.md | head -1

Never read across projects. If no artifact exists for the current project, run the predecessor command first.

Retention: only the home-fallback tier is pruned on a schedule, by `$HOME/.claude/bin/scratch-rotate.sh` (30-day default; run manually via `scratch-rotate.sh` or wire to launchd; pass a custom retention window as the first argument, e.g. `scratch-rotate.sh 14`). Per-project scratch directories are gitignored and rely on manual cleanup - there is no scheduled pruning across arbitrary project roots.

Session-start dedup markers (written by `inject-context.sh`) always live under `$HOME/.claude/scratch/`, regardless of project context - they are session infrastructure, not a project artifact.
