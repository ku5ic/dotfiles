#!/bin/sh

EXTENSIONS=(
 "EditorConfig.EditorConfig" \
 "asvetliakov.snapshot-tools" \
 "bung87.rails" \
 "castwide.solargraph" \
 "dbaeumer.vscode-eslint" \
 "glen-84.sass-lint" \
 "mikestead.dotenv" \
 "misogi.ruby-rubocop" \
 "ms-python.python" \
 "msjsdiag.debugger-for-chrome" \
 "qinjia.seti-icons" \
 "rebornix.Ruby" \
 "robinbentley.sass-indented" \
 "streetsidesoftware.code-spell-checker" \
 "tomphilbin.gruvbox-themes" \
 "vscodevim.vim" \" \
)

 echo "Installing VS Code exstensions"
 for EXSTENSION in ${EXTENSIONS[@]}
 do
   code --install-extension $EXSTENSION
 done
