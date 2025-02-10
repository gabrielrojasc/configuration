#!/usr/bin/env bash

set -euo pipefail

function print_red() {
	echo -e "\033[31maides-backend\033[39m"
}

# check docker is running
if (! docker version >/dev/null 2>&1); then
	print_red 'Docker is not running'
	exit 1
fi

cd "/Users/gabriel/magnet/aides-backend/"

if [ -f .env ]; then
	set -o allexport && source .env && set +o allexport
fi

devcontainer open

# wait for containers to spin up
until [ "$(docker ps -f=name=aides-backend_devcontainer-app-1 -q)" ] && [ "$(docker inspect -f \{\{.State.Running\}\} "$(docker ps -f=name=aides-backend_devcontainer-app-1 -q)")" == "true" ]; do
	echo 'Waiting for containers to be running'
	sleep 3
done

# source venv/bin/activate
tmux new-session -d -s "aides-backend"

# start npm and runserver
tmux send-keys -t "aides-backend" "docker exec -it aides-backend_devcontainer-app-1 zsh" Enter
tmux send-keys -t "aides-backend" "cd /workspace/app" Enter
tmux send-keys -t "aides-backend" 'poetry install' Enter
tmux send-keys -t "aides-backend" 'source $(poetry env info --path)/bin/activate' Enter
tmux send-keys -t "aides-backend" 'uvicorn main:app --port 8000 --reload' Enter

# terminal inside container
tmux new-window -t "aides-backend"
tmux send-keys -t "aides-backend" "docker exec -it aides-backend_devcontainer-app-1 zsh" Enter
tmux send-keys -t "aides-backend" "cd /workspace/app" Enter
tmux send-keys -t "aides-backend" 'export PYTHONPATH=$PWD' Enter
tmux send-keys -t "aides-backend" 'sleep 3' Enter
tmux send-keys -t "aides-backend" 'source $(poetry env info --path)/bin/activate' Enter

# attach
tmux attach -t "aides-backend"
