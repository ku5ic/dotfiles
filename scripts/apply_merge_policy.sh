#!/usr/bin/env bash
set -euo pipefail

# apply_merge_policy
#
# Apply consistent merge settings and branch protection to all GitHub repos
# owned by the authenticated user. Archived repos are always skipped.
#
# Merge settings applied per repo:
#   allow_squash_merge          = true   (only merge strategy)
#   allow_merge_commit          = false
#   allow_rebase_merge          = false
#   allow_auto_merge            = true
#   delete_branch_on_merge      = true
#   allow_update_branch         = true
#   squash_merge_commit_title   = PR_TITLE
#   squash_merge_commit_message = PR_BODY
#
# Branch protection applied to the default branch:
#   required_linear_history = true   (enforces squash-only at the git level)
#   allow_force_pushes      = false
#   allow_deletions         = false
#   enforce_admins          = false  (repo owner bypasses all rules)
#
# Requirements: gh (authenticated), jq.

die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: apply_merge_policy [--yes | --dry-run]

Apply consistent merge settings and branch protection to all GitHub repos owned
by the authenticated user. Archived repos are always skipped.

Flags:
  -y, --yes      Apply to all repos without prompting
  -n, --dry-run  Print current settings per repo; do nothing
  -h, --help     Print this help

Prompt responses (interactive mode):
  y  apply
  n  skip (default)
  q  quit
EOF
}

mode="interactive"
for arg in "$@"; do
  case "$arg" in
  --yes | -y) mode="yes" ;;
  --dry-run | -n) mode="dry-run" ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "unknown argument: $arg" >&2
    usage >&2
    exit 2
    ;;
  esac
done

command -v gh >/dev/null 2>&1 || die "gh CLI not found"
command -v jq >/dev/null 2>&1 || die "jq not found"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated -- run: gh auth login"

gh_login="$(gh api user --jq '.login')"
echo "Authenticated as: $gh_login"
echo "Mode: $mode"
echo

# affiliation=owner excludes collaborator and org repos
mapfile -t repos < <(
  gh api --paginate \
    -H "Accept: application/vnd.github+json" \
    "/user/repos?affiliation=owner&per_page=100" \
    --jq '.[] | "\(.full_name)\t\(.archived)\t\(.fork)\t\(.default_branch)"'
)

total=${#repos[@]}
echo "Found $total repos owned by $gh_login."
echo

changed=0
skipped=0
failed=0

apply_settings() {
  local full_name="$1"
  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$full_name" \
    -F allow_squash_merge=true \
    -F allow_merge_commit=false \
    -F allow_rebase_merge=false \
    -F allow_auto_merge=true \
    -F delete_branch_on_merge=true \
    -F allow_update_branch=true \
    -f squash_merge_commit_title=PR_TITLE \
    -f squash_merge_commit_message=PR_BODY \
    >/dev/null
}

# Prints one line per field that differs from the target policy.
# Prints nothing when the repo already matches -- callers use empty output as
# the "already up to date" signal.
show_diff() {
  local full_name="$1"
  gh api "/repos/$full_name" --jq '
    [
      if .allow_squash_merge        != true      then "allow_squash_merge: \(.allow_squash_merge) -> true"               else empty end,
      if .allow_merge_commit        != false     then "allow_merge_commit: \(.allow_merge_commit) -> false"               else empty end,
      if .allow_rebase_merge        != false     then "allow_rebase_merge: \(.allow_rebase_merge) -> false"               else empty end,
      if .allow_auto_merge          != true      then "allow_auto_merge: \(.allow_auto_merge) -> true"                   else empty end,
      if .delete_branch_on_merge    != true      then "delete_branch_on_merge: \(.delete_branch_on_merge) -> true"       else empty end,
      if .allow_update_branch       != true      then "allow_update_branch: \(.allow_update_branch) -> true"             else empty end,
      if .squash_merge_commit_title != "PR_TITLE" then "squash_merge_commit_title: \(.squash_merge_commit_title) -> PR_TITLE" else empty end,
      if .squash_merge_commit_message != "PR_BODY" then "squash_merge_commit_message: \(.squash_merge_commit_message) -> PR_BODY" else empty end
    ] | .[]
  '
}

# Prints one line per protection field that differs from the target.
# Prints nothing when already matching. On 404 (no rule exists), prints all
# four fields as needing change.
show_protection_diff() {
  local full_name="$1" default_branch="$2"
  local response
  if ! response="$(gh api "/repos/$full_name/branches/$default_branch/protection" 2>/dev/null)"; then
    printf '%s\n' \
      "required_linear_history: (none) -> true" \
      "allow_force_pushes: (none) -> false" \
      "allow_deletions: (none) -> false" \
      "enforce_admins: (none) -> false"
    return 0
  fi
  printf '%s' "$response" | jq -r '
    [
      if .required_linear_history.enabled != true  then "required_linear_history: \(.required_linear_history.enabled) -> true"  else empty end,
      if .allow_force_pushes.enabled      != false then "allow_force_pushes: \(.allow_force_pushes.enabled) -> false"            else empty end,
      if .allow_deletions.enabled         != false then "allow_deletions: \(.allow_deletions.enabled) -> false"                  else empty end,
      if .enforce_admins.enabled          != false then "enforce_admins: \(.enforce_admins.enabled) -> false"                    else empty end
    ] | .[]
  '
}

apply_branch_protection() {
  local full_name="$1" default_branch="$2"
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$full_name/branches/$default_branch/protection" \
    --input - <<'BODY' >/dev/null
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false
}
BODY
}

i=0
for line in "${repos[@]}"; do
  i=$((i + 1))
  IFS=$'\t' read -r full_name archived fork default_branch <<<"$line"

  echo "[$i/$total] $full_name (archived=$archived, fork=$fork, default=$default_branch)"

  if [[ "$archived" == "true" ]]; then
    echo "  skipped: archived"
    skipped=$((skipped + 1))
    echo
    continue
  fi

  merge_diff="$(show_diff "$full_name")"
  protection_diff="$(show_protection_diff "$full_name" "$default_branch")"

  case "$mode" in
  dry-run)
    if [[ -z "$merge_diff" && -z "$protection_diff" ]]; then
      echo "  already up to date"
      skipped=$((skipped + 1))
    else
      if [[ -n "$merge_diff" ]]; then
        echo "  merge policy - would change:"
        echo "    ${merge_diff//$'\n'/$'\n    '}"
      fi
      if [[ -n "$protection_diff" ]]; then
        echo "  branch protection - would change:"
        echo "    ${protection_diff//$'\n'/$'\n    '}"
      fi
    fi
    ;;
  yes)
    if [[ -z "$merge_diff" && -z "$protection_diff" ]]; then
      echo "  already up to date"
      skipped=$((skipped + 1))
    else
      apply_ok=true
      if [[ -n "$merge_diff" ]]; then
        if apply_settings "$full_name"; then
          echo "  merge policy: applied"
        else
          echo "  merge policy: failed"
          apply_ok=false
        fi
      fi
      if [[ -n "$protection_diff" ]]; then
        if apply_branch_protection "$full_name" "$default_branch"; then
          echo "  branch protection: applied"
        else
          echo "  branch protection: failed"
          apply_ok=false
        fi
      fi
      if [[ "$apply_ok" == true ]]; then
        changed=$((changed + 1))
      else
        failed=$((failed + 1))
      fi
    fi
    ;;
  interactive)
    if [[ -z "$merge_diff" && -z "$protection_diff" ]]; then
      echo "  already up to date"
      skipped=$((skipped + 1))
    else
      if [[ -n "$merge_diff" ]]; then
        echo "  merge policy - would change:"
        echo "    ${merge_diff//$'\n'/$'\n    '}"
      fi
      if [[ -n "$protection_diff" ]]; then
        echo "  branch protection - would change:"
        echo "    ${protection_diff//$'\n'/$'\n    '}"
      fi
      read -r -p "  apply changes to this repo? [y/N/q] " ans </dev/tty
      case "$ans" in
      y | Y)
        apply_ok=true
        if [[ -n "$merge_diff" ]]; then
          if apply_settings "$full_name"; then
            echo "  merge policy: applied"
          else
            echo "  merge policy: failed"
            apply_ok=false
          fi
        fi
        if [[ -n "$protection_diff" ]]; then
          if apply_branch_protection "$full_name" "$default_branch"; then
            echo "  branch protection: applied"
          else
            echo "  branch protection: failed"
            apply_ok=false
          fi
        fi
        if [[ "$apply_ok" == true ]]; then
          changed=$((changed + 1))
        else
          failed=$((failed + 1))
        fi
        ;;
      q | Q)
        echo "  quitting"
        break
        ;;
      *)
        echo "  skipped"
        skipped=$((skipped + 1))
        ;;
      esac
    fi
    ;;
  esac
  echo
done

echo "Summary:"
echo "  changed: $changed"
echo "  skipped: $skipped"
echo "  failed:  $failed"
