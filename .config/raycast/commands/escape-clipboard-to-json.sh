#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Escape clipboard for JSON
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📋

# Documentation:
# @raycast.author Gabriel Rojas

clipboard=$(pbpaste)
if [[ -z "$clipboard" ]]; then
  echo "Clipboard is empty"
  exit 1
fi

# Try to pretty-print as JSON; if that fails, escape raw input
if jq . >/dev/null 2>&1 <<<"$clipboard"; then
  jq . <<<"$clipboard" | pbcopy
  echo "Clipboard already escaped for JSON"
else
  jq -Rsa . <<<"$clipboard" | pbcopy
  echo "Clipboard escaped for JSON"
fi