#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy ZF STAG Bearer token
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🦊

# Documentation:
# @raycast.author Gabriel Rojas

source $HOME/.zsh_functions
token=$(get-zf-token stag)

echo "Bearer ${token}" | pbcopy
unset token

echo "Token copied to clipboard"
