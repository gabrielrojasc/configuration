#!/usr/bin/env bash

set -euo pipefail

cd "/Users/gabriel/dcc/informe-memoria"

code .

tmux new-session -d -s "memoria"
tmux send-keys -t "memoria" "typst watch main.typ" Enter
tmux new-window -t "memoria"
tmux attach -t "memoria"
