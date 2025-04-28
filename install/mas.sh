#!/bin/sh

apps=(
1569813296  # 1Password for Safari
1616831348  # Affinity Designer 2
1616822987  # Affinity Photo 2
1482920575  # DuckDuckGo Privacy for Safari
682658836   # GarageBand
408981434   # iMovie
1458969831  # JSONPeep
409183694   # Keynote
890031187   # Marked 2
409203825   # Numbers
409201541   # Pages
1153157709  # Speedtest
497799835   # Xcode
)


# Loop through the array and install each package
for app in "${apps[@]}"
do
  mas install $app
done
