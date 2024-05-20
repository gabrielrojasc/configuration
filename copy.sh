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
rsync --recursive --archive --delete ~/.vim . &
rsync --recursive --archive --delete ~/.config/nvim .config/ &
rsync --recursive --archive --delete ~/.config/direnv .config/ &
rsync --recursive --archive --delete ~/.config/htop .config/ &

rsync --recursive --archive --delete ~/dcc/scripts dcc/ &

rsync --recursive --archive --delete ~/magnet/scripts magnet/ &

wait
