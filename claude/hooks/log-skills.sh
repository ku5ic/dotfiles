#!/usr/bin/env bash
# Logs every skill / slash-command activation as a JSONL line in
# $HOME/.claude/logs/skills.jsonl. Always exits 0; this is a logger,
# not a guard. The _lib.sh ERR trap fails open on any error.
#
# Wire-up in settings.json. The two event paths cover:
#   - UserPromptExpansion: user typed /flow:preflight, /audit:debt, ...
#   - PreToolUse (matcher Skill): the model called the Skill tool itself
# A PreToolUse Skill matcher alone misses the user-typed path, which is
# why the first iteration of this hook never fired.
#
#   "UserPromptExpansion": [
#     {
#       "hooks": [
#         { "type": "command", "command": "$HOME/.claude/hooks/log-skills.sh", "timeout": 5 }
#       ]
#     }
#   ],
#   "PreToolUse": [
#     ...,
#     {
#       "matcher": "Skill",
#       "hooks": [
#         { "type": "command", "command": "$HOME/.claude/hooks/log-skills.sh", "timeout": 5 }
#       ]
#     }
#   ]

HOOK_NAME="log-skills.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

event="$(printf '%s' "$payload" | jq -r '.hook_event_name // empty')"

# Filter early. Each event path has its own irrelevant cases that should
# not pollute the log: PreToolUse fires for every tool, and
# UserPromptExpansion fires for MCP prompts as well as slash commands.
case "$event" in
  UserPromptExpansion)
    expansion_type="$(printf '%s' "$payload" | jq -r '.expansion_type // empty')"
    [[ "$expansion_type" != "slash_command" ]] && exit 0
    ;;
  PreToolUse)
    tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
    [[ "$tool_name" != "Skill" ]] && exit 0
    ;;
  *)
    exit 0
    ;;
esac

log_dir="$HOME/.claude/logs"
mkdir -p "$log_dir"

# Unified schema across both events. Fields not applicable to the
# current event come through as null, so downstream readers can use one
# jq expression regardless of source. The hook field tags which logger
# wrote each line in case more loggers are added later.
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '%s' "$payload" | jq -c \
  --arg ts "$ts" \
  --arg hook "$HOOK_NAME" \
  '{
     ts: $ts,
     hook: $hook,
     event: (.hook_event_name // null),
     session_id: (.session_id // null),
     cwd: (.cwd // null),
     expansion_type: (.expansion_type // null),
     command_name: (.command_name // null),
     command_args: (.command_args // null),
     command_source: (.command_source // null),
     tool_name: (.tool_name // null),
     tool_input: (.tool_input // null)
   }' >> "$log_dir/skills.jsonl"

exit 0
