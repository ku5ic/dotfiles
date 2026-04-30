_asdf_update_tool_versions() {
  local context state line

  _arguments -C \
    '(-h --help)'{-h,--help}'[Show help]' \
    '(-w --write -i --install)'{-w,--write}'[Rewrite .tool-versions in place]' \
    '(-w --write -i --install)'{-i,--install}'[Run asdf install for new versions then write]' \
    '*:tool-versions file:_files' && return 0
}
