#!/usr/bin/env bash
# PreToolUse hook: blocks genuinely destructive bash patterns that
# permission rules can't express reliably. exit 2 blocks (stderr is the
# reason shown to Claude); any other nonzero exit is a soft failure.

HOOK_NAME="guard-bash.sh"
# shellcheck source=../bin/_lib.sh
source "$(dirname "$0")/../bin/_lib.sh"
kit_hook_init

read_payload
require_jq

cmd="$(extract_command)"
[[ -z "$cmd" ]] && exit 0

block() {
  echo "Blocked by ${HOOK_NAME}: $1" >&2
  echo "Command: $cmd" >&2
  exit 2
}

PROTECTED_BRANCHES=(main master develop production release)

# Forces the interactive permission prompt for cases settings.json prefix
# patterns can't express (flagged/unflagged forms sharing one prefix) -
# unlike block(), hands the decision back to the user instead of denying.
# Only records the first reason: the ask is emitted after every segment has
# been checked, so a block in a later segment still wins.
pending_decision=""
force_ask() {
  [[ -n "$pending_decision" ]] || pending_decision="$1"
}

_cwd="$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)"
norm="$(printf '%s' "$cmd" | tr '\t' ' ' | tr -s ' ')"

# Full-string checks: need the complete command chain, or are distinctive
# enough that quoted-argument false positives aren't realistic.

if [[ "$norm" =~ :\(\)[[:space:]]*\{ ]]; then
  block "fork bomb pattern" "fork-bomb"
fi

# Not per-segment: curl/wget and the interpreter sit on opposite sides of |.
if [[ "$norm" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|fish|python|node|ruby|perl) ]]; then
  block "piping network content into an interpreter" "pipe-to-shell"
fi

if [[ "$norm" =~ \>[[:space:]]*/dev/(sd|nvme|disk|rdisk) ]]; then
  block "write to raw disk device" "device-write"
fi

if [[ "$norm" =~ \>+[[:space:]]*(\$HOME|\$\{HOME\}|~|$HOME)/\.(zshrc|zprofile|bashrc|bash_profile|profile)([[:space:]]|$) ]]; then
  block "direct write to a shell rc file. Use the dotfiles repo." "rc-redirect"
fi

# Quote-stripped copy: checks below must ignore chain operators/redirects
# that appear only inside quoted literals (grep '&&' or grep '2>&1' shouldn't
# look like a real chain or redirect).
_cmd_sq="$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g" | sed -E 's/"[^"]*"//g')"

# Full-string because xargs and rm straddle a | boundary; the per-segment
# splitter does not split on |.
if [[ "$_cmd_sq" =~ xargs[[:space:]]+((-[^[:space:]]+[[:space:]]+)*)rm[[:space:]]+-[a-zA-Z]*[rRfF] ]]; then
  block "xargs rm with recursive or force flag" "xargs-rm"
fi

# Resolves dir $2 (relative or ~-prefixed) against $1. Physical when it
# exists, so it compares equal to git's toplevel (macOS /var -> /private/var).
_resolve_dir() {
  local dir="${2/#\~/$HOME}"
  [[ "$dir" == /* ]] || dir="$1/$dir"
  (cd -P "$dir" 2>/dev/null && pwd) || printf '%s\n' "$dir"
}

# Directory a segment runs in: the payload cwd, moved by earlier cd segments.
_seg_cwd="$(_resolve_dir / "${_cwd:-$PWD}")"

# Prints "manager:lockfile" for the nearest lockfile of ecosystem $2, walking
# from dir $1 up to its git toplevel (only $1 outside a repo). Nothing when
# that ecosystem has no lockfile on the way: greenfield. Walks the cached
# package_managers table from bin/_lib.sh, never yq.
_nearest_pm_lockfile() {
  kit_stacks_load
  local dir="$1" eco="$2" top i
  top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  while :; do
    for ((i = 0; i < ${#STACK_PM_LOCKFILES[@]}; i++)); do
      [[ "${STACK_PM_ECOSYSTEMS[i]:-}" == "$eco" ]] || continue
      if [[ -f "$dir/${STACK_PM_LOCKFILES[i]}" ]]; then
        printf '%s:%s\n' "${STACK_PM_MANAGERS[i]}" "${STACK_PM_LOCKFILES[i]}"
        return 0
      fi
    done
    if [[ -z "$top" || "$dir" == "$top" || "$dir" == / ]]; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
}

# Returns 0 (true) when $1 names a sensitive credential/key file. Normalizes
# ~ and $HOME first. Patterns must match bin/doctor.sh's parity grep across
# guard-edit.sh, guard-bash.sh, and settings.json.
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

# Mirrors the path set in the full-string rc-file redirect guard above.
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

# Returns 0 (true) when $1 is a relative write target that would land loose in
# the repo instead of scratch (rules/tooling.md). Unresolvable
# targets - variables, subshells, quoted strings - return 1: $(scratch-dir.sh)
# is the sanctioned form and must not trip this.
_is_loose_write_target() {
  local p="$1"
  # shellcheck disable=SC2016  # matching a literal "$(" is the point here
  case "$p" in
  '' | - | \$* | *'$('* | \"* | \'*) return 1 ;;
  scratch | scratch/* | */scratch | */scratch/*) return 1 ;;
  /* | \~*) return 1 ;;
  esac
  return 0
}

# Returns 0 when ref $1 names a protected branch, ignoring refs/heads/,
# refs/remotes/<remote>/, and origin/ prefixes.
_is_protected_branch() {
  local ref="${1#refs/heads/}" branch
  [[ "$ref" == refs/remotes/*/* ]] && ref="${ref#refs/remotes/*/}"
  ref="${ref#origin/}"
  for branch in "${PROTECTED_BRANCHES[@]}"; do
    [[ "$ref" == "$branch" ]] && return 0
  done
  return 1
}

# Splits a git segment past git's global options. Sets _git_sub (the
# subcommand), _git_args (its arguments), and _git_dir (the -C value, empty
# when absent). Words split on whitespace only; quotes aren't parsed.
_git_parse() {
  local -a words
  read -ra words <<<"$1"
  _git_sub="" _git_dir="" _git_args=()
  local i=1 n=${#words[@]}
  while ((i < n)); do
    case "${words[i]}" in
    -C)
      _git_dir="${words[i + 1]:-}"
      i=$((i + 2))
      ;;
    -c | --git-dir | --work-tree | --namespace | --config-env | --super-prefix) i=$((i + 2)) ;;
    -*) i=$((i + 1)) ;;
    *) break ;;
    esac
  done
  ((i < n)) || return 0
  _git_sub="${words[i]}"
  _git_args=("${words[@]:i+1}")
}

_git_has_arg() {
  local arg
  for arg in "${_git_args[@]}"; do
    [[ "$arg" == "$1" ]] && return 0
  done
  return 1
}

# Current branch of the repo the segment targets: -C resolved against the
# payload cwd. Empty outside a repo or on a detached HEAD.
_git_current_branch() {
  local dir="${_git_dir/#\~/$HOME}"
  case "$dir" in
  '') dir="${_cwd:-$PWD}" ;;
  /*) ;;
  *) dir="${_cwd:-$PWD}/$dir" ;;
  esac
  git -C "$dir" branch --show-current 2>/dev/null || true
}

_check_git_push() {
  local arg want_value=0 opts_done=0 have_remote=0
  local -a refspecs=()
  for arg in "${_git_args[@]}"; do
    if ((want_value)); then
      want_value=0
      continue
    fi
    if ((! opts_done)); then
      case "$arg" in
      --)
        opts_done=1
        continue
        ;;
      --force) block "git push --force. Use --force-with-lease if you must." "git-force-push" ;;
      --mirror) block "git push --mirror overwrites every remote ref, protected branches included" "git-force-push" ;;
      --repo | --push-option | --receive-pack | --exec)
        want_value=1
        continue
        ;;
      --*) continue ;;
      -*)
        [[ "$arg" == *f* ]] && block "git push -f. Use --force-with-lease if you must." "git-force-push"
        [[ "$arg" == *o ]] && want_value=1
        continue
        ;;
      esac
    fi
    if ((! have_remote)); then
      have_remote=1
      continue
    fi
    refspecs+=("$arg")
  done

  local ref dst
  for ref in "${refspecs[@]}"; do
    [[ "$ref" == +* ]] && block "force push via a +refspec. Use --force-with-lease if you must." "git-force-push"
    dst="${ref##*:}"
    [[ "$dst" == HEAD ]] && dst="$(_git_current_branch)"
    if _is_protected_branch "$dst"; then
      block "push to a protected branch; use a feature branch" "git-push-protected"
    fi
  done
  if ((${#refspecs[@]} == 0)) && _is_protected_branch "$(_git_current_branch)"; then
    block "push to a protected branch; use a feature branch" "git-push-protected"
  fi
  force_ask "git push publishes commits to a remote; confirm the destination"
}

# -n is --no-verify for commit. Scans short clusters up to the first option
# that takes a value (-m, -F, -C, -c, -t): in -mn the n is the message.
_check_git_commit() {
  local arg i want_value=0
  for arg in "${_git_args[@]}"; do
    if ((want_value)); then
      want_value=0
      continue
    fi
    case "$arg" in
    --) break ;;
    --*) ;;
    -*)
      for ((i = 1; i < ${#arg}; i++)); do
        case "${arg:i:1}" in
        n) block "git commit -n bypasses pre-commit hooks, same as --no-verify" "git-no-verify" ;;
        m | F | C | c | t)
          ((i == ${#arg} - 1)) && want_value=1
          break
          ;;
        esac
      done
      ;;
    esac
  done
}

# Redirected output to a bare filename or ./name lands in cwd - the repo root,
# in a project session. Narrower than _is_loose_write_target on purpose: a
# subdir target (docs/report.md) is plausibly a deliverable, a bare one is not.
# The char class drops >&2, >(...), and /dev/* before they reach the check.
_redir_re='(^|[[:space:]])[0-9]?>>?[[:space:]]*([^[:space:]&|$"'"'"'();<>]+)'
_OVERLAY_ASK="this writes the claude-kit overlay, which can switch the kit's own guards off; confirm the change"

# True when shell word $1 (quoted, ~- or $HOME-prefixed, or relative to the
# segment's cwd) names the kit overlay. The basename test keeps the path
# resolution off every other argument.
_is_overlay_arg() {
  local arg="$1"
  arg="${arg#[\"\']}"
  arg="${arg%[\"\']}"
  [[ "$arg" == claude-kit.local.yml || "$arg" == */claude-kit.local.yml ]] || return 1
  arg="${arg/#\~/$HOME}"
  arg="${arg/#\$HOME/$HOME}"
  arg="${arg/#\$\{HOME\}/$HOME}"
  [[ "$arg" == /* ]] || arg="$_seg_cwd/$arg"
  kit_is_overlay_path "$arg"
}

_check_redirects() {
  local rest="$1" target word i
  # Every redirect target, quoted or not: the regex below skips $-prefixed
  # and quoted targets, which is fine for its own check but not this one.
  local -a words
  read -ra words <<<"$1"
  for ((i = 0; i < ${#words[@]}; i++)); do
    word="${words[i]}"
    [[ "$word" == *'>'* ]] || continue
    target="${word##*>}"
    [[ -n "$target" ]] || target="${words[i + 1]:-}"
    if _is_overlay_arg "$target"; then
      force_ask "$_OVERLAY_ASK"
    fi
  done

  while [[ "$rest" =~ $_redir_re ]]; do
    target="${BASH_REMATCH[2]}"
    rest="${rest#*"${BASH_REMATCH[0]}"}"
    if [[ "$target" != */* || "$target" == ./* ]] && _is_loose_write_target "$target"; then
      force_ask "'> ${target}' writes into the current directory; rules/tooling.md wants > \"\$(scratch-dir.sh)/${target##*/}\". Confirm only if this file belongs in the project tree."
    fi
  done
}

# Per-segment checks: split on &&, ||, ;, newlines - not | so pipe chains
# like curl|bash stay intact for the full-string check above. Each segment
# is only checked when its leading token is a known dangerous command, so
# text mentioning command names (commit bodies, grep patterns) isn't scanned.
# sudo-prefixed commands aren't unwrapped; sudo forces its own confirmation.
_check_segment() {
  local seg="$1"
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && return 0

  _check_redirects "$seg"

  # See through what only changes how the command runs: VAR=value
  # assignments and one command/env/builtin wrapper or backslash escape.
  local _assign_re='^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+'
  while [[ "$seg" =~ $_assign_re ]]; do
    seg="${seg#"${BASH_REMATCH[0]}"}"
  done
  case "${seg%% *}" in
  command | env | builtin)
    if [[ "$seg" == *' '* ]]; then
      seg="${seg#* }"
    fi
    ;;
  esac
  seg="${seg#\\}"
  while [[ "$seg" =~ $_assign_re ]]; do
    seg="${seg#"${BASH_REMATCH[0]}"}"
  done

  local lead="${seg%% *}"

  case "$lead" in
  cd)
    # Tracked so a later segment's package manager checks the right lockfile.
    local _cd_target="${seg#cd}"
    _cd_target="${_cd_target# }"
    case "$_cd_target" in
    '') _seg_cwd="$HOME" ;;
    -*) ;;
    *) _seg_cwd="$(_resolve_dir "$_seg_cwd" "${_cd_target%% *}")" ;;
    esac
    ;;
  rm)
    # Whole tokens only: rm -rf *.log and rm -rf dist/* stay allowed.
    local _rarg _rforce=0 _rbroad=0
    local -a _rwords
    read -ra _rwords <<<"${seg#rm}"
    for _rarg in "${_rwords[@]}"; do
      # shellcheck disable=SC2016,SC2088  # literal ~ and $HOME tokens are the point
      case "$_rarg" in
      --recursive | --force) _rforce=1 ;;
      --*) ;;
      -*[rRfF]*) _rforce=1 ;;
      '/' | '/*' | '~' | '~/' | '~/*' | '$HOME' | '${HOME}' | '$HOME/' | '${HOME}/' | '$HOME/*' | '${HOME}/*' | '.' | '..' | './' | '../' | '*') _rbroad=1 ;;
      esac
    done
    if ((_rforce && _rbroad)); then
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
    _git_parse "$seg"
    local _garg
    case "$_git_sub" in
    commit | push | merge | rebase)
      if _git_has_arg --no-verify; then
        block "use of --no-verify bypasses pre-commit and pre-push hooks" "git-no-verify"
      fi
      ;;
    esac
    case "$_git_sub" in
    push) _check_git_push ;;
    commit) _check_git_commit ;;
    reset)
      if _git_has_arg --hard; then
        for _garg in "${_git_args[@]}"; do
          if _is_protected_branch "$_garg"; then
            block "git reset --hard on protected branch" "git-reset-hard"
          fi
        done
      fi
      ;;
    config)
      if _git_has_arg --global; then
        block "git config --global from a project session" "git-config-global"
      fi
      ;;
    esac
    # Tree-wide pathspecs only: bare dot, double-dash-dot, :/, or bare star.
    # --staged without --worktree is allowed (unstaging isn't destructive).
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
    # ([^[:space:]]+[[:space:]]+)* skips global flags (--profile prod)
    # between binary and verb without a bare .*'s ambiguity, which could
    # latch onto an unrelated "s3" substring inside an argument (an s3://
    # URI) and silently defeat the check.
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
    # See the aws case above for why tokens are skipped explicitly.
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
      # -a/-f are the only short flags these prune subcommands define, so any
      # cluster with both letters (-af, -fa) is equivalent to --all --force.
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
    # settings.json can't express "this prefix except with this flag", so
    # pnpm install without --frozen-lockfile (which can change the lockfile)
    # forces a prompt here instead.
    if [[ "$lead" == "pnpm" ]]; then
      local _pnpm_rest="${seg#pnpm}"
      _pnpm_rest="${_pnpm_rest#"${_pnpm_rest%%[![:space:]]*}"}"
      if [[ "$_pnpm_rest" =~ ^(install|i)([[:space:]]|$) ]] && [[ ! "$seg" =~ (^|[[:space:]])--frozen-lockfile([[:space:]]|$) ]]; then
        force_ask "pnpm install without --frozen-lockfile can change the lockfile; confirm before running"
      fi
    fi
    if [[ "$lead" =~ ^(npm|pnpm|yarn)$ ]] && [[ "$seg" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    if [[ "$lead" == "yarn" ]] && [[ "$seg" =~ yarn[[:space:]]+global[[:space:]]+add[[:space:]] ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    if [[ "$lead" == "bun" ]] && [[ "$seg" =~ bun[[:space:]]+(add|install)[[:space:]]+.*(-g|--global) ]]; then
      block "global package install. Use a project-local install or asdf shim." "pkg-global-install"
    fi
    # Block when the invoked PM differs from the lockfile-detected one.
    # --version/-v is exempt (never touches project files).
    local _pm_rest
    _pm_rest="${seg#"$lead"}"
    _pm_rest="${_pm_rest#"${_pm_rest%%[![:space:]]*}"}"
    [[ "$_pm_rest" == "--version" || "$_pm_rest" == "-v" ]] && return 0
    # Canonical invoked PM (aliases: npx->npm, bunx->bun, pip3->pip).
    # Known gap: python -m pip bypasses this (lead token is python, not pip).
    local _invoked
    case "$lead" in
    npx) _invoked="npm" ;;
    bunx) _invoked="bun" ;;
    pip3) _invoked="pip" ;;
    *) _invoked="$lead" ;;
    esac
    # Only lockfiles of the invoked manager's own ecosystem count, so uv in
    # a pnpm monorepo's Python service isn't told to use pnpm.
    local _eco="" _i
    kit_stacks_load
    for ((_i = 0; _i < ${#STACK_PM_MANAGERS[@]}; _i++)); do
      if [[ "${STACK_PM_MANAGERS[_i]}" == "$_invoked" ]]; then
        _eco="${STACK_PM_ECOSYSTEMS[_i]:-}"
        break
      fi
    done
    [[ -z "$_eco" || "$_eco" == none ]] && return 0
    # The manager's own directory flag overrides the segment's cwd.
    local _pm_dir="$_seg_cwd" _pm_word _want_dir=0
    local -a _pm_words
    read -ra _pm_words <<<"$_pm_rest"
    for _pm_word in "${_pm_words[@]}"; do
      if ((_want_dir)); then
        _pm_dir="$(_resolve_dir "$_seg_cwd" "$_pm_word")"
        _want_dir=0
        continue
      fi
      case "$_invoked:$_pm_word" in
      uv:--directory | uv:--project | pnpm:--dir | pnpm:-C | yarn:--cwd | npm:--prefix) _want_dir=1 ;;
      uv:--directory=* | uv:--project=* | pnpm:--dir=* | yarn:--cwd=* | npm:--prefix=*)
        _pm_dir="$(_resolve_dir "$_seg_cwd" "${_pm_word#*=}")"
        ;;
      esac
    done
    # Greenfield (no lockfile in this ecosystem) is always allowed.
    local _pm_info
    _pm_info="$(_nearest_pm_lockfile "$_pm_dir" "$_eco")"
    [[ -z "$_pm_info" ]] && return 0
    local _expected="${_pm_info%%:*}"
    local _lf_found="${_pm_info#*:}"
    [[ "$_invoked" == "$_expected" ]] && return 0
    # npx/bunx get their dlx equivalents in the suggested replacement.
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
  curl)
    # -O/-J let the server name the file and drop it in cwd; there is no case
    # where that is intended. An explicit -o/--output-dir target still has to
    # resolve outside the repo, so a relative one gets a prompt.
    local _carg _remote=0 _want_target=0 _target=""
    for _carg in ${seg#"$lead"}; do
      if ((_want_target)); then
        _target="$_carg"
        _want_target=0
        continue
      fi
      case "$_carg" in
      --) break ;;
      --remote-name | --remote-name-all | --remote-header-name) _remote=1 ;;
      --output | --output-dir) _want_target=1 ;;
      --*) ;;
      -*)
        [[ "$_carg" == *O* || "$_carg" == *J* ]] && _remote=1
        # Only a trailing -o consumes the next word as its value.
        [[ "$_carg" == *o ]] && _want_target=1
        ;;
      esac
    done
    if ((_remote)); then
      block "curl -O/-J writes a server-named file into the current directory; use: curl -o \"\$(scratch-dir.sh)/<name>\"" "download-to-repo"
    fi
    if _is_loose_write_target "$_target"; then
      force_ask "curl would write '${_target}' into the repo; rules/tooling.md wants \$(scratch-dir.sh)/<name>. Confirm only if this file belongs in the project tree."
    fi
    ;;
  wget)
    # wget's default is to write into cwd, so an output flag is mandatory.
    # -O - is stdout; -P names a directory, -O a file. Both get path-checked.
    local _warg _want_doc=0 _want_dir=0 _doc="" _dir="" _has_out=0
    for _warg in ${seg#"$lead"}; do
      if ((_want_doc)); then
        _doc="$_warg"
        _want_doc=0
        _has_out=1
        continue
      fi
      if ((_want_dir)); then
        _dir="$_warg"
        _want_dir=0
        _has_out=1
        continue
      fi
      case "$_warg" in
      --) break ;;
      --output-document=*)
        _doc="${_warg#*=}"
        _has_out=1
        ;;
      --directory-prefix=*)
        _dir="${_warg#*=}"
        _has_out=1
        ;;
      --output-document) _want_doc=1 ;;
      --directory-prefix) _want_dir=1 ;;
      --*) ;;
      -O) _want_doc=1 ;;
      -P) _want_dir=1 ;;
      -*) ;;
      esac
    done
    if ((_has_out == 0)); then
      block "wget writes into the current directory by default; use: wget -P \"\$(scratch-dir.sh)\" <url>" "download-to-repo"
    fi
    local _wtarget="${_doc:-$_dir}"
    if _is_loose_write_target "$_wtarget"; then
      force_ask "wget would write '${_wtarget}' into the repo; rules/tooling.md wants \$(scratch-dir.sh). Confirm only if this file belongs in the project tree."
    fi
    ;;
  cat | bat | head | tail | less | more | strings)
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
    # The first non-option argument is the search pattern, not a path; skip it.
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
    # own Bash tool call, bypassing the permission allow list. Scan
    # short-option clusters only; long options like --login can't carry -c.
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
    # Catches sed -i on rc files; the full-string guard above only catches
    # > ~/.zshrc, not sed -i.
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
          if _is_overlay_arg "$_sarg"; then
            force_ask "$_OVERLAY_ASK"
          fi
          ;;
        esac
      done
    fi
    ;;
  sd)
    # Always in-place when given a file argument; no flag check needed.
    local _sarg
    for _sarg in ${seg#"$lead"}; do
      case "$_sarg" in
      --) break ;;
      -*) ;;
      *)
        if _is_rc_file "$_sarg"; then
          block "in-place edit of a shell rc file. Use the dotfiles repo." "rc-inplace-edit"
        fi
        if _is_overlay_arg "$_sarg"; then
          force_ask "$_OVERLAY_ASK"
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

# Kit scripts that only read state or create the scratch/plans directories.
# Plugins can't ship allow rules, so the hook allows them itself; settings
# deny and ask rules still win over a hook allow. run-checks.sh stays out:
# it runs project-defined scripts.
KIT_READONLY_SCRIPTS=(scratch-dir.sh plans-dir.sh git-base.sh git-diff-from-base.sh git-log-from-base.sh project-name.sh project-root.sh detect-stack.sh skills-report.sh)

# A lone kit script call: no chaining, pipes, redirects, or substitutions
# that could smuggle in a second command.
_is_kit_readonly_call() {
  local metachars=$';&|<>`\n' script
  # shellcheck disable=SC2016  # matching a literal "$(" is the point here
  [[ "$cmd" == *[$metachars]* || "$cmd" == *'$('* ]] && return 1
  for script in "${KIT_READONLY_SCRIPTS[@]}"; do
    [[ "${norm%% *}" == "$script" ]] && return 0
  done
  return 1
}

if [[ -n "$pending_decision" ]]; then
  emit_decision ask "$pending_decision"
elif _is_kit_readonly_call; then
  emit_decision allow "side-effect-free claude-kit script"
fi

exit 0
