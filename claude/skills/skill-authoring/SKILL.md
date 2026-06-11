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

## Single-file vs Pattern 1 (index + reference files)

The denominator is content shape, not line count.

- **Pattern 1**: when the skill has multiple distinct sub-domains, each substantial enough to be its own reference. Layout: `SKILL.md` as index + `reference/<topic>.md` files for each sub-domain. SKILL.md links to reference files explicitly.
- **Single SKILL.md**: when the topic is one cohesive flow.

By the sub-domain test, framework and language skills with distinct expertise areas are Pattern 1. Single-topic skills (logging, monitoring, backup, git) are single-file.

Reference files over 100 lines need a table of contents at the top.

## Verification rule

Every version-sensitive claim, library version, syntax form, framework feature, and tooling recommendation must be verified against authoritative sources before shipping. When creating or substantially editing a skill, produce a verification log saved to `~/.claude/scratch/verification-<skill>-<YYYYMMDD-HHMM>.md` listing each claim and its source URL. If a claim cannot be verified, omit it. No freestyling.

## Anti-patterns

- `failure`: description missing either project signals or keyword aliases -- the skill will not autodetect reliably on the required cases.
- `failure`: skill body instructs Claude to load a companion skill by name -- breaks the autodetection contract.
- `warning`: shipping version-sensitive claims without a verification log -- claims that cannot be verified must be omitted, not asserted.
- `warning`: body written in descriptive rather than imperative voice ("Claude should..." instead of just the rule).
- `info`: choosing Pattern 1 for a single-cohesive-topic skill -- use single-file when the topic is one flow.

## Severity rubric (matches markdown-report)

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

No new severity levels.

## When to load this skill

- Editing any file under `~/.dotfiles/claude/skills/` or `~/.claude/skills/`
- Editing a `SKILL.md` file anywhere in the repo
- User asks about authoring a skill, writing a skill description, skill file structure, or skill conventions
- User asks "what makes a good skill description" or similar phrasing

## When not to load this skill

- Merely using a skill during a flow or audit cycle
- Editing command files under `claude/commands/` (different format, no skill conventions apply)
- Editing `_stacks.yml` (stack config, not skill authoring)

## References

- Scratch artifact naming: `~/.dotfiles/claude/rules/scratch-conventions.md`

## Maintenance note

Skill conventions evolve when new structural patterns emerge (new layout patterns beyond single-file and Pattern 1), when the description contract changes (new required fields), or when the severity rubric changes.
