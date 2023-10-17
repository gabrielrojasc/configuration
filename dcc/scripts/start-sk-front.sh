#!/usr/bin/env sh

tmux new-session -d -s sk-front -c "/Users/gabriel/dcc/SmartKam/frontend"
tmux send-keys -t sk-front "npm run dev" Enter
tmux attach -t sk-front
