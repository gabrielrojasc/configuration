#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Mac Password
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔑

# Documentation:
# @raycast.author Gabriel Rojas

~/.local/bin/tidpass mac-login || exit 1
sleep 0.2
osascript -e 'tell application "System Events" to keystroke "v" using command down' || exit 1
echo "Password copied and pasted"
