#!/usr/bin/env bash
# Appends one JSONL line per skill activation to $HOME/.claude/logs/skills.jsonl.
# Covers three paths:
#
#   UserPromptExpansion  - user typed /skillname or /command:name directly
#   PreToolUse Skill     - Claude invoked the Skill tool; payload field is
#                          tool_input.skill (e.g. {"skill": "react-patterns"})
#   PostToolUse Read     - fallback: direct SKILL.md reads (rare)
#
# Wire-up in settings.json:
#
#   "UserPromptExpansion": [
#     { "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/log-skills.sh", "timeout": 5 }] }
#   ]
#
#   "PreToolUse": [
#     {
#       "matcher": "Skill",
#       "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/log-skills.sh", "timeout": 5 }]
#     },
#     ... existing Bash and Edit|Write|MultiEdit entries ...
#   ]
#
#   "PostToolUse": [
#     {
#       "matcher": "Read",
#       "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/log-skills.sh", "timeout": 5 }]
#     },
#     ... existing Edit|Write|MultiEdit entry ...
#   ]

HOOK_NAME="log-skills.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=""
read_payload
require_jq

event="$(printf '%s' "$payload" | jq -r '.hook_event_name // empty')"

case "$event" in
  UserPromptExpansion)
    expansion_type="$(printf '%s' "$payload" | jq -r '.expansion_type // empty')"
    [[ "$expansion_type" != "slash_command" ]] && exit 0
    ;;

  PreToolUse)
    tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
    [[ "$tool_name" != "Skill" ]] && exit 0
    ;;

  PostToolUse)
    tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
    if [[ "$tool_name" == "Skill" ]]; then
      : # always log
    elif [[ "$tool_name" == "Read" ]]; then
      file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
      [[ "$file_path" == *"/skills/"*"/SKILL.md" ]] || exit 0
    else
      exit 0
    fi
    ;;

  *)
    exit 0
    ;;
esac

log_dir="$HOME/.claude/logs"
mkdir -p "$log_dir"

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
     skill_file: (.tool_input.skill // .tool_input.file_path // null),
     tool_name: (.tool_name // null)
   }' >> "$log_dir/skills.jsonl"

exit 0
