#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

# dump brew bundle
brew bundle dump --force &

# files
## Config files
cp -a ~/.zprofile . &
cp -a ~/.bash_profile . &
cp -a ~/.gitconfig . &
cp -a ~/.config/btop/btop.conf .config/btop/ &
cp -a ~/fun/.gitconfig fun/ &
cp -a ~/.screenrc . &
cp -a ~/.tmux.conf . &
cp -a ~/.vimrc . &
grep -vE '^//' ~/.npmrc >.npmrc &
cp -a ~/.zshrc . &
cp -a ~/.zsh_aliases . &
cp -a ~/.zsh_exports . &
cp -a ~/.zsh_functions . &
## colima
cp -a ~/.colima/default/colima.yaml .colima/default/ &
## docker
cp -a ~/.docker/config.json .docker/ &
## VS Code
cp -a ~/Library/Application\ Support/Code/User/settings.json Library/Application\ Support/Code/User/ &
cp -a ~/Library/Application\ Support/Code/User/keybindings.json Library/Application\ Support/Code/User/ &
## Cursor
cp -a ~/Library/Application\ Support/Cursor/User/settings.json Library/Application\ Support/Cursor/User/ &
cp -a ~/Library/Application\ Support/Cursor/User/keybindings.json Library/Application\ Support/Cursor/User/ &
cp -a ~/.cursor/mcp.json .cursor/ &
cp -a ~/.cursor/cli-config.json .cursor/ &
## Codex
(
  cp -a ~/.codex/config.toml .codex/
  config_tmp="$(mktemp .codex/config.toml.XXXXXX)"
  trap 'rm -f "$config_tmp"' EXIT
  awk '
    /^\[projects\."/ { skipping = 1; next }
    skipping && /^\[/ { skipping = 0 }
    !skipping
  ' .codex/config.toml >"$config_tmp"
  cp "$config_tmp" .codex/config.toml
) &
cp -a ~/.codex/AGENTS.md .codex/ &
## Claude
cp -a ~/.claude/settings.json .claude/ &
cp -a ~/.claude/statusline.sh .claude/ &
## utils
cp -a ~/Library/Scripts/keyboardremap Library/Scripts/keyboardremap &
cp -a ~/.gnupg/gpg-agent.conf .gnupg &

# directories
rsync --recursive --archive --delete ~/.vim . &
rsync --recursive --archive --delete ~/.config/nvim .config/ &
rsync --recursive --archive --delete ~/.config/direnv .config/ &
rsync --recursive --archive --delete ~/.config/htop .config/ &
rsync --recursive --archive --delete ~/.config/raycast/commands .config/raycast/commands &

wait
