#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

# dump brew bundle
brew bundle dump --force &

# files
cp ~/.zprofile . &
cp ~/.bash_profile . &
cp ~/.gitconfig . &
cp ~/.screenrc . &
cp ~/.tmux.conf . &
cp ~/.vimrc . &
cp ~/.zshrc . &
cp ~/.zsh_aliases . &
cp ~/.zsh_exports . &
cp ~/Library/Application\ Support/Code/User/settings.json Library/Application\ Support/Code/User/ &
cp ~/Library/Application\ Support/Code/User/keybindings.json Library/Application\ Support/Code/User/ &

cp ~/dcc/justfile dcc/ &

cp ~/magnet/.gitconfig magnet/ &
cp ~/magnet/justfile magnet/ &

# directories
rsync --recursive --archive --delete-after ~/.vim . &
rsync --recursive --archive --delete-after ~/.config/nvim .config/ &
rsync --recursive --archive --delete-after ~/.config/direnv .config/ &
rsync --recursive --archive --delete-after ~/.config/htop .config/ &

rsync --recursive --archive --delete-after ~/dcc/scripts dcc/ &

rsync --recursive --archive --delete-after ~/magnet/scripts magnet/ &

wait
