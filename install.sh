#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"
repo="$PWD"
source ./utils.sh

# Workbrew owns /opt/homebrew on this machine; install it before running this script.
if [[ ! -x /opt/workbrew/bin/brew ]]; then
    color_print "$red" 'Workbrew is not installed (/opt/workbrew/bin/brew). Install it first.'
    exit 1
fi
eval "$(/opt/workbrew/bin/brew shellenv)"

# Touch ID for sudo
if grep -qs '^auth.*pam_tid\.so' /etc/pam.d/sudo_local; then
    color_print "$blue" 'Touch ID for sudo commands is already configured.'
else
    sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
    color_print "$green" 'Configured Touch ID to allow sudo commands'
fi

# Packages. Some entries (e.g. vscode extensions without the `code` CLI) can fail
# on a fresh machine; report and keep going.
if brew bundle install --file=Brewfile; then
    color_print "$green" 'Installed Brewfile packages'
else
    color_print "$yellow" 'Some Brewfile entries failed; see the output above'
fi

# Config files. Anything that would be overwritten is backed up first.
backup="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
function prepare() {
    local path=$1
    if [[ -e "$HOME/$path" ]]; then
        mkdir -p "$backup/$(dirname "$path")"
        cp -a "$HOME/$path" "$backup/$path"
    fi
    mkdir -p "$HOME/$(dirname "$path")"
}

# gpg rejects a ~/.gnupg readable by others
mkdir -p -m 700 "$HOME/.gnupg"

for path in "${config_files[@]}"; do
    prepare "$path"
    cp -a "$path" "$HOME/$path"
done
# No --delete: keep files the repo ignores (e.g. nvim's lazy-lock.json).
for path in "${config_dirs[@]}"; do
    prepare "$path"
    rsync --archive "$path/" "$HOME/$path/"
done

## npm: the repo copy has no auth lines; keep the ones already in ~/.npmrc
prepare .npmrc
{
    cat .npmrc
    grep -E '^//' "$HOME/.npmrc" 2>/dev/null || true
} >"$HOME/.npmrc.tmp"
mv "$HOME/.npmrc.tmp" "$HOME/.npmrc"

## Codex: the repo copy omits projects and MCP servers, so only seed a missing config
if [[ -e "$HOME/.codex/config.toml" ]]; then
    color_print "$yellow" 'Kept existing ~/.codex/config.toml; merge .codex/config.toml by hand if needed'
else
    cp -a .codex/config.toml "$HOME/.codex/config.toml"
fi

if [[ -d "$backup" ]]; then
    color_print "$green" "Restored config files (previous versions in $backup)"
else
    color_print "$green" 'Restored config files'
fi

# Key remap: Automator app that runs ~/Library/Scripts/keyboardremap at login
rsync --archive "Applications/$(basename "$keyboard_remap_app")" /Applications/
osascript -e "tell application \"System Events\" to if not (exists login item \"KeyboardRemap\") then make login item at end with properties {path:\"$keyboard_remap_app\", hidden:true}" >/dev/null
"$HOME/Library/Scripts/keyboardremap" >/dev/null
color_print "$green" 'Installed KeyboardRemap login item'

# Terminal profile (manual snapshot; opening it imports the profile and opens a window)
open Basic.terminal
defaults write com.apple.Terminal "Default Window Settings" -string Basic
defaults write com.apple.Terminal "Startup Window Settings" -string Basic
color_print "$green" 'Imported Basic Terminal profile'

# Toolchain: node and pnpm from the global proto config, then pnpm global CLIs.
# Run from ~ so no repo pin applies.
export PROTO_HOME="$HOME/.proto"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH:$PNPM_HOME/bin"
(cd "$HOME" && proto install --config-mode global)
(cd "$HOME" && xargs pnpm add -g <"$repo/pnpm-globals.txt")
color_print "$green" 'Installed proto tools and pnpm globals'

./set_defaults.sh
color_print "$green" 'Defaults from "set_defaults.sh" were set'

color_print "$yellow" 'Manual steps:
  1. Sign in to 1Password; enable its SSH agent and CLI integration (.zshrc reads secrets with `op`).
  2. Run `gh auth login`.
  3. Open a new terminal.'
