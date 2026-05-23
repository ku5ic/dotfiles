_apply_merge_policy() {
  _arguments \
    '(-h --help)'{-h,--help}'[Print help]' \
    '(-y --yes -n --dry-run)'{-y,--yes}'[Apply to all repos without prompting]' \
    '(-n --dry-run -y --yes)'{-n,--dry-run}'[Print current settings per repo; do nothing]'
}
