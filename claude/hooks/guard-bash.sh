#!/usr/bin/env bash
# ~/.claude/hooks/guard-bash.sh
# PreToolUse hook. Reads the tool call JSON from stdin, inspects the
# proposed bash command, and blocks genuinely destructive patterns that
# permission rules cannot express reliably.
#
# Contract:
#   exit 0 -> allow the tool call
#   exit 2 -> block the tool call. stderr is shown to Claude as the reason.
# Any other non-zero exit is treated as a soft failure and does not block.
#
# TODO(phase6): full-string regex flaw -- all patterns below run against the
# entire normalized command string, including quoted arguments. This means a
# pattern like chmod[[:space:]] fires when the word "chmod" appears anywhere
# in a multi-line command, even inside a commit message body or a heredoc.
# Observed false positive: "git commit -m" with a message containing "chmod",
# "+x", and "cd ~/..." triggered the chmod guard during Phase 4 smoke tests.
# Phase 6 fix: segment the command before pattern matching. Extract the leading
# subcommand (split on &&, ||, ;, and pipe boundaries) and check each segment
# independently so that quoted string arguments are not scanned as commands.
# Tracked in: ~/.claude/scratch/followup-dotfiles-guard-bash-segmentation-*.md

set -euo pipefail
trap 'echo "guard-bash: unexpected error, failing open" >&2; exit 0' ERR

payload="$(cat)"

# Require jq. If missing, fail open rather than break the session.
if ! command -v jq >/dev/null 2>&1; then
  echo "guard-bash: jq not found, skipping checks" >&2
  exit 0
fi

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"

if [[ -z "$cmd" ]]; then
  exit 0
fi

block() {
  echo "Blocked by guard-bash.sh: $1" >&2
  echo "Command: $cmd" >&2
  exit 2
}

# Normalize whitespace for easier matching without altering the shown command.
norm="$(printf '%s' "$cmd" | tr '\t' ' ' | tr -s ' ')"

# Root and home nukes in any form.
if [[ "$norm" =~ rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+)+(/|/\*|~|~/|\$HOME|\$\{HOME\}|\.|\.\.)($|[[:space:]]) ]]; then
  block "rm with recursive force against root, home, or cwd"
fi

# Fork bomb.
if [[ "$norm" =~ :\(\)[[:space:]]*\{ ]]; then
  block "fork bomb pattern"
fi

# Disk wipers.
if [[ "$norm" =~ (^|[[:space:]])(dd|mkfs|mkfs\.[a-z0-9]+|shred|wipefs)[[:space:]] ]]; then
  block "low level disk or filesystem tool"
fi

# chmod 777 anywhere is almost never what we want.
if [[ "$norm" =~ chmod[[:space:]]+(-R[[:space:]]+)?777([[:space:]]|$) ]]; then
  block "chmod 777"
fi

# Git force push and history rewrites on protected branches.
if [[ "$norm" =~ git[[:space:]]+push[[:space:]].*(--force[^-]|--force$|[[:space:]]-f([[:space:]]|$)) ]]; then
  if [[ ! "$norm" =~ --force-with-lease ]]; then
    block "git push --force. Use --force-with-lease if you must."
  fi
fi

if [[ "$norm" =~ git[[:space:]]+push[[:space:]].*(main|master|develop|production|release) ]]; then
  # Allow normal pushes, only block force pushes to these.
  if [[ "$norm" =~ (--force[^-]|--force$|[[:space:]]-f([[:space:]]|$)) ]]; then
    block "force push to a protected branch"
  fi
fi

# Hard reset on protected branches.
if [[ "$norm" =~ git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+(origin/)?(main|master|develop|production) ]]; then
  block "git reset --hard on protected branch"
fi

# Bypassing git hooks.
if [[ "$norm" =~ git[[:space:]]+(commit|push|merge|rebase)[[:space:]].*--no-verify ]]; then
  block "use of --no-verify bypasses pre-commit and pre-push hooks"
fi

# Destructive SQL if a single-shot psql command is given.
if [[ "$norm" =~ psql[[:space:]].*(-c|--command)[[:space:]] ]]; then
  if [[ "$norm" =~ (DROP[[:space:]]+(DATABASE|SCHEMA|TABLE)|TRUNCATE[[:space:]]+TABLE|DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*;|DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*$) ]]; then
    block "destructive SQL via psql -c"
  fi
fi

# Redis catastrophes.
if [[ "$norm" =~ redis-cli[[:space:]].*(FLUSHALL|FLUSHDB|CONFIG[[:space:]]+SET|DEBUG[[:space:]]+SLEEP) ]]; then
  block "destructive redis-cli command"
fi

# Piping network downloads into a shell.
if [[ "$norm" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|fish|python|node|ruby|perl) ]]; then
  block "piping network content into an interpreter"
fi

# find with delete, and xargs rm patterns.
if [[ "$norm" =~ find[[:space:]].*-delete($|[[:space:]]) ]]; then
  block "find -delete"
fi

if [[ "$norm" =~ find[[:space:]].*-exec[[:space:]]+rm([[:space:]]|$) ]]; then
  block "find -exec rm"
fi

# Writing to device nodes.
if [[ "$norm" =~ \>[[:space:]]*/dev/(sd|nvme|disk|rdisk) ]]; then
  block "write to raw disk device"
fi

# Keychain and auth logout.
if [[ "$norm" =~ security[[:space:]]+delete-keychain ]]; then
  block "keychain deletion"
fi

# Block git config --global from a project session.
if [[ "$norm" =~ git[[:space:]]+config[[:space:]]+--global ]]; then
  block "git config --global from a project session"
fi

# Block broad chmod +x against root, home, or cwd.
if [[ "$norm" =~ chmod[[:space:]] ]] && [[ "$norm" =~ \+x ]]; then
  if [[ "$norm" =~ [[:space:]](\.|\.\.|/)($|[[:space:]]) ]] || \
     [[ "$norm" =~ [[:space:]](~|\$HOME|\$\{HOME\})($|[[:space:]]|/) ]]; then
    block "broad chmod +x against root, home, or cwd"
  fi
fi

# Block global package installs.
if [[ "$norm" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+.*(-g|--global) ]]; then
  block "global package install. Use a project-local install or asdf shim."
fi

# Block writes to shell rc files via redirection.
if [[ "$norm" =~ \>+[[:space:]]*(\$HOME|\$\{HOME\}|~|$HOME)/\.(zshrc|zprofile|bashrc|bash_profile|profile)([[:space:]]|$) ]]; then
  block "direct write to a shell rc file. Use the dotfiles repo."
fi

# Block 2>&1 and &> shell redirects. The matcher will not cover these
# with wildcard patterns (issue #13137), so they force a permission
# prompt every time. The Bash tool merges stderr by default; the
# redirect is redundant noise.
if [[ "$cmd" =~ 2\>\&1 ]]; then
  echo "Blocked by guard-bash.sh: shell redirect detected (2>&1)" >&2
  echo "The Bash tool merges stderr by default. Drop the redirect and retry." >&2
  exit 2
fi
if [[ "$cmd" =~ \&\>\>? ]]; then
  echo "Blocked by guard-bash.sh: shell redirect detected (&> or &>>)" >&2
  echo "The Bash tool merges stderr by default. Drop the redirect and retry." >&2
  exit 2
fi

exit 0
