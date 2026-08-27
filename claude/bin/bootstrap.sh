#!/usr/bin/env bash
# Idempotent symlink installer for the Claude config layout.
# Maps ~/.dotfiles/claude/{settings.json,CLAUDE.md,hooks,skills,agents,rules,bin,_stacks.yml}
# onto ~/.claude/<same>. Refuses to clobber non-symlinks unless --force, and
# never auto-removes a non-symlink directory (would destroy user data).
# Invoke with --non-interactive from install.sh; bare runs prompt on conflict.

set -euo pipefail

# pwd -P resolves the physical path so SOURCE_ROOT points at the real dotfiles
# checkout even when invoked through the symlinked ~/.claude/bin. A logical pwd
# here makes SOURCE_ROOT == ~/.claude, and the bin entry then self-symlinks (ELOOP).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
TARGET_ROOT="$HOME/.claude"

INTERACTIVE=1
FORCE=0
for arg in "$@"; do
  case "$arg" in
  --non-interactive) INTERACTIVE=0 ;;
  --force) FORCE=1 ;;
  -h | --help)
    cat <<EOF
Usage: bootstrap.sh [--non-interactive] [--force]
  --non-interactive  Do not prompt; error on any conflict. For install.sh.
  --force            Overwrite non-symlink files without prompting.
                     Never removes non-symlink directories.
EOF
    exit 0
    ;;
  *)
    echo "Unknown argument: $arg" >&2
    exit 2
    ;;
  esac
done

ENTRIES=(settings.json CLAUDE.md hooks skills agents rules bin _stacks.yml)

mkdir -p "$TARGET_ROOT"

exit_code=0

for entry in "${ENTRIES[@]}"; do
  src="$SOURCE_ROOT/$entry"
  dst="$TARGET_ROOT/$entry"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "ERROR    source missing: $src" >&2
    exit_code=1
    continue
  fi

  if [[ -L "$dst" ]]; then
    actual="$(readlink "$dst")"
    if [[ "${actual%/}" == "$src" ]]; then
      echo "ok       $dst"
      continue
    fi
    echo "wrong    $dst -> $actual (expected $src)"
    if ((FORCE == 1)); then
      ln -sfn "$src" "$dst"
      echo "fixed    $dst"
    elif ((INTERACTIVE == 1)); then
      read -r -p "Replace symlink? [y/N] " ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        ln -sfn "$src" "$dst"
        echo "fixed    $dst"
      else
        echo "skipped  $dst"
        exit_code=1
      fi
    else
      echo "ERROR    refusing to replace symlink in non-interactive mode: $dst" >&2
      exit_code=1
    fi
  elif [[ -e "$dst" ]]; then
    kind="file"
    [[ -d "$dst" ]] && kind="directory"
    echo "conflict $dst (regular $kind, expected symlink)"
    if [[ "$kind" == "directory" ]]; then
      # Never auto-remove a directory; it may hold user data not in dotfiles.
      echo "ERROR    not removing non-symlink directory; resolve manually: $dst" >&2
      exit_code=1
    elif ((FORCE == 1)); then
      rm -f "$dst"
      ln -s "$src" "$dst"
      echo "fixed    $dst"
    elif ((INTERACTIVE == 1)); then
      read -r -p "Remove file and create symlink? [y/N] " ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -f "$dst"
        ln -s "$src" "$dst"
        echo "fixed    $dst"
      else
        echo "skipped  $dst"
        exit_code=1
      fi
    else
      echo "ERROR    refusing to overwrite regular file in non-interactive mode: $dst" >&2
      exit_code=1
    fi
  else
    ln -s "$src" "$dst"
    echo "created  $dst"
  fi
done

# codebase-memory-mcp's installer/update writer can't write through
# symlinked ~/.claude/{agents,hooks,settings.json} (upstream bug: reports
# "target: does not exist or cannot be inspected"). Swap each to a real
# copy, fold whatever CBM wrote back into dotfiles, then restore the
# symlink. Shared by both the install and update paths below.
_cbm_swapped=()

_cbm_swap_dotfiles_symlinks() {
  local entries=(agents hooks settings.json)
  local entry target src
  _cbm_swapped=()

  for entry in "${entries[@]}"; do
    target="$TARGET_ROOT/$entry"
    src="$SOURCE_ROOT/$entry"
    if [[ -L "$target" ]]; then
      rm "$target"
      cp -R "$src" "$target"
      _cbm_swapped+=("$entry")
    else
      echo "skip     $target not a symlink, leaving as-is for install"
    fi
  done
}

_cbm_restore_dotfiles_symlinks() {
  local entry target src
  for entry in "${_cbm_swapped[@]}"; do
    target="$TARGET_ROOT/$entry"
    src="$SOURCE_ROOT/$entry"
    if [[ -d "$target" ]]; then
      cp -R "$target/." "$src/"
    else
      cp "$target" "$src"
    fi
    rm -rf "$target"
    ln -s "$src" "$target"
    echo "restored $target -> $src"
  done
}

# The installer/update writer refuses to overwrite a cbm-* hook file it
# doesn't recognize as its own output (e.g. one vendored from another
# machine or account, with a stale hardcoded $HOME baked into it) and
# errors out instead of just regenerating it. Clear known CBM-generated
# hook files from the swapped copy so a fresh, correct version gets
# written for this machine every time install/update actually runs.
_cbm_clear_stale_hooks() {
  local cbm_hooks=(cbm-code-discovery-gate cbm-session-reminder cbm-subagent-reminder)
  local hook
  for hook in "${cbm_hooks[@]}"; do
    rm -f "$TARGET_ROOT/hooks/$hook"
  done
}

install_codebase_memory_mcp() {
  _cbm_swap_dotfiles_symlinks
  _cbm_clear_stale_hooks

  # Restore the swapped symlinks even if the installer fails - otherwise
  # a failed run (set -e) leaves ~/.claude/{agents,hooks,settings.json}
  # stuck as real copies instead of symlinks.
  local install_failed=""
  if ! curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash; then
    install_failed=1
  fi

  _cbm_restore_dotfiles_symlinks
  [[ -z "$install_failed" ]]
}

update_codebase_memory_mcp() {
  # `codebase-memory-mcp update` doesn't self-update - it just prints
  # instructions to run a local install.sh copy the installer never
  # actually vendors alongside the binary (upstream bug, verified: the
  # file it names does not exist after a fresh install). Re-running the
  # same remote install.sh used for a fresh install IS the real update
  # path (idempotent per its own printed message), so check the latest
  # release tag first and only pay for that full reinstall when this
  # machine is actually behind.
  command -v codebase-memory-mcp >/dev/null 2>&1 || return 0

  local current latest
  current="$(codebase-memory-mcp --version 2>/dev/null | awk '{print $2}')"
  latest="$(curl -fsSL https://api.github.com/repos/DeusData/codebase-memory-mcp/releases/latest | jq -r '.tag_name' 2>/dev/null)"
  latest="${latest#v}"

  if [[ -z "$current" || -z "$latest" ]]; then
    echo "skipped  codebase-memory-mcp version check failed, leaving as-is"
    return
  fi

  if [[ "$current" == "$latest" ]]; then
    echo "ok       codebase-memory-mcp $current (up to date)"
    return
  fi

  echo "updating codebase-memory-mcp $current -> $latest"
  if install_codebase_memory_mcp; then
    echo "ok       codebase-memory-mcp updated to $latest"
  else
    echo "error    codebase-memory-mcp update failed"
  fi
}

setup_mcps() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "skipped  claude CLI not found; re-run bootstrap.sh after installing Claude Code"
    return
  fi

  if ! claude mcp get context7 >/dev/null 2>&1; then
    claude mcp add -s user context7 -- npx -y @upstash/context7-mcp
    echo "created  mcp:context7"
  else
    echo "ok       mcp:context7"
  fi

  if ! claude mcp get foxhole >/dev/null 2>&1; then
    claude mcp add -s user foxhole -- foxhole mcp
    echo "created  mcp:foxhole"
  else
    echo "ok       mcp:foxhole"
  fi

  if ! claude mcp get playwright >/dev/null 2>&1; then
    claude mcp add -s user playwright -- npx @playwright/mcp@latest
    echo "created  mcp:playwright"
  else
    echo "ok       mcp:playwright"
  fi

  if ! claude mcp get codebase-memory-mcp >/dev/null 2>&1; then
    install_codebase_memory_mcp
  else
    echo "ok       mcp:codebase-memory-mcp"
    update_codebase_memory_mcp
  fi
}

setup_mcps

exit "$exit_code"
