#!/usr/bin/env bash
# statusLine command (see claude/settings.json). Reads the payload Claude Code
# pipes to stdin and prints a two-row status: model/dir/git on row 1,
# context/cost/effort/rate-limit on row 2. Never blocks a render: a missing
# jq, a missing field, or any other unexpected error falls through to a
# best-effort or blank line rather than raising.

set -euo pipefail
trap 'exit 0' ERR

readonly CACHE_TTL=5  # seconds; matches the git-status refresh window in the spec
readonly BAR_WIDTH=10 # blocks in the context-usage bar
readonly YELLOW_AT=70 # bar turns yellow at >=70% context used
readonly RED_AT=90    # bar turns red at >=90% context used

payload="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "statusline: jq not found"
  exit 0
fi

# One value per line, read via a while-read loop rather than `IFS=$'\t' read`
# (tab is IFS whitespace, so `read` collapses consecutive empty tab fields and
# silently shifts every later value one slot left) or `mapfile` (bash 4+ only;
# `env bash` can resolve to the stock macOS bash 3.2 if Homebrew's bash isn't
# first on the invoking process's PATH).
fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(
  jq -r '
    (.model.display_name // "unknown"),
    (.workspace.current_dir // ""),
    (.session_id // ""),
    (.context_window.used_percentage // 0),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.effort.level // ""),
    (.rate_limits.five_hour.used_percentage // "")
  ' <<<"$payload"
)
# Empty or invalid-JSON stdin makes jq exit non-zero with no stdout, leaving
# fields short; pad to the 8 values above so indexing below can't hit
# `set -u`'s unbound-variable error (which bypasses the ERR trap).
while ((${#fields[@]} < 8)); do fields+=(""); done
model_name="${fields[0]}"
cwd="${fields[1]}"
session_id="${fields[2]}"
ctx_pct="${fields[3]}"
cost_usd="${fields[4]}"
duration_ms="${fields[5]}"
effort_level="${fields[6]}"
five_h="${fields[7]}"

dir_name="$(basename "${cwd:-.}")"

safe_session_id="${session_id//[^a-zA-Z0-9_-]/}"
cache_dir="$HOME/.claude/cache/statusline"
git_cache_file="$cache_dir/git-${safe_session_id:-nosession}"

git_segment=""
if [[ -n "$cwd" ]] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mkdir -p "$cache_dir"
  now="$(date +%s)"
  cache_mtime=0
  [[ -f "$git_cache_file" ]] && cache_mtime="$(stat -c '%Y' "$git_cache_file" 2>/dev/null || stat -f '%m' "$git_cache_file" 2>/dev/null || echo 0)"
  if ((now - cache_mtime >= CACHE_TTL)) || [[ ! -s "$git_cache_file" ]]; then
    branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
    staged="$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')"
    modified="$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')"
    tmp="$(mktemp)"
    printf '%s +%s ~%s\n' "${branch:-detached}" "$staged" "$modified" >"$tmp"
    mv "$tmp" "$git_cache_file"
  fi
  git_segment="$(cat "$git_cache_file" 2>/dev/null)"
fi

row1="$model_name  $dir_name"
[[ -n "$git_segment" ]] && row1="$row1  $git_segment"

ctx_int="${ctx_pct%%.*}"
[[ -z "$ctx_int" ]] && ctx_int=0
((ctx_int < 0)) && ctx_int=0
((ctx_int > 100)) && ctx_int=100
filled=$((ctx_int / (100 / BAR_WIDTH)))

if ((ctx_int >= RED_AT)); then
  color=$'\033[31m'
elif ((ctx_int >= YELLOW_AT)); then
  color=$'\033[33m'
else
  color=$'\033[32m'
fi
reset=$'\033[0m'

bar=""
for ((i = 0; i < BAR_WIDTH; i++)); do
  if ((i < filled)); then
    bar+="█"
  else
    bar+="░"
  fi
done

cost_fmt="$(printf '%.2f' "$cost_usd" 2>/dev/null || echo "$cost_usd")"

duration_s=$((duration_ms / 1000))
if ((duration_s >= 60)); then
  duration_fmt="$((duration_s / 60))m$((duration_s % 60))s"
else
  duration_fmt="${duration_s}s"
fi

row2="${color}${bar}${reset} ${ctx_int}%  \$${cost_fmt}  ${duration_fmt}"
[[ -n "$effort_level" ]] && row2="$row2  effort:${effort_level}"
[[ -n "$five_h" ]] && row2="$row2  5h:${five_h%%.*}%"

printf '%s\n%s\n' "$row1" "$row2"
