#!/bin/sh

extensions=(
  asvetliakov.snapshot-tools
  bigonesystems.django
  bung87.rails
  bung87.vscode-gemfile
  castwide.solargraph
  codezombiech.gitignore
  dbaeumer.vscode-eslint
  EditorConfig.EditorConfig
  Equinusocio.vsc-material-theme
  GitHub.vscode-pull-request-github
  glen-84.sass-lint
  HookyQR.beautify
  Hridoy.rails-snippets
  mikestead.dotenv
  ms-python.python
  ms-vsliveshare.vsliveshare
  msjsdiag.debugger-for-chrome
  PKief.material-icon-theme
  rebornix.ruby
  robinbentley.sass-indented
  sianglim.slim
  streetsidesoftware.code-spell-checker
  vscodevim.vim
  wholroyd.jinja
)

for extension in "${extensions[@]}"
do
  code --install-extension --force $extension
done
