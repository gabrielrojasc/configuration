#!/usr/bin/env bash

set -euo pipefail

function print_red() {
	echo -e "\033[31m$1\033[39m"
}

# check docker is running
if (! docker version >/dev/null 2>&1); then
	print_red 'Docker is not running'
	exit 1
fi

cd
cd "/Users/gabriel/magnet/$1"

devcontainer open

# wait for containers to spin up
until [ "$(docker-compose ps -q django)" ] && [ "$(docker inspect -f \{\{.State.Running\}\} "$(docker-compose ps -q django)")" == "true" ]; do
	echo 'Waiting for containers to be running'
	sleep 3
done

# source venv/bin/activate
tmux new-session -d -s "$1"

# start npm and runserver
tmux send-keys -t "$1" "dce django zsh" Enter
tmux send-keys -t "$1" "npm run start" Enter
tmux split-window -hfb -t "$1"
tmux send-keys -t "$1" "dce django zsh" Enter
tmux send-keys -t "$1" "djs" Enter

# celery in new window
# tmux new-window -t "$1"
# tmux send-keys -t "$1" "dce celery zsh" Enter
# tmux send-keys -t "$1" "celery -A project worker --loglevel=INFO" Enter

# terminal inside container
tmux new-window -t "$1"
tmux send-keys -t "$1" "dce django zsh" Enter

# attach
tmux attach -t "$1"
