#!/usr/bin/env bash
# asdf-update-tool-versions
#
# Inspects a .tool-versions file and proposes updates per language policy:
#   - nodejs : latest LTS major, latest patch (Node has a real LTS track)
#   - python : latest stable patch on the highest non-EOL minor (no LTS exists)
#   - ruby   : latest stable (no LTS exists)
#   - other  : asdf latest <plugin> (best-effort fallback)
#
# Default behavior is dry run. Pass --write to update the file in place.
# Pass --install to also run `asdf install` for each new version (implies --write).
#
# Requires: asdf (>= 0.16), curl, awk, sed, sort. jq is optional but recommended.

set -euo pipefail

# ---------- config ----------

TOOL_VERSIONS_FILE="${TOOL_VERSIONS_FILE:-.tool-versions}"
WRITE=0
INSTALL=0

# ---------- args ----------

usage() {
  cat <<'EOF'
Usage: asdf-update-tool-versions [options] [path-to-.tool-versions]

Options:
  -w, --write       Rewrite the file in place after computing updates.
  -i, --install     Run `asdf install` for each new version. Implies --write.
  -h, --help        Show this help.

Without flags the script prints a diff and exits 0.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--write)   WRITE=1; shift ;;
    -i|--install) WRITE=1; INSTALL=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    -*)           echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *)            TOOL_VERSIONS_FILE="$1"; shift ;;
  esac
done

if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
  echo "error: $TOOL_VERSIONS_FILE not found" >&2
  exit 1
fi

# ---------- deps ----------

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required" >&2; exit 1; }
}
need curl
need awk
need sed
need sort
need asdf

HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

# ---------- helpers ----------

# Compare two semver-ish version strings. Echoes the larger one. Ignores
# pre-release suffixes by trimming at the first non [0-9.] character.
vmax() {
  local a="${1%%[^0-9.]*}"
  local b="${2%%[^0-9.]*}"
  printf '%s\n%s\n' "$a" "$b" | sort -V | tail -n1
}

# Extract first major.minor (e.g. "3.13.1" -> "3.13").
minor_of() {
  local v="$1"
  echo "${v%.*}"
}

# ---------- resolvers ----------

# Node: latest LTS major, latest patch.
# Source: https://nodejs.org/dist/index.json (entries with "lts" != false).
resolve_nodejs() {
  local json
  json="$(curl -fsSL https://nodejs.org/dist/index.json)" || return 1

  if [[ $HAS_JQ -eq 1 ]]; then
    # Pick highest LTS major, then highest version within that major.
    jq -r '
      [ .[] | select(.lts != false) ] as $lts
      | ($lts | map(.version | ltrimstr("v") | split(".")[0] | tonumber) | max) as $maxmajor
      | $lts
      | map(select((.version | ltrimstr("v") | split(".")[0] | tonumber) == $maxmajor))
      | .[0].version
      | ltrimstr("v")
    ' <<<"$json"
  else
    # awk fallback: parse the array, keep only LTS entries, find the highest major,
    # then within that major emit the first (newest) version.
    echo "$json" \
      | tr ',{}' '\n' \
      | awk '
          /"version"/ { gsub(/[" ]/,""); split($0,a,":"); v=a[2]; sub(/^v/,"",v); next }
          /"lts"/ {
            gsub(/[" ]/,"");
            split($0,a,":");
            if (a[2] != "false") {
              split(v,b,".");
              maj=b[1]+0;
              print maj, v;
            }
          }
        ' \
      | sort -k1,1nr -k2,2Vr \
      | awk 'NR==1 { for (i=2;i<=NF;i++) printf "%s%s", $i, (i==NF?"\n":" ") }' \
      | awk '{ print $1 }'
  fi
}

# Python: latest stable patch on highest non-EOL minor.
# Source: https://endoflife.date/api/python.json
resolve_python() {
  local json today
  json="$(curl -fsSL https://endoflife.date/api/python.json)" || return 1
  today="$(date -u +%Y-%m-%d)"

  if [[ $HAS_JQ -eq 1 ]]; then
    jq -r --arg today "$today" '
      [ .[]
        | select(.eol == false or (.eol | strptime("%Y-%m-%d") | mktime) > ($today | strptime("%Y-%m-%d") | mktime))
        | select(.latest | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
      ]
      | sort_by(.cycle | split(".") | map(tonumber))
      | last
      | .latest
    ' <<<"$json"
  else
    # Crude fallback: take the first "latest" field whose cycle is highest.
    # endoflife.date returns newest cycle first, so this is usually the first
    # entry with eol==false. Good enough for the no-jq path.
    echo "$json" \
      | tr ',{}' '\n' \
      | awk '
          /"cycle"/   { gsub(/[" ]/,""); split($0,a,":"); cyc=a[2]; next }
          /"latest"/  { gsub(/[" ]/,""); split($0,a,":"); lat=a[2]; next }
          /"eol"/     {
            gsub(/[" ]/,"");
            split($0,a,":");
            if (a[2]=="false" && lat ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {
              print cyc, lat; exit
            }
          }
        ' \
      | awk '{ print $2 }'
  fi
}

# Ruby: latest stable. asdf already does the right thing here.
resolve_ruby() {
  asdf latest ruby
}

# Generic fallback for anything else listed in .tool-versions.
resolve_default() {
  local plugin="$1"
  asdf latest "$plugin" 2>/dev/null || return 1
}

resolve_for_plugin() {
  local plugin="$1"
  case "$plugin" in
    nodejs|node) resolve_nodejs ;;
    python)      resolve_python ;;
    ruby)        resolve_ruby ;;
    *)           resolve_default "$plugin" ;;
  esac
}

policy_for_plugin() {
  case "$1" in
    nodejs|node) echo "lts (latest major, latest patch)" ;;
    python)      echo "latest patch on highest non-EOL minor" ;;
    ruby)        echo "latest stable" ;;
    *)           echo "asdf latest (fallback)" ;;
  esac
}

# ---------- main ----------

# Read the file, preserving order. We process line by line so comments and
# blank lines round-trip cleanly.
declare -a ORDERED_LINES=()
declare -a UPDATES=()  # rows: "plugin|current|proposed|policy|status"

while IFS= read -r line || [[ -n "$line" ]]; do
  ORDERED_LINES+=("$line")
done < "$TOOL_VERSIONS_FILE"

# Build the proposal table.
for line in "${ORDERED_LINES[@]}"; do
  # Skip blanks and comments.
  if [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]]; then
    continue
  fi

  # asdf supports multiple versions per line (fallback chain). We only touch
  # the first one and leave the rest alone.
  read -r plugin current _rest <<<"$line"
  [[ -z "${plugin:-}" || -z "${current:-}" ]] && continue

  policy="$(policy_for_plugin "$plugin")"
  if proposed="$(resolve_for_plugin "$plugin")" && [[ -n "$proposed" ]]; then
    if [[ "$proposed" == "$current" ]]; then
      status="up-to-date"
    elif [[ "$(vmax "$current" "$proposed")" == "$current" ]]; then
      # Current is already newer than what we resolved. Don't downgrade.
      status="skip (current is newer)"
      proposed="$current"
    else
      status="update"
    fi
  else
    proposed="$current"
    status="skip (no resolver)"
  fi

  UPDATES+=("${plugin}|${current}|${proposed}|${policy}|${status}")
done

# Print the table.
printf '%-12s %-14s %-14s %-40s %s\n' "PLUGIN" "CURRENT" "PROPOSED" "POLICY" "STATUS"
printf '%-12s %-14s %-14s %-40s %s\n' "------" "-------" "--------" "------" "------"
for row in "${UPDATES[@]}"; do
  IFS='|' read -r p c n pol s <<<"$row"
  printf '%-12s %-14s %-14s %-40s %s\n' "$p" "$c" "$n" "$pol" "$s"
done

# Stop here if dry run.
if [[ $WRITE -eq 0 ]]; then
  echo
  echo "dry run. pass --write to update $TOOL_VERSIONS_FILE."
  exit 0
fi

# Optionally install before writing, so we don't pin to something asdf can't fetch.
# Install failures are non-fatal: we report them and skip writing that pin, but
# continue with the rest. This avoids a single failing tool aborting the whole run.
declare -A INSTALL_FAILED=()
if [[ $INSTALL -eq 1 ]]; then
  for row in "${UPDATES[@]}"; do
    IFS='|' read -r p _c n _pol s <<<"$row"
    [[ "$s" == "update" ]] || continue
    echo "installing $p $n ..."
    if ! asdf install "$p" "$n"; then
      echo "  install failed for $p $n; will not pin this tool" >&2
      INSTALL_FAILED["$p"]=1
    fi
  done
fi

# Rewrite the file, preserving order, comments, and any trailing fallback versions.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Build a quick lookup: plugin -> proposed. Skip anything whose install failed.
declare -A PROPOSED_BY_PLUGIN=()
for row in "${UPDATES[@]}"; do
  IFS='|' read -r p _c n _pol s <<<"$row"
  if [[ "$s" == "update" && -z "${INSTALL_FAILED[$p]:-}" ]]; then
    PROPOSED_BY_PLUGIN["$p"]="$n"
  fi
done

for line in "${ORDERED_LINES[@]}"; do
  if [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]]; then
    printf '%s\n' "$line" >>"$tmp"
    continue
  fi
  read -r plugin current rest <<<"$line"
  if [[ -n "${PROPOSED_BY_PLUGIN[$plugin]:-}" ]]; then
    if [[ -n "${rest:-}" ]]; then
      printf '%s %s %s\n' "$plugin" "${PROPOSED_BY_PLUGIN[$plugin]}" "$rest" >>"$tmp"
    else
      printf '%s %s\n' "$plugin" "${PROPOSED_BY_PLUGIN[$plugin]}" >>"$tmp"
    fi
  else
    printf '%s\n' "$line" >>"$tmp"
  fi
done

mv "$tmp" "$TOOL_VERSIONS_FILE"
trap - EXIT

echo
echo "wrote $TOOL_VERSIONS_FILE"
