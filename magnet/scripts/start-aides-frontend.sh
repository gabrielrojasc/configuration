#!/usr/bin/env bash

set -euo pipefail

function print_red() {
	echo -e "\033[31maides-frontend\033[39m"
}

# check docker is running
if (! docker version >/dev/null 2>&1); then
	print_red 'Docker is not running'
	exit 1
fi

cd "/Users/gabriel/magnet/aides-frontend/"

# source venv/bin/activate
tmux new-session -d -s "aides-frontend"

# start npm and runserver
tmux send-keys -t "aides-frontend" "fnm use 20" Enter
tmux send-keys -t "aides-frontend" "git pull" Enter
tmux send-keys -t "aides-frontend" "npm run dev" Enter

# attach
tmux attach -t "aides-frontend"
