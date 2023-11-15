#!/usr/bin/env sh

cd /Users/gabriel/dcc/SmartKam/backend
source "$(poetry env info --path)/bin/activate"
tmux new-session -d -s sk-back
tmux send-keys -t sk-back "drs" Enter
tmux attach -t sk-back
