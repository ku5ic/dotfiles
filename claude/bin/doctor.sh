#!/usr/bin/env bash
# Verifies the Claude config: symlink layout AND cross-file consistency.
# Used by .github/workflows/lint.yml and runnable locally.
#
# Checks:
#   1. Symlinks: each top-level claude/ entry is symlinked to the dotfiles
#      source. Verifies link existence and target path.
#   2. Credential pattern parity: guard-edit.sh, guard-bash.sh, and
#      settings.json all list every credential pattern. Both hook layers exist
#      as defense in depth (a misconfigured permission file should not be the
#      only thing standing between an injection and a clobbered key).
#   3. PM table parity: guard-bash.sh lockfile->manager table matches
#      _stacks.yml package_managers list.
#   4. Command frontmatter lint: every command .md has a valid model field and
#      matching effort field.
#   5. Skill map validation: skill_file_map and skill_triggers reference only
#      skills that exist, and every stack/extra skill has a trigger entry.
#
# Adding a credential pattern: add it to the `patterns` array below AND to
# hooks/guard-edit.sh's "Sensitive credential and key files" case block AND
# hooks/guard-bash.sh's _is_sensitive_arg block AND settings.json's deny array.
#
# Exit codes: 0 = all checks passed, 1 = one or more checks failed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ROOT="$HOME/.claude"

ENTRIES=(settings.json CLAUDE.md commands hooks skills bin)

exit_code=0

# CI runners have no ~/.claude install, so symlink targets never resolve correctly.
if [[ "${CI:-}" == "true" ]]; then
  echo "== symlinks == (skipped: running in CI)"
elif [[ -d "$TARGET_ROOT" ]]; then
  echo "== symlinks =="
  for entry in "${ENTRIES[@]}"; do
    src="$SOURCE_ROOT/$entry"
    dst="$TARGET_ROOT/$entry"

    if [[ ! -L "$dst" ]]; then
      if [[ -e "$dst" ]]; then
        echo "not-a-symlink  $dst"
      else
        echo "missing        $dst"
      fi
      exit_code=1
      continue
    fi

    actual="$(readlink "$dst")"
    if [[ "${actual%/}" != "$src" ]]; then
      echo "wrong-target   $dst -> $actual (expected $src)"
      exit_code=1
      continue
    fi

    echo "ok             $dst"
  done
else
  echo "== symlinks == (skipped: $TARGET_ROOT does not exist)"
fi

echo
echo "== credential pattern parity =="

GUARD_EDIT="$SOURCE_ROOT/hooks/guard-edit.sh"
GUARD_BASH="$SOURCE_ROOT/hooks/guard-bash.sh"
SETTINGS="$SOURCE_ROOT/settings.json"

# Canonical credential patterns. Each must appear verbatim in all three files.
# Path-tail forms are used so settings.json's `~/...` and the guard hooks'
# `$HOME/...` both contain the substring.
# Adding a pattern: add it here AND to guard-edit.sh, guard-bash.sh (_is_sensitive_arg),
# and settings.json deny rules.
patterns=(
  "*.pem"
  "*.key"
  "*.pfx"
  "*.p12"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
  ".env"
  ".env.*"
  ".ssh/"
  ".gnupg/"
  ".aws/credentials"
  ".aws/config"
  ".docker/config.json"
  ".config/gh/hosts.yml"
  ".netrc"
  ".pgpass"
  ".npmrc"
  "Library/Keychains/"
  ".pypirc"
  ".cargo/credentials"
  ".gem/credentials"
)

parity_failed=0
for pat in "${patterns[@]}"; do
  if ! grep -qF "$pat" "$GUARD_EDIT"; then
    echo "missing-pattern  guard-edit.sh: '$pat'"
    parity_failed=1
  fi
  if ! grep -qF "$pat" "$GUARD_BASH"; then
    echo "missing-pattern  guard-bash.sh: '$pat'"
    parity_failed=1
  fi
  if ! grep -qF "$pat" "$SETTINGS"; then
    echo "missing-pattern  settings.json: '$pat'"
    parity_failed=1
  fi
done

if ((parity_failed)); then
  exit_code=1
else
  echo "ok             ${#patterns[@]} patterns mirrored across guard-edit.sh, guard-bash.sh, and settings.json"
fi

echo
echo "== PM table parity =="

GUARD_BASH_PM="$SOURCE_ROOT/hooks/guard-bash.sh"
STACKS_YML="$SOURCE_ROOT/_stacks.yml"
pm_parity_failed=0

if ! command -v yq >/dev/null 2>&1; then
  echo "skip           yq not found; skipping PM table parity check"
else
  yml_pm="$(yq '.package_managers[] | .lockfile + ":" + .manager' "$STACKS_YML" 2>/dev/null | sort)"
  bash_pm="$(awk '/<<.*PM_LOCKFILES/{f=1; next} /^PM_LOCKFILES$/{f=0} f{print}' "$GUARD_BASH_PM" 2>/dev/null | sort)"
  if [[ "$yml_pm" == "$bash_pm" ]]; then
    echo "ok             guard-bash.sh PM table matches _stacks.yml"
  else
    echo "FAIL           guard-bash.sh PM table drifted from _stacks.yml"
    diff <(printf '%s\n' "$yml_pm") <(printf '%s\n' "$bash_pm") | head -20 || true
    pm_parity_failed=1
  fi
fi

if ((pm_parity_failed)); then
  exit_code=1
fi

echo
echo "== command frontmatter lint =="

if ! command -v yq >/dev/null 2>&1; then
  echo "skip           yq not found; install via Brewfile to enable frontmatter lint"
else
  COMMANDS_DIR="$SOURCE_ROOT/commands"
  fm_failed=0
  fm_count=0

  while IFS= read -r f; do
    fm_count=$((fm_count + 1))
    # Extract YAML frontmatter between the first pair of --- delimiters.
    fm=$(awk 'NR==1 && /^---$/{in_fm=1;next} in_fm && /^---$/{exit} in_fm{print}' "$f")
    rel="${f#"$SOURCE_ROOT/"}"

    if [[ -z "$fm" ]]; then
      echo "missing-frontmatter  $rel"
      fm_failed=1
      continue
    fi

    # Filter to just model/effort lines before passing to yq: other frontmatter
    # fields (e.g. argument-hint: <...>) contain angle brackets that yq rejects
    # as invalid YAML.
    fm_safe=$(printf '%s\n' "$fm" | grep -E '^(model|effort):')
    model=$(printf '%s\n' "$fm_safe" | yq '.model // ""' 2>/dev/null || true)
    effort=$(printf '%s\n' "$fm_safe" | yq '.effort // ""' 2>/dev/null || true)
    # yq may emit the literal string "null" for absent keys; normalize to empty.
    [[ "$model" == "null" ]] && model=""
    [[ "$effort" == "null" ]] && effort=""

    if [[ -z "$model" ]]; then
      echo "missing-model    $rel"
      fm_failed=1
    else
      case "$model" in
      fable | opus | sonnet | haiku | best | opusplan | "sonnet[1m]" | "opus[1m]" | inherit | default | claude-*)
        ;;
      *)
        echo "invalid-model    $rel: '$model'"
        fm_failed=1
        ;;
      esac
    fi

    if [[ "$model" == "sonnet" || "$model" == "opus" ]] && [[ -z "$effort" ]]; then
      echo "missing-effort   $rel: model=$model requires effort"
      fm_failed=1
    fi

    if [[ "$model" == "haiku" && -n "$effort" ]]; then
      echo "extra-effort     $rel: haiku does not support effort (got '$effort')"
      fm_failed=1
    fi

    if [[ -n "$effort" ]]; then
      case "$effort" in
      low | medium | high | xhigh | max)
        ;;
      *)
        echo "invalid-effort   $rel: '$effort'"
        fm_failed=1
        ;;
      esac
    fi

  done < <(find "$COMMANDS_DIR" -name "*.md" -type f | sort)

  if ((fm_failed)); then
    exit_code=1
  else
    echo "ok             $fm_count commands passed frontmatter lint"
  fi
fi

echo
echo "== skill map validation =="

if ! command -v yq >/dev/null 2>&1; then
  echo "skip           yq not found; skipping skill map validation"
else
  STACKS_YML_SRC="$SOURCE_ROOT/_stacks.yml"
  SKILLS_DIR="$SOURCE_ROOT/skills"
  sm_failed=0

  # Collect every skill named in skill_file_map[].skills[].
  mapfile -t sfm_skills < <(yq '.skill_file_map // [] | .[].skills // [] | .[]' "$STACKS_YML_SRC" 2>/dev/null | sort -u)
  for sk in "${sfm_skills[@]}"; do
    if [[ ! -d "$SKILLS_DIR/$sk" ]]; then
      echo "missing-skill    skill_file_map references '$sk' but $SKILLS_DIR/$sk/ does not exist"
      sm_failed=1
    fi
  done

  # Collect every key in skill_triggers.
  mapfile -t trigger_skills < <(yq '.skill_triggers // {} | keys | .[]' "$STACKS_YML_SRC" 2>/dev/null | sort -u)
  for sk in "${trigger_skills[@]}"; do
    if [[ ! -d "$SKILLS_DIR/$sk" ]]; then
      echo "missing-skill    skill_triggers references '$sk' but $SKILLS_DIR/$sk/ does not exist"
      sm_failed=1
    fi
  done

  # Every skill mapped in stacks[].skills[] or stacks[].extras[].skills[]
  # (stack/extra skills; global_skills excluded) must have a skill_triggers entry.
  # Plugin skills are out of scope: no mapped skill is a plugin skill.
  mapfile -t stack_skills < <(
    {
      yq '.stacks | to_entries[] | .value.skills // [] | .[]' "$STACKS_YML_SRC" 2>/dev/null
      yq '.stacks | to_entries[] | .value.extras // [] | .[].skills // [] | .[]' "$STACKS_YML_SRC" 2>/dev/null
    } | sort -u
  )
  mapfile -t global_skill_list < <(yq '.global_skills // [] | .[]' "$STACKS_YML_SRC" 2>/dev/null | sort -u)

  for sk in "${stack_skills[@]}"; do
    [[ -z "$sk" ]] && continue
    # Skip skills that are in global_skills; they are required, not suggested.
    is_global=0
    for gsk in "${global_skill_list[@]}"; do
      [[ "$gsk" == "$sk" ]] && is_global=1 && break
    done
    ((is_global)) && continue

    trigger="$(yq ".skill_triggers.\"${sk}\" // \"\"" "$STACKS_YML_SRC" 2>/dev/null || true)"
    if [[ -z "$trigger" || "$trigger" == "null" ]]; then
      echo "missing-trigger  stack/extra maps '$sk' but skill_triggers has no entry for it"
      sm_failed=1
    fi
  done

  if ((sm_failed)); then
    exit_code=1
  else
    echo "ok             skill_file_map (${#sfm_skills[@]} skills), skill_triggers (${#trigger_skills[@]} entries), stack coverage all valid"
  fi
fi

exit "$exit_code"
