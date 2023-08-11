#!/usr/bin/env sh

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

tmux new-session -d -s "aes"
# start npm and runserver
tmux send-keys -t "aes" "dce django bash" Enter
tmux send-keys -t "aes" "./manage.py runserver 0:8000" Enter
tmux split-window -hf -t "aes"
tmux send-keys -t "aes" "dce django bash" Enter
tmux send-keys -t "aes" "npm start" Enter
tmux new-window -t "aes"
tmux send-keys -t "aes" "dce celery bash" Enter
tmux send-keys -t "aes" "celery -A project worker --loglevel=INFO" Enter

# attach
tmux attach -t "aes"
