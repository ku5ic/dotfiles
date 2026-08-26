---
name: skill-authoring
description: Rules and conventions for authoring or editing Claude Code skills in `~/.dotfiles/claude/skills/`. Use whenever editing a SKILL.md file or any file under `claude/skills/`, OR the user asks about authoring a skill, editing a skill, skill descriptions, skill conventions, or skill structure, even if the word "skill" is not used.
---

# Skill authoring conventions

Rules for authoring or editing skills in `~/.dotfiles/claude/skills/`. Apply to every skill, present and future.

## Autodetection over named cross-references

Skills load based on their own descriptions matching the project context, not because one skill instructs Claude to load another. A skill's description must:

- Trigger on concrete project signals (file extensions, sentinel files like `manage.py` or `next.config.js`, dependency markers in `package.json` or `pyproject.toml`, distinctive syntax).
- Trigger on keyword aliases (the user mentioning the technology, even informally).
- NOT instruct Claude to "load skill X alongside this one" or "see also skill Y".
- NOT enumerate companion skills in the body as "load these together".

Skills load in combination because each skill's independent triggers all match the same project. A TypeScript Next.js project loads `typescript-patterns`, `react-patterns`, and `next-app-router-patterns` because each description independently matches the project's signals, not because one skill names the others.

Documentation references to other skills as concepts ("framework-specific patterns live in their respective skills") are acceptable. Load instructions that name other skills are not.

## Description shape

> [What the skill is, one phrase]. Use whenever [project signals], OR the user asks about [keyword aliases], even if [the technology] is not mentioned by name.

Both project signals and keyword aliases are required.

## Body conventions

- Imperative voice, terse.
- Plain ASCII punctuation. ASCII arrows (`->`, `<-`) only.
- Anti-patterns section with severity calls (`failure`, `warning`, `info`).
- "When to load this skill" section listing concrete triggers.
- "When not to load this skill" section listing exclusions (NEVER name other skills).
- "References" section with verified URLs.
- Maintenance note acknowledging the ecosystem will evolve.
- Procedure structure follows `rules/adhd-output.md` - see ADHD-output compliance below.

## ADHD-output compliance

Skill bodies (the procedure in `SKILL.md`) follow `rules/adhd-output.md` with no exception - the reader executes these turn by turn, so a wall-of-text or multi-action step costs real working memory. Matters most for user-invoked skills (`flow-*`, `audit-*`, `meta-*`, `write-*`); they get read and acted on directly, unlike patterns skills that are mostly reference lookups.

- Scope: `reference/<topic>.md` files are a different content shape - lookup/catalog material, not sequential procedure.
- Exemption: a dense 2-3 sentence technical explanation under its own header is not a violation there - it's normal for a reader consulting one entry, not holding the whole file in working memory.
- Still fix: an enumerable list of named items crammed into one prose sentence, or a multi-branch conditional written as prose instead of a nested list.
- Don't: flatten reference material into bullet soup on principle.

Recurring defect patterns to avoid on first write, not just catch on review:

- A numbered step packing 2+ distinct actions into one sentence instead of a numbered sub-list.
- Enumerable criteria (3+ named cases) inlined as a comma-separated parenthetical when a sibling step in the same file already uses a bullet list for the same shape - internal inconsistency, pick one style.
- "Tool A (...) or tool B (...)" comparisons crammed into a single sentence instead of split bullets.
- A violating block copy-pasted verbatim across sibling skills (e.g. two stack-pattern skills sharing an anti-pattern paragraph) - fix once, then check siblings for the same text.

## Single-file vs Pattern 1 (index + reference files)

The denominator is content shape, not line count.

- **Pattern 1**: when the skill has multiple distinct sub-domains, each substantial enough to be its own reference. Layout: `SKILL.md` as index + `reference/<topic>.md` files for each sub-domain. SKILL.md links to reference files explicitly.
- **Single SKILL.md**: when the topic is one cohesive flow.

By the sub-domain test, framework and language skills with distinct expertise areas are Pattern 1. Single-topic skills (logging, monitoring, backup, git) are single-file.

Reference files over 100 lines need a table of contents at the top.

## Verification rule

Every version-sensitive claim, library version, syntax form, framework feature, and tooling recommendation must be verified against authoritative sources before shipping.

- When creating or substantially editing a skill, produce a verification log saved to `$(scratch-dir.sh)/verification-<skill>-<YYYYMMDD-HHMM>.md` listing each claim and its source URL.
- If a claim cannot be verified, omit it. No freestyling.

## Anti-patterns

- `failure`: description missing either project signals or keyword aliases -- the skill will not autodetect reliably on the required cases.
- `failure`: skill body instructs Claude to load a companion skill by name -- breaks the autodetection contract.
- `warning`: shipping version-sensitive claims without a verification log -- claims that cannot be verified must be omitted, not asserted.
- `warning`: body written in descriptive rather than imperative voice ("Claude should..." instead of just the rule).
- `warning`: a procedure step packs 2+ distinct actions into one prose sentence instead of a numbered sub-list -- rules/adhd-output.md rule 3/8.
- `info`: choosing Pattern 1 for a single-cohesive-topic skill -- use single-file when the topic is one flow.
- `info`: reference-file prose reformatted into fragmented bullets when it was already a coherent 2-3 sentence explanation -- reference material is lookup, not procedure; not every dense paragraph is a violation.

## Severity rubric (matches `rules/markdown-report.md`)

No new severity levels.

## When to load this skill

- Editing any file under `~/.dotfiles/claude/skills/` or `~/.claude/skills/`
- Editing a `SKILL.md` file anywhere in the repo
- User asks about authoring a skill, writing a skill description, skill file structure, or skill conventions
- User asks "what makes a good skill description" or similar phrasing

## When not to load this skill

- Merely using a skill during a flow or audit cycle
- Editing `_stacks.yml` (stack config, not skill authoring)

## References

- Scratch artifact naming: `~/.dotfiles/claude/rules/scratch-conventions.md`

## Maintenance note

Skill conventions evolve when:

- New structural patterns emerge (new layout patterns beyond single-file and Pattern 1).
- The description contract changes (new required fields).
- The severity rubric changes.

The ADHD-output compliance section was added after a full-corpus audit (49 skill bodies, 117 reference files) found real wall-of-text and multi-action-step violations concentrated in procedure bodies, and confirmed reference files are a different content shape - revisit if that boundary stops holding.
