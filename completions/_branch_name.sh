#compdef branch_name

_branch_name() {
  local -a types=(
    'feat:New feature'
    'fix:Bug fix'
    'refactor:Code restructure without behavior change'
    'perf:Performance improvement'
    'test:Add or improve tests'
    'docs:Documentation changes'
    'build:Build or dependency changes'
    'ci:CI changes'
    'chore:Maintenance task'
    'style:Formatting or style only'
  )

  if (( CURRENT == 2 )); then
    _describe 'branch type' types
    return
  fi
}
