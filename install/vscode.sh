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
  gencer.html-slim-scss-css-class-completion
  GitHub.vscode-pull-request-github
  glen-84.sass-lint
  HookyQR.beautify
  mikestead.dotenv
  misogi.ruby-rubocop
  ms-python.python
  ms-vsliveshare.vsliveshare
  ms-vsliveshare.vsliveshare-audio
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
