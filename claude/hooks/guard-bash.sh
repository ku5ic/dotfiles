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
  log_block "${2:-unknown}" "$cmd"
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  echo "Command: $cmd" >&2
  exit 2
}

# Forces the interactive permission prompt via structured JSON output, for
# cases settings.json prefix patterns can't express (a subcommand's flagged
# and unflagged forms sharing one prefix). Unlike block(), this doesn't deny
# the call - it hands the decision back to the user, same as a settings ask
# rule, just scoped to the one case this hook can detect.
force_ask() {
  jq -cn --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

_cwd="$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)"
norm="$(printf '%s' "$cmd" | tr '\t' ' ' | tr -s ' ')"

# Full-string checks: patterns that need the complete command chain, or are
# distinctive enough that false positives from quoted arguments are not realistic.

# Fork bomb.
if [[ "$norm" =~ :\(\)[[:space:]]*\{ ]]; then
  block "fork bomb pattern" "fork-bomb"
fi

# Piping network downloads into a shell. Not per-segment because curl/wget
# and the interpreter are on opposite sides of a pipe boundary.
if [[ "$norm" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|fish|python|node|ruby|perl) ]]; then
  block "piping network content into an interpreter" "pipe-to-shell"
fi

# Writing to device nodes.
if [[ "$norm" =~ \>[[:space:]]*/dev/(sd|nvme|disk|rdisk) ]]; then
  block "write to raw disk device" "device-write"
fi

# Writes to shell rc files.
if [[ "$norm" =~ \>+[[:space:]]*(\$HOME|\$\{HOME\}|~|$HOME)/\.(zshrc|zprofile|bashrc|bash_profile|profile)([[:space:]]|$) ]]; then
  block "direct write to a shell rc file. Use the dotfiles repo." "rc-redirect"
fi

# Quote-stripped copy of the command: checks below must ignore chain
# operators and redirects that appear only inside quoted literals (e.g.
# grep '&&' or grep '2>&1' should not look like a chain or a redirect).
_cmd_sq="$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g" | sed -E 's/"[^"]*"//g')"

# xargs rm: full-string check because xargs and rm straddle a | boundary;
# the per-segment splitter does not split on |.
if [[ "$_cmd_sq" =~ xargs[[:space:]]+((-[^[:space:]]+[[:space:]]+)*)rm[[:space:]]+-[a-zA-Z]*[rRfF] ]]; then
  block "xargs rm with recursive or force flag" "xargs-rm"
fi

# 2>&1 and &> redirects are no longer blocked: the only reason they were is
# that such commands didn't match the old fine-grained permission allow-list,
# forcing a prompt. Now that the allow-list is a blanket "Bash" rule, that
# reason no longer applies.

# Returns 0 (true) when $1's side effects are read-only regardless of its
# arguments, safe to appear in a &&/||/; chain. git is deliberately excluded:
# many subcommands are read-only but others mutate, and chain-safety here is
# classified by binary name only, not subcommand.
_is_safe_chain_lead() {
  case "$1" in
  ls | cat | bat | head | tail | less | more | grep | rg | fd | find | \
    pwd | echo | printf | date | wc | sort | uniq | jq | yq | gron | qsv | \
    stat | file | tree | du | df | which | type | tokei | hyperfine | diff | \
    basename | dirname) return 0 ;;
  esac
  return 1
}

# Shell command chaining (&&, ||, ;) is allowed only when every command in
# the chain is on the read-only list above; a chain containing anything else
# still requires separate Bash tool calls. Strip structural ; uses first
# (case terminator ;; and ; before do/done/then/else/elif/fi/case/esac
# keywords) - those never count as chaining. Pipes (|) are intentionally
# unrestricted here: the segment splitter handles them and each side is
# still checked per-segment against the dangerous-pattern dispatch below.
_cmd_struct_stripped="$(printf '%s' "$_cmd_sq" | sed -E -e 's/;;/ /g' -e 's/;[[:space:]]*(do|done|then|else|elif|fi|case|esac)([^a-zA-Z0-9_]|$)/ /g')"

if [[ "$_cmd_struct_stripped" =~ \&\& ]] || [[ "$_cmd_struct_stripped" =~ \|\| ]] || [[ "$_cmd_struct_stripped" =~ \; ]]; then
  _chain_unsafe_lead=""
  # Walk segments of $_cmd_struct_stripped, not raw $norm: it is already
  # quote-stripped (so a literal && or ; inside quotes can't resurface as a
  # bogus segment) and structural ; is already blanked out (so do/done/then/
  # ... keywords can't resurface as one either).
  while IFS= read -r _chain_seg; do
    _chain_seg="${_chain_seg#"${_chain_seg%%[![:space:]]*}"}"
    [[ -z "$_chain_seg" ]] && continue
    _chain_lead="${_chain_seg%% *}"
    if ! _is_safe_chain_lead "$_chain_lead"; then
      _chain_unsafe_lead="$_chain_lead"
      break
    fi
  done < <(printf '%s\n' "$_cmd_struct_stripped" | sed -E 's/[[:space:]]*(&&|\|\|)[[:space:]]*/\n/g' | tr ';' '\n')

  if [[ -n "$_chain_unsafe_lead" ]]; then
    log_block "chain-unsafe" "$cmd"
    echo "Blocked by ${HOOK_NAME}: chain operator detected; '${_chain_unsafe_lead}' is not on the read-only safe-chain list" >&2
    echo "Run as separate Bash tool calls, or use the tool's native path/dir argument (git -C, tokei <path>, etc.)." >&2
    exit 2
  fi
fi

# _resolve_pm_for_dir <dir>: prints "manager:lockfile" for the first lockfile
# match in <dir> or its git toplevel; prints nothing when no lockfile is found.
# Hardcoded table mirrors _stacks.yml package_managers (verified by bin/doctor.sh).
# Editing here: also update _stacks.yml and run bin/doctor.sh to verify parity.
_resolve_pm_for_dir() {
  local dir="${1:-.}"
  local toplevel
  toplevel="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  local lf mgr
  while IFS=: read -r lf mgr; do
    if [[ -f "$dir/$lf" || (-n "$toplevel" && -f "$toplevel/$lf") ]]; then
      printf '%s:%s\n' "$mgr" "$lf"
      return 0
    fi
  done <<'PM_LOCKFILES'
bun.lockb:bun
bun.lock:bun
pnpm-lock.yaml:pnpm
yarn.lock:yarn
package-lock.json:npm
uv.lock:uv
poetry.lock:poetry
Pipfile.lock:pipenv
requirements.txt:pip
PM_LOCKFILES
}

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
      block "rm with recursive force against root, home, or cwd" "rm-recursive"
    fi
    ;;
  dd | shred | wipefs | mkfs | mkfs.*)
    block "low level disk or filesystem tool" "disk-tool"
    ;;
  chmod)
    if [[ "$seg" =~ chmod[[:space:]]+(-R[[:space:]]+)?777([[:space:]]|$) ]]; then
      block "chmod 777" "chmod-777"
    fi
    if [[ "$seg" =~ chmod[[:space:]] ]] && [[ "$seg" =~ \+x ]]; then
      if [[ "$seg" =~ [[:space:]](\.|\.\.|/)($|[[:space:]]) ]] ||
        [[ "$seg" =~ [[:space:]](~|\$HOME|\$\{HOME\})($|[[:space:]]|/) ]]; then
        block "broad chmod +x against root, home, or cwd" "chmod-broad-x"
      fi
    fi
    ;;
  git)
    if [[ "$seg" =~ git[[:space:]]+push[[:space:]].*(--force[^-]|--force$|-f([[:space:]]|$)) ]]; then
      if [[ ! "$seg" =~ --force-with-lease ]]; then
        block "git push --force. Use --force-with-lease if you must." "git-force-push"
      fi
    fi
    if [[ "$seg" =~ git[[:space:]]+push[[:space:]].*(main|master|develop|production|release) ]]; then
      if [[ "$seg" =~ (--force[^-]|--force$|[[:space:]]-f([[:space:]]|$)) ]]; then
        block "force push to a protected branch" "git-force-push-protected"
      fi
    fi
    # Any push (force or not) to a protected branch. Branch token must be
    # bounded by whitespace/start/end so it matches the actual ref, not a
    # substring inside a longer branch name (feat/production-config, fix/mainline).
    if [[ "$seg" =~ git[[:space:]]+push[[:space:]] ]] && [[ "$seg" =~ (^|[[:space:]])(origin/)?(main|master|develop|production|release)([[:space:]]|$) ]]; then
      block "push to a protected branch; use a feature branch" "git-push-protected"
    fi
    if [[ "$seg" =~ git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+(origin/)?(main|master|develop|production) ]]; then
      block "git reset --hard on protected branch" "git-reset-hard"
    fi
    if [[ "$seg" =~ git[[:space:]]+(commit|push|merge|rebase)[[:space:]].*--no-verify ]]; then
      block "use of --no-verify bypasses pre-commit and pre-push hooks" "git-no-verify"
    fi
    if [[ "$seg" =~ git[[:space:]]+config[[:space:]]+--global ]]; then
      block "git config --global from a project session" "git-config-global"
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
        block "destructive SQL via psql -c" "psql-destructive"
      fi
    fi
    ;;
  redis-cli)
    if [[ "$seg" =~ redis-cli[[:space:]].*(FLUSHALL|FLUSHDB|CONFIG[[:space:]]+SET|DEBUG[[:space:]]+SLEEP) ]]; then
      block "destructive redis-cli command" "redis-destructive"
    fi
    ;;
  aws)
    # ([^[:space:]]+[[:space:]]+)* skips zero or more whitespace-delimited
    # tokens (global flags like --profile prod) between the binary and the
    # service/verb, without the ambiguity a bare .* has: a bare .* can match
    # past the real "s3" token and latch onto an unrelated "s3" substring
    # inside an argument (e.g. the "s3" prefix of an s3:// URI), silently
    # defeating the check.
    if [[ "$seg" =~ aws[[:space:]]+([^[:space:]]+[[:space:]]+)*s3[[:space:]]+rm[[:space:]].*(--recursive)([[:space:]]|$) ]]; then
      block "aws s3 rm --recursive deletes an entire bucket prefix" "aws-s3-recursive-rm"
    fi
    if [[ "$seg" =~ aws[[:space:]]+([^[:space:]]+[[:space:]]+)*s3[[:space:]]+rb[[:space:]].*(--force)([[:space:]]|$) ]]; then
      block "aws s3 rb --force force-deletes a bucket and its contents" "aws-s3-force-rb"
    fi
    if [[ "$seg" =~ aws[[:space:]]+([^[:space:]]+[[:space:]]+)*ec2[[:space:]]+terminate-instances ]]; then
      block "aws ec2 terminate-instances is irreversible" "aws-ec2-terminate"
    fi
    ;;
  gcloud)
    if [[ "$seg" =~ gcloud[[:space:]]+([^[:space:]]+[[:space:]]+)*delete([[:space:]]|$) ]]; then
      block "gcloud delete operation" "gcloud-delete"
    fi
    ;;
  kubectl)
    # See the aws case above for why this skips tokens explicitly instead of
    # using a bare .* between the binary and the verb.
    if [[ "$seg" =~ kubectl[[:space:]]+([^[:space:]]+[[:space:]]+)*delete([[:space:]]|$) ]]; then
      block "kubectl delete" "kubectl-delete"
    fi
    ;;
  terraform)
    if [[ "$seg" =~ terraform[[:space:]]+([^[:space:]]+[[:space:]]+)*destroy([[:space:]]|$) ]]; then
      block "terraform destroy" "terraform-destroy"
    fi
    if [[ "$seg" =~ terraform[[:space:]]+([^[:space:]]+[[:space:]]+)*apply[[:space:]].*(-auto-approve|--auto-approve)([[:space:]]|$) ]]; then
      block "terraform apply -auto-approve skips the plan review step" "terraform-auto-approve"
    fi
    ;;
  docker)
    if [[ "$seg" =~ (system|volume|image|container|network)[[:space:]]+prune ]]; then
      # -a and -f are the only short flags these prune subcommands define, so
      # any short-option cluster containing both letters (-af, -fa) is
      # equivalent to --all --force: docker's flag parser accepts either form.
      local _has_a=0 _has_f=0
      [[ "$seg" =~ (^|[[:space:]])(-a|--all)([[:space:]]|$) || "$seg" =~ (^|[[:space:]])-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$) ]] && _has_a=1
      [[ "$seg" =~ (^|[[:space:]])(-f|--force)([[:space:]]|$) || "$seg" =~ (^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$) ]] && _has_f=1
      if ((_has_a && _has_f)); then
        block "docker prune with --all --force wipes all unused resources" "docker-prune-all-force"
      fi
    fi
    ;;
  find)
    if [[ "$seg" =~ find[[:space:]].*-delete($|[[:space:]]) ]]; then
      block "find -delete" "find-delete"
    fi
    if [[ "$seg" =~ find[[:space:]].*-exec[[:space:]]+rm([[:space:]]|$) ]]; then
      block "find -exec rm" "find-exec-rm"
    fi
    ;;
  security)
    if [[ "$seg" =~ security[[:space:]]+delete-keychain ]]; then
      block "keychain deletion" "keychain-delete"
    fi
    ;;
  npm | npx | pnpm | yarn | bun | bunx | pip | pip3 | poetry | uv | pipenv)
    # pnpm install without --frozen-lockfile can change the lockfile; force a
    # prompt. settings.json can't express "this prefix except with this flag",
    # so npm ci (no ambiguous prefix overlap) moves to allow directly, while
    # pnpm install's ask entry is removed and replaced by this hook check.
    if [[ "$lead" == "pnpm" ]]; then
      local _pnpm_rest="${seg#pnpm}"
      _pnpm_rest="${_pnpm_rest#"${_pnpm_rest%%[![:space:]]*}"}"
      if [[ "$_pnpm_rest" =~ ^(install|i)([[:space:]]|$) ]] && [[ ! "$seg" =~ (^|[[:space:]])--frozen-lockfile([[:space:]]|$) ]]; then
        force_ask "pnpm install without --frozen-lockfile can change the lockfile; confirm before running"
      fi
    fi
    # Global install guards (JS package managers only).
    if [[ "$lead" =~ ^(npm|pnpm|yarn)$ ]] && [[ "$seg" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    if [[ "$lead" == "yarn" ]] && [[ "$seg" =~ yarn[[:space:]]+global[[:space:]]+add[[:space:]] ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    if [[ "$lead" == "bun" ]] && [[ "$seg" =~ bun[[:space:]]+(add|install)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    # PM mismatch guard: block when the invoked PM differs from the lockfile-detected PM.
    # Allow --version / -v (version queries never affect project files).
    local _pm_rest
    _pm_rest="${seg#"$lead"}"
    _pm_rest="${_pm_rest#"${_pm_rest%%[![:space:]]*}"}"
    [[ "$_pm_rest" == "--version" || "$_pm_rest" == "-v" ]] && return 0
    # Canonical invoked PM (aliases: npx->npm, bunx->bun, pip3->pip).
    # Known gap: python -m pip bypasses this check (lead token is python, not pip).
    local _invoked
    case "$lead" in
    npx) _invoked="npm" ;;
    bunx) _invoked="bun" ;;
    pip3) _invoked="pip" ;;
    *) _invoked="$lead" ;;
    esac
    # Resolve expected PM from repo lockfiles; greenfield (no lockfile) always allowed.
    local _pm_info
    _pm_info="$(_resolve_pm_for_dir "${_cwd:-$PWD}")"
    [[ -z "$_pm_info" ]] && return 0
    local _expected="${_pm_info%%:*}"
    local _lf_found="${_pm_info#*:}"
    [[ "$_invoked" == "$_expected" ]] && return 0
    # Build suggested replacement command; npx/bunx get their dlx equivalents.
    local _tail="${seg#"$lead"}"
    local _suggest
    if [[ "$lead" == "npx" ]]; then
      case "$_expected" in
      bun) _suggest="bunx${_tail}" ;;
      pnpm) _suggest="pnpm dlx${_tail}" ;;
      yarn) _suggest="yarn dlx${_tail}" ;;
      *) _suggest="${_expected}${_tail}" ;;
      esac
    elif [[ "$lead" == "bunx" ]]; then
      case "$_expected" in
      npm) _suggest="npx${_tail}" ;;
      pnpm) _suggest="pnpm dlx${_tail}" ;;
      yarn) _suggest="yarn dlx${_tail}" ;;
      *) _suggest="${_expected}${_tail}" ;;
      esac
    else
      _suggest="${_expected}${_tail}"
    fi
    block "this repo uses ${_expected} (${_lf_found}); rerun as: ${_suggest}" "pm-mismatch"
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
