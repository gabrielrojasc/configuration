#!/usr/bin/env bash

set -euo pipefail

# check docker is running
if (! docker version >/dev/null 2>&1); then
	echo 'Docker is not running'
	exit 1
fi

cd "/Users/gabriel/magnet/aes-essprim"

devcontainer open

# wait for containers to spin up
until [ "$(docker inspect -f {{.State.Running}} aes-essprim-django)" == "true" ]; do
	echo 'Waiting for containers to be running'
	sleep 1
done

# source venv/bin/activate
tmux new-session -d -s "aes"

# start npm and runserver
tmux send-keys -t "aes" "dce django bash" Enter
tmux send-keys -t "aes" "npm start" Enter
tmux split-window -hfb -t "aes"
tmux send-keys -t "aes" "dce django bash" Enter
tmux send-keys -t "aes" "./manage.py runserver 0:8000" Enter

# celery in new window
tmux new-window -t "aes"
tmux send-keys -t "aes" "dce celery bash" Enter
tmux send-keys -t "aes" "watchmedo auto-restart --directory=./ --pattern=*.py --recursive -- celery -A project worker --loglevel=INFO" Enter

# attach
tmux attach -t "aes"
