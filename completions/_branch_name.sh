_branch_name() {
  local context state line
  local -a types

  types=(
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
    'release:Release branch'
  )

  _arguments -C \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--checkout[Create and checkout the branch]' \
    '1:branch type:->type' \
    '*:branch title:_message "branch title"' && return 0

  case $state in
    type)
      _describe -t types 'branch type' types
      ;;
  esac
}
