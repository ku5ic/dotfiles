# Scratch conventions

Scratch resolves to the directory printed by `scratch-dir.sh`: project-scoped at `<project-root>/scratch/` when the current directory is a recognized project, `$HOME/.claude/scratch/` everywhere else. "Recognized project" means `project-root.sh --check` succeeds - a git worktree, or a stack sentinel matched during the ancestor walk - not merely "isn't `$HOME` or `/`".

The project tier lives at `scratch/`, not `.claude/scratch/`: Claude Code treats `.claude/` as a hardcoded protected directory and always confirms edits there, regardless of `Edit(...)` allow rules or `acceptEdits` mode. `scratch/` sits outside that protected list, so writes there follow normal permission rules. The home-fallback tier stays under `~/.claude/scratch/` since it's session infrastructure, not a project artifact - see the dedup-marker note below.

## What goes in scratch

Everything temporary: structured reports, plans, and previews, but also test artifacts, proof-of-concept scripts, one-off debug files, and any other working file that isn't a deliverable landing in the project's own source tree. `scratch-dir.sh`'s resolved directory is the only place these belong.

This overrides two defaults that otherwise compete for the same job: the harness's per-session `/tmp` scratchpad (use the project's `scratch/` instead - it survives the session and isn't wiped when the container ends) and ad hoc paths under `~/.claude/` for anything besides the `~/.claude/scratch/` home-fallback tier - the harness's own memory stores (`~/.claude/projects/<project>/memory/`, `~/.claude/agent-memory-local/`) are the one carve-out, since those are Claude Code's own persistence mechanism, not a scratch substitute.

Structured artifacts (reports, plans) keep the naming pattern below. Test artifacts and POC files don't need to fit that shape - name them sensibly - but still must live under `scratch-dir.sh`'s resolved directory, never in system `/tmp` or loose in `~/.claude/`.

### Never the project root

Nothing temporary is ever written to the project root or loose in the repo tree. That includes downloads (`curl`, `wget`, `gh` artifact fetches), captured screenshots, redirected command output and logs, and generated data files.

Resolve the destination with `scratch-dir.sh` first, then pass that path explicitly to whatever writes the file:

- `curl -o "$(scratch-dir.sh)/<name>"`, not `curl -O`
- a screenshot or export tool's `out_dir` / `save_to_disk` path argument, not its default
- `cmd > "$(scratch-dir.sh)/<name>.log"`, not `cmd > out.log`

Never default to `.`, to a bare filename, or to whatever directory the tool picks on its own. The project root is tracked source: a stray file there pollutes `git status`, risks being committed, and lands in every clone.

`guard-bash.sh` enforces the shell cases: `curl -O`/`-J` and a bare `wget` are blocked outright (the server picks the name, so there is no intended target), while an explicit relative target (`curl -o notes.json`, `wget -P downloads`, `cmd > out.log`) forces the permission prompt rather than a denial - a file that genuinely belongs in the project tree is a decision to confirm, not a mistake to block. Targets under `scratch/`, absolute paths, and `$(scratch-dir.sh)` forms pass untouched. Tool-driven writes (a browser screenshot's `out_dir`, an MCP server's own download path) are outside what a bash hook can see and rely on this rule alone.

One naming pattern for structured artifacts, regardless of which tier `scratch-dir.sh` resolves to - the directory itself is what scopes an artifact to a project, not the filename:

$(scratch-dir.sh)/<kind>-<scope-slug>-<YYYYMMDD-HHMM>.md

If the kind has no scope slug:

$(scratch-dir.sh)/<kind>-<YYYYMMDD-HHMM>.md

Outside any recognized project, `scratch-dir.sh` falls back to `~/.claude/scratch/`, shared across every unrelated session and project running from a non-project cwd. Artifacts there are not disambiguated by filename - only by content and timestamp. This is a rare case (it only triggers when cwd has no git worktree and no stack-sentinel ancestor) and not worth a second filename shape for.

When reading "the most recent X" of a kind, always filter within the resolved scratch directory:

ls -t "$(scratch-dir.sh)"/<kind>-\*.md | head -1

Never read across projects. If no artifact exists for the current project, run the predecessor command first.

Retention: `$HOME/.claude/bin/scratch-rotate.sh` prunes both tiers on a schedule (30-day default; run manually via `scratch-rotate.sh` or wire to launchd; pass a custom retention window as the first argument, e.g. `scratch-rotate.sh 14`). The home-fallback tier is pruned directly. Project-scoped `scratch/` directories are pruned via a registry: `scratch-dir.sh` appends each project scratch path it resolves to `~/.claude/logs/scratch-registry.txt` (deduped), and `scratch-rotate.sh` reads that file each run, pruning every listed directory that still exists and dropping entries whose directory is gone. This exists because the scheduled launchd run has no project cwd of its own - it only knows `$HOME` - so without the registry it could never find a project's `scratch/` to prune. Project directories are still gitignored.
