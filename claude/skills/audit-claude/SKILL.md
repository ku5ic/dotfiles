---
description: Audit Claude Code configuration layer -- skills, commands, hooks, and settings -- for staleness, misconfiguration, and trigger-coverage gaps
argument-hint: <none | --area=skills|commands|hooks|settings|versions>
model: opus
disable-model-invocation: true
---

## Procedure

Delegate the procedure below (steps 1 onward, through Rules) to the claude-config-auditor agent (Agent tool, subagent_type: claude-config-auditor, foreground). It executes every step itself and writes the report; relay its returned summary.

1. Get the scratch directory: `!`scratch-dir.sh``. Note the date for the report filename.
2. Determine scope. If $ARGUMENTS contains `--area=<value>`, run only that pass. Otherwise run all five passes in order.
3. Write findings incrementally to the report file (create it before starting Pass 1 with an empty findings list). Path: `$(scratch-dir.sh)/audit-claude-<YYYYMMDD-HHMM>.md`.
4. Run the passes below. Each pass is independent: if one fails to gather data, mark "Cannot be verified statically" and continue to the next pass.

### Pass 1: Skills

Glob `~/.dotfiles/claude/skills/*/SKILL.md`. For each file:

**Shared checks (all skills)**

- Parse the YAML frontmatter. Extract `name`, `description`, and `disable-model-invocation`.
- Flag (failure): `description` is absent or empty.
- Flag (failure): description body contains an explicit instruction to load another skill by name (e.g., "load skill X alongside", "see also skill Y", "load these together"). Autodetection rule -- skills may not name other skills as load instructions.

Skills split into two genres here: autodetected pattern skills (`disable-model-invocation` absent or `false`) and command-type skills (`disable-model-invocation: true`, invoked only by typed slash command, never autodetected). Apply the matching check set below, not both.

**Pattern skills (autodetected) -- description and body checks**

- Flag (warning): description does not follow the required shape: `[What the skill is, one phrase]. Use whenever [project signals], OR the user asks about [keyword aliases], even if [technology] is not mentioned by name.` The shape requires BOTH a project-signal clause (file extensions, sentinel files, dependency markers) AND a keyword-alias clause.
- Check that the body contains each of these sections. One warning per missing section:
  - An anti-patterns section with at least one severity call (`failure`, `warning`, or `info`), OR a `reference/anti-patterns.md` file exists alongside `SKILL.md` (accepted Pattern 1 convention)
  - A "When to load this skill" section
  - A "When not to load this skill" section
  - A "References" section

**Command-type skills (`disable-model-invocation: true`) -- lighter rubric**

The autodetection shape requirement above does not apply -- these skills are typed by name, not matched against project context. Instead:

- Flag (warning): body does not contain a `## Procedure` section (or equivalent numbered step-by-step body).
- Flag (warning): body does not contain either a "Stop conditions" section or an "Output" section describing what the skill produces or when it halts.

**Pattern 1 structure check (SKILL.md + reference/)**

For skills that have a `reference/` subdirectory alongside `SKILL.md`: glob `reference/*.md`. For each reference file over 100 lines: flag (info) if the file does not contain a table of contents (a `## Contents` or `## Table of contents` heading, or a list of anchor links near the top of the file).

### Pass 2: Commands

Glob `~/.dotfiles/claude/skills/*/SKILL.md`, filtered to files whose frontmatter has `disable-model-invocation: true` -- the command-type skills. (`claude/commands/*/*.md` no longer exists: commit `3760001` migrated every command to `claude/skills/<group>-<name>/SKILL.md`.) For each matching file:

- Flag (failure): YAML frontmatter is absent entirely.
- Flag (info): `model` or `effort` fields are absent from frontmatter. (Info only -- optional but expected for high-complexity skills. `name`/`description` presence is already covered by Pass 1; `argument-hint` is not a skill frontmatter field and is not checked here.)
- Use `rg` to scan the body for deprecated `cmd-*` naming convention references (e.g., `/cmd-plan`, `/cmd-implement`). Flag each hit (warning) with the line number.
- Use `rg` to scan the body for unprefixed or stale-prefixed flow-step references -- the seven short names used by the `flow-*` group (`plan`, `implement`, `review`, `test`, `fix`, `resume`, `checks`) -- appearing as bare `/plan` etc. or old colon-namespaced `/flow:plan` etc., rather than the current hyphenated `/flow-plan` form. Pattern: `/\b(flow:)?(plan|implement|review|test|fix|resume|checks)\b` not preceded by a word character and not immediately preceded by `flow-`. Exclude `~/.dotfiles/claude/skills/audit-claude/SKILL.md` itself from this scan to avoid self-referential false positives. Flag each remaining hit (warning) with the line number.

### Pass 3: Hooks

Read `~/.claude/settings.json` with `jq '.hooks'`. Build a list of all wired hook script paths (de-duplicate by path).

For each wired hook path:

- Flag (failure): the script file does not exist at the stated path (e.g., `$HOME/.claude/hooks/foo.sh` resolved to the real path).
- Flag (failure): the script exists but is not executable (`[ -x ]`).
- For `PreToolUse` and `PostToolUse` entries only: flag (warning) if the `matcher` value is not a recognized Claude Code tool name or `|`-separated combination of them. Split the matcher on `|` and validate each token against the known-good set: `Bash`, `Edit`, `Write`, `MultiEdit`, `Skill`, `Read`, `Agent`, `WebFetch`, `WebSearch`, `Glob`, `Grep`, `LS`. Any unrecognized token gets a warning: "unrecognized matcher token, verify against current Claude Code hook docs".
- For `UserPromptSubmit` and `UserPromptExpansion` entries: these event types carry no `matcher` field by design. Skip the matcher check entirely; only validate that each entry's `hooks[].command` script exists and is executable.
- For `PreToolUse` + `Bash` matcher hooks: read the script body and check that it reads from stdin (sources `_lib.sh` and calls `read_payload`, or contains an explicit stdin read: `read`, `cat`, or `</dev/stdin`) and blocks via `exit 2`, either directly in the script body or by delegating to a shared helper that does (e.g. `_lib.sh`'s `block()` function, which itself calls `exit 2` -- check `_lib.sh` for the delegation rather than requiring the literal `exit 2` text in the hook script itself). Flag (warning) if the stdin-read pattern is absent, or if neither a direct `exit 2` nor a delegated block-helper call is found, because a PreToolUse Bash guard that does not read stdin or does not block is structurally broken.

Orphan check: glob `~/.dotfiles/claude/hooks/*.sh`. For each hook file NOT referenced in `settings.json` AND NOT named `_lib.sh` (which is a shared library, not a hook): flag (info) as "script exists on disk but is not wired in settings.json -- orphaned or intentionally disabled".

### Pass 4: Settings

Read `~/.claude/settings.json` with `jq`.

- Flag (warning): `permissions.allow` contains an entry of the form `Bash(*)` -- a bare wildcard that permits all bash commands without restriction.
- Flag (info): `permissions.allow` contains `Bash(rm *)` or `Bash(git push *)` -- potentially destructive commands that should require confirmation rather than be in the allowlist.
- Flag (info): `cleanupPeriodDays` is absent. If present, report its current value; do not treat any specific value as canonical unless it is stated as policy in `CLAUDE.md`.
- Flag (info): `skillListingBudgetFraction` is absent. If present, report its current value; values outside `0.02`-`0.05` are unusual and worth noting, but are not a violation.
- Flag (info): `includeCoAuthoredBy` is absent or `true` (expected `false` per project convention).

### Pass 5: Version currency

For each skill that covers a framework or language with version-sensitive behavior, read its `SKILL.md` and identify which version(s) it targets or describes.

Skills to examine (check `name` frontmatter against this list): `react-patterns`, `next-app-router-patterns`, `django-patterns`, `drf-patterns`, `fastapi-patterns`, `vue-patterns`, `nuxt-patterns`, `tailwind-patterns`, `typescript-patterns`, `python-patterns`, `javascript-patterns`, `bash-patterns`, `docker-patterns`. Skills not in this list (`git-patterns`, `wcag-audit`, `test-patterns`, `security-patterns`, `markdown-report`, `engineering-fundamentals`, `monitoring-patterns`, `logging-patterns`, `backup-patterns`, `vps-provisioning`) are intentionally excluded: they cover concepts or standards that do not resolve to a single versioned library in Context7.

For each examined skill:

1. Extract the version(s) the skill claims to cover (look for explicit version numbers, "vX", "X.x", "as of version", "targeting", etc.).
2. Use Context7 to fetch current documentation for the library: `mcp__context7__resolve-library-id` to get the library ID, then `mcp__context7__query-docs` to confirm the current latest stable version and any recent breaking changes.
3. Compare skill coverage against current stable.

The finding is NOT "upgrade the skill to latest". The finding is a version-currency note:

- Flag (warning): skill documents only a single version with no differentiation language and the current stable is a major version ahead. The fix is to add version-differentiation guidance (state which version the skill's advice applies to, what changes in the new major version, and that skills must adapt advice to the version present in the project being assisted).
- Flag (warning): skill advice references a deprecated API, removed flag, or changed syntax that is incorrect in the current stable version.
- Flag (info): skill targets a current-ish version but does not include a note that version-sensitive claims should be verified against the project's lockfile or `.tool-versions`. Reminder: each skill invocation should be adapted to the version found in the project being assisted, not the version the skill was authored against.
- Pass (no finding): skill already uses version-differentiation language ("as of vX", "in version Y and above", "check the project's lockfile") and covers a reasonably current range.

If Context7 returns no data for a library, mark "Cannot be verified via Context7 -- manually check <library> current stable." Do not flag the skill itself.

## Output

Use markdown-report format. Write to `$(scratch-dir.sh)/audit-claude-<YYYYMMDD-HHMM>.md`. Print the path.

Report structure:

```
# Audit: Claude Code configuration
**Date:** <YYYY-MM-DD>
**Scope:** <all | --area=value>

## Summary
<N failure(s), N warning(s), N info item(s). One sentence on the highest-priority finding.>

## Findings: Skills
...

## Findings: Commands
...

## Findings: Hooks
...

## Findings: Settings
...

## Findings: Version currency
...
```

Each finding entry:

```
### [SEVERITY] <skill-or-file-name>
**File:** `<absolute path>`
**Line:** <line number or "frontmatter">
**Finding:** <one sentence description>
**Remediation:** <one sentence concrete action>
```

Sort findings within each section by severity (failure first, then warning, then info).

## Rules

- Read only. Do not modify any audited file.
- If a pass cannot gather source data (file unreadable, jq parse error, Context7 unavailable), emit "Cannot be verified statically: <reason>" as an info item and move to the next pass.
- Pass 5 (version currency) requires Context7 and may take longer than the other passes. If `--area=` is used and does not include `versions`, skip Pass 5.
- Do not claim a skill is wrong because its advice differs from the latest version. The claim is specifically that the skill lacks version-differentiation language, which causes it to mislead on projects that differ from the skill's implicit version assumption.
- One report per invocation. Do not append to an existing report.
