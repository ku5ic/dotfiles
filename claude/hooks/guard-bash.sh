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

HOOK_NAME="guard-bash.sh"
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

read_payload
require_jq

cmd="$(extract_command)"
[[ -z "$cmd" ]] && exit 0

# Override _lib.sh block() to also show the offending command for context.
block() {
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  echo "Command: $cmd" >&2
  exit 2
}

norm="$(printf '%s' "$cmd" | tr '\t' ' ' | tr -s ' ')"

# Full-string checks: patterns that need the complete command chain, or are
# distinctive enough that false positives from quoted arguments are not realistic.

# Fork bomb.
if [[ "$norm" =~ :\(\)[[:space:]]*\{ ]]; then
  block "fork bomb pattern"
fi

# Piping network downloads into a shell. Not per-segment because curl/wget
# and the interpreter are on opposite sides of a pipe boundary.
if [[ "$norm" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|fish|python|node|ruby|perl) ]]; then
  block "piping network content into an interpreter"
fi

# Writing to device nodes.
if [[ "$norm" =~ \>[[:space:]]*/dev/(sd|nvme|disk|rdisk) ]]; then
  block "write to raw disk device"
fi

# Writes to shell rc files.
if [[ "$norm" =~ \>+[[:space:]]*(\$HOME|\$\{HOME\}|~|$HOME)/\.(zshrc|zprofile|bashrc|bash_profile|profile)([[:space:]]|$) ]]; then
  block "direct write to a shell rc file. Use the dotfiles repo."
fi

# 2>&1 and &> redirects: redundant in the Bash tool (stderr merged by default)
# and force permission prompts. Strip quoted content first so grep patterns that
# contain these literals as search strings (e.g. grep '2>&1') are not blocked.
_cmd_sq="$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g" | sed -E 's/"[^"]*"//g')"

# xargs rm: full-string check because xargs and rm straddle a | boundary;
# the per-segment splitter does not split on |.
if [[ "$_cmd_sq" =~ xargs[[:space:]]+((-[^[:space:]]+[[:space:]]+)*)rm[[:space:]]+-[a-zA-Z]*[rRfF] ]]; then
  block "xargs rm with recursive or force flag" "xargs-rm"
fi

if [[ "$_cmd_sq" =~ 2\>\&1 ]]; then
  echo "Blocked by guard-bash.sh: shell redirect detected (2>&1)" >&2
  echo "The Bash tool merges stderr by default. Drop the redirect and retry." >&2
  exit 2
fi
if [[ "$_cmd_sq" =~ \&\>\>? ]]; then
  echo "Blocked by guard-bash.sh: shell redirect detected (&> or &>>)" >&2
  echo "The Bash tool merges stderr by default. Drop the redirect and retry." >&2
  exit 2
fi

# Shell command chaining (&&, ||, ;) forces "ask" prompts because the
# permission allow list cannot match compound commands. CLAUDE.md bans
# this pattern; the hook enforces it. Strip quoted content first so
# patterns like grep '&&' are not flagged. Pipes (|) are intentionally
# allowed: the segment splitter handles them and they match per-segment
# against the allow list.
if [[ "$_cmd_sq" =~ \&\& ]]; then
  echo "Blocked by ${HOOK_NAME}: shell chain operator detected (&&)" >&2
  echo "Run as separate Bash tool calls, or use the tool's native path/dir argument (git -C, tokei <path>, etc.)." >&2
  exit 2
fi
if [[ "$_cmd_sq" =~ \|\| ]]; then
  echo "Blocked by ${HOOK_NAME}: shell chain operator detected (||)" >&2
  echo "Run as separate Bash tool calls." >&2
  exit 2
fi
# For ;, strip structural uses (case terminator ;; and ; before do/done/then/
# else/elif/fi/case/esac keywords) before checking. What remains is a chain
# operator. The per-segment scan below still catches dangerous commands inside
# any chain that slips through.
_cmd_struct_stripped="$(printf '%s' "$_cmd_sq" | sed -E -e 's/;;/ /g' -e 's/;[[:space:]]*(do|done|then|else|elif|fi|case|esac)([^a-zA-Z0-9_]|$)/ /g')"
if [[ "$_cmd_struct_stripped" =~ \; ]]; then
  echo "Blocked by ${HOOK_NAME}: shell chain operator detected (;)" >&2
  echo "Run as separate Bash tool calls. Control-flow ; (do, done, then, fi, ...) is allowed." >&2
  exit 2
fi

# Returns 0 (true) when $1 names a sensitive credential or key file.
# Normalizes ~ and $HOME before matching so both forms are caught.
# The literal pattern substrings below must match what bin/doctor.sh greps
# for parity across guard-edit.sh, guard-bash.sh, and settings.json.
_is_sensitive_arg() {
  local arg="$1"
  arg="${arg/#\~/$HOME}"
  arg="${arg/#\$HOME/$HOME}"
  arg="${arg/#\$\{HOME\}/$HOME}"
  local base="${arg##*/}"
  case "$base" in
  .env | .env.*) return 0 ;;
  *.pem | *.key | *.p12 | *.pfx) return 0 ;;
  id_rsa | id_ed25519 | id_ecdsa) return 0 ;;
  esac
  case "$arg" in
  "$HOME/.ssh/"*) return 0 ;;
  "$HOME/.gnupg/"*) return 0 ;;
  "$HOME/Library/Keychains/"*) return 0 ;;
  "$HOME/.aws/credentials" | "$HOME/.aws/config") return 0 ;;
  "$HOME/.docker/config.json") return 0 ;;
  "$HOME/.config/gh/hosts.yml") return 0 ;;
  "$HOME/.netrc" | "$HOME/.pgpass" | "$HOME/.npmrc") return 0 ;;
  "$HOME/.pypirc") return 0 ;;
  "$HOME/.cargo/credentials") return 0 ;;
  "$HOME/.gem/credentials") return 0 ;;
  esac
  return 1
}

# Returns 0 (true) when $1 names a shell rc file that should not be edited
# in-place. Mirrors the path set in the full-string rc-file redirect guard.
_is_rc_file() {
  local arg="$1"
  arg="${arg/#\~/$HOME}"
  arg="${arg/#\$HOME/$HOME}"
  arg="${arg/#\$\{HOME\}/$HOME}"
  case "$arg" in
  "$HOME/.zshrc" | "$HOME/.zprofile" | "$HOME/.bashrc" | "$HOME/.bash_profile" | "$HOME/.profile") return 0 ;;
  esac
  return 1
}

# Per-segment checks: split $norm on &&, ||, ;, and newlines (NOT on | so that
# pipe chains like curl|bash remain intact for the full-string check above).
# Each segment is checked only when its leading token matches a known dangerous
# command, so commit message bodies and grep patterns that mention command names
# as text are not scanned as commands.
# Limitation: sudo-prefixed commands are not unwrapped; sudo requires user
# confirmation via the permission system anyway.
_check_segment() {
  local seg="$1"
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && return 0

  local lead="${seg%% *}"

  case "$lead" in
  rm)
    if [[ "$seg" =~ rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+)+(/|/\*|~|~/|\$HOME|\$\{HOME\}|\.|\.\.)($|[[:space:]]) ]]; then
      block "rm with recursive force against root, home, or cwd"
    fi
    ;;
  dd | shred | wipefs | mkfs | mkfs.*)
    block "low level disk or filesystem tool"
    ;;
  chmod)
    if [[ "$seg" =~ chmod[[:space:]]+(-R[[:space:]]+)?777([[:space:]]|$) ]]; then
      block "chmod 777"
    fi
    if [[ "$seg" =~ chmod[[:space:]] ]] && [[ "$seg" =~ \+x ]]; then
      if [[ "$seg" =~ [[:space:]](\.|\.\.|/)($|[[:space:]]) ]] ||
        [[ "$seg" =~ [[:space:]](~|\$HOME|\$\{HOME\})($|[[:space:]]|/) ]]; then
        block "broad chmod +x against root, home, or cwd"
      fi
    fi
    ;;
  git)
    if [[ "$seg" =~ git[[:space:]]+push[[:space:]].*(--force[^-]|--force$|-f([[:space:]]|$)) ]]; then
      if [[ ! "$seg" =~ --force-with-lease ]]; then
        block "git push --force. Use --force-with-lease if you must."
      fi
    fi
    if [[ "$seg" =~ git[[:space:]]+push[[:space:]].*(main|master|develop|production|release) ]]; then
      if [[ "$seg" =~ (--force[^-]|--force$|[[:space:]]-f([[:space:]]|$)) ]]; then
        block "force push to a protected branch"
      fi
    fi
    if [[ "$seg" =~ git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+(origin/)?(main|master|develop|production) ]]; then
      block "git reset --hard on protected branch"
    fi
    if [[ "$seg" =~ git[[:space:]]+(commit|push|merge|rebase)[[:space:]].*--no-verify ]]; then
      block "use of --no-verify bypasses pre-commit and pre-push hooks"
    fi
    if [[ "$seg" =~ git[[:space:]]+config[[:space:]]+--global ]]; then
      block "git config --global from a project session"
    fi
    # Block tree-wide discard of working-tree changes. Tree-wide pathspecs:
    # bare dot, double-dash-dot, :/, or bare star. Allow --staged without
    # --worktree (unstaging is non-destructive). git -C <dir> variants work
    # because the segment splitter sees 'git' as the lead token regardless.
    if [[ "$seg" =~ [[:space:]](restore|checkout)[[:space:]] ]]; then
      if [[ "$seg" =~ [[:space:]](\.|\*|--[[:space:]]?\.|:/)([[:space:]]|$) ]]; then
        if ! [[ "$seg" =~ --staged ]] || [[ "$seg" =~ --worktree ]]; then
          block "tree-wide discard of working-tree changes; restore individual files explicitly" "git-tree-discard"
        fi
      fi
    fi
    ;;
  psql)
    if [[ "$seg" =~ psql[[:space:]].*(-c|--command)[[:space:]] ]]; then
      if [[ "$seg" =~ (DROP[[:space:]]+(DATABASE|SCHEMA|TABLE)|TRUNCATE[[:space:]]+TABLE|DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*;|DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*$) ]]; then
        block "destructive SQL via psql -c"
      fi
    fi
    ;;
  redis-cli)
    if [[ "$seg" =~ redis-cli[[:space:]].*(FLUSHALL|FLUSHDB|CONFIG[[:space:]]+SET|DEBUG[[:space:]]+SLEEP) ]]; then
      block "destructive redis-cli command"
    fi
    ;;
  find)
    if [[ "$seg" =~ find[[:space:]].*-delete($|[[:space:]]) ]]; then
      block "find -delete"
    fi
    if [[ "$seg" =~ find[[:space:]].*-exec[[:space:]]+rm([[:space:]]|$) ]]; then
      block "find -exec rm"
    fi
    ;;
  security)
    if [[ "$seg" =~ security[[:space:]]+delete-keychain ]]; then
      block "keychain deletion"
    fi
    ;;
  npm | pnpm | yarn)
    if [[ "$seg" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim."
    fi
    if [[ "$seg" =~ yarn[[:space:]]+global[[:space:]]+add[[:space:]] ]]; then
      block "global package install. Use a project-local install or asdf shim."
    fi
    ;;
  bun)
    if [[ "$seg" =~ bun[[:space:]]+(add|install)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim."
    fi
    ;;
  cat | bat | head | tail | less | more | strings)
    # Block reads of sensitive credential and key files.
    local _sarg
    for _sarg in ${seg#"$lead"}; do
      case "$_sarg" in
      --) break ;;
      -*) ;;
      *)
        if _is_sensitive_arg "$_sarg"; then
          block "reading a sensitive file is not permitted" "sensitive-read"
        fi
        ;;
      esac
    done
    ;;
  grep | rg)
    # Block when a path argument references a sensitive file. The first
    # non-option argument is the search pattern, not a path; skip it.
    local _sarg _seen_pat=0
    for _sarg in ${seg#"$lead"}; do
      case "$_sarg" in
      --) break ;;
      -*) ;;
      *)
        if ((_seen_pat == 0)); then
          _seen_pat=1
        elif _is_sensitive_arg "$_sarg"; then
          block "reading a sensitive file is not permitted" "sensitive-read"
        fi
        ;;
      esac
    done
    ;;
  sh | bash | zsh | dash)
    # -c wrapping runs an arbitrary command string that never surfaces as its
    # own Bash tool call, bypassing the permission allow list entirely.
    # Scan short-option clusters only (single dash); long options like --login
    # are not flag clusters and cannot carry -c.
    local _iarg _interp_c=0
    for _iarg in ${seg#"$lead"}; do
      case "$_iarg" in
      --) break ;;
      --*) ;;
      -*) [[ "$_iarg" == *c* ]] && _interp_c=1 ;;
      *) break ;;
      esac
    done
    if ((_interp_c)); then
      block "interpreter -c wrapping bypasses the permission allow list; run the command directly as a Bash tool call" "interpreter-c-wrap"
    fi
    ;;
  sed)
    # Block in-place edits (-i) targeting shell rc files. Complements the
    # full-string redirect guard which catches > ~/.zshrc but not sed -i.
    local _has_i=0 _sarg
    for _sarg in ${seg#"$lead"}; do
      case "$_sarg" in
      --) break ;;
      -*) [[ "$_sarg" == *i* ]] && _has_i=1 ;;
      esac
    done
    if ((_has_i)); then
      for _sarg in ${seg#"$lead"}; do
        case "$_sarg" in
        --) break ;;
        -*) ;;
        *)
          if _is_rc_file "$_sarg"; then
            block "in-place edit of a shell rc file. Use the dotfiles repo." "rc-inplace-edit"
          fi
          ;;
        esac
      done
    fi
    ;;
  sd)
    # sd is always in-place when given a file argument; no flag check needed.
    local _sarg
    for _sarg in ${seg#"$lead"}; do
      case "$_sarg" in
      --) break ;;
      -*) ;;
      *)
        if _is_rc_file "$_sarg"; then
          block "in-place edit of a shell rc file. Use the dotfiles repo." "rc-inplace-edit"
        fi
        ;;
      esac
    done
    ;;
  esac
}

while IFS= read -r _seg; do
  _check_segment "$_seg"
done < <(printf '%s\n' "$norm" | sed -E 's/[[:space:]]*(&&|\|\|)[[:space:]]*/\n/g' | tr ';' '\n')

exit 0
