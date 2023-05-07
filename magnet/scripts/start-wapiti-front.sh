#!/usr/bin/env sh

tmux new-session -d -s front -c "/Users/gabriel/magnet"
# dashboard
tmux send-keys -t front "cd wapiti-dashboard" Enter
tmux send-keys -t front "npm run start" Enter

# storefront
tmux new-window -t front
tmux send-keys -t front "cd wapiti-storefront" Enter
tmux send-keys -t front "pnpm dev" Enter

# wc plugin
tmux new-window -t front
tmux send-keys -t front "cd wapiti-link" Enter

tmux attach -t front
