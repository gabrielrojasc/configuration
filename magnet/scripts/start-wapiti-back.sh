#!/usr/bin/env sh

cd /Users/gabriel/magnet/wapiti-backend
. $(poetry env info --path)/bin/activate
tmux new-session -s back
