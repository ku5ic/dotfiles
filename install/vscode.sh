#!/bin/sh

EXTENSIONS=(
 "asvetliakov.snapshot-tools" \
 "bung87.rails" \
 "bung87.vscode-gemfile" \
 "castwide.solargraph" \
 "dbaeumer.vscode-eslint" \
 "EditorConfig.EditorConfig" \
 "glen-84.sass-lint" \
 "HookyQR.beautify" \
 "mikestead.dotenv" \
 "misogi.ruby-rubocop" \
 "ms-python.python" \
 "msjsdiag.debugger-for-chrome" \
 "PKief.material-icon-theme" \
 "rebornix.ruby" \
 "robinbentley.sass-indented" \
 "streetsidesoftware.code-spell-checker" \
 "tomphilbin.gruvbox-themes" \
 "vscodevim.vim" \
)

 echo "Installing VS Code exstensions"
 for EXSTENSION in ${EXTENSIONS[@]}
 do
   code --install-extension $EXSTENSION
 done
