#!/usr/bin/env bash

set -euo pipefail

# start tmux within poetry shell
cd "/Users/gabriel/magnet/$1"
source "$(poetry env info --path)/bin/activate"
tmux new-session -d -s "$2"

# start npm and dj runserver
tmux send-keys -t "$2" "npm start" Enter
tmux split-window -hfb -t "$2"
tmux send-keys -t "$2" "drs" Enter

# attach
tmux attach -t "$2"
