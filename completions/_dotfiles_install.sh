_dotfiles_install() {
  local -a stages

  # Read the STAGES array straight from install.sh so the list never drifts.
  stages=(${=${${"$(<"$DOTFILES_DIR/install.sh")"#*$'\nSTAGES=('}%%\)*}})
  stages=(${stages:|words})

  _describe -t stages 'install stage' stages
}

compdef _dotfiles_install install.sh
