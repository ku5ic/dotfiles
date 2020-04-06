#!/bin/sh

extensions=(
  asvetliakov.snapshot-tools
  bung87.vscode-gemfile
  castwide.solargraph
  codezombiech.gitignore
  dbaeumer.vscode-eslint
  EditorConfig.EditorConfig
  Equinusocio.vsc-material-theme
  equinusocio.vsc-material-theme-icons
  glen-84.sass-lint
  mikestead.dotenv
  ms-python.python
  ms-vsliveshare.vsliveshare
  msjsdiag.debugger-for-chrome
  rebornix.ruby
  streetsidesoftware.code-spell-checker
  vscodevim.vim
  wingrunr21.vscode-ruby
)

for extension in "${extensions[@]}"
do
  code --install-extension $extension
done
