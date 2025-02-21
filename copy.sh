#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

# dump brew bundle
brew bundle dump --force &

# files
cp -a ~/.zprofile . &
cp -a ~/.bash_profile . &
cp -a ~/.gitconfig . &
cp -a ~/.screenrc . &
cp -a ~/.tmux.conf . &
cp -a ~/.vimrc . &
cp -a ~/.zshrc . &
cp -a ~/.zsh_aliases . &
cp -a ~/.zsh_exports . &
cp -a ~/Library/Application\ Support/Code/User/settings.json Library/Application\ Support/Code/User/ &
cp -a ~/Library/Application\ Support/Code/User/keybindings.json Library/Application\ Support/Code/User/ &
cp -a ~/Library/Scripts/keyboardremap Library/Scripts/keyboardremap &
cp -a ~/.gnupg/gpg-agent.conf .gnupg &

# directories
rsync --recursive --archive --delete ~/.vim . &
rsync --recursive --archive --delete ~/.config/nvim .config/ &
rsync --recursive --archive --delete ~/.config/direnv .config/ &
rsync --recursive --archive --delete ~/.config/htop .config/ &

wait
