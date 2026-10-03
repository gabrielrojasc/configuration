# shellcheck shell=bash

# Format helpers for color_print
green="\033[0;32m"
blue="\033[0;34m"
cyan="\033[0;36m"
yellow="\033[0;33m"
red="\033[0;31m"
default="\033[0m"

function color_print() {
	local color=$1
	local message=$2

	echo -e "${color}${message}${default}\n"
}

# brew bundle dumps and installs `go` entries from $GOPATH/bin; match .zsh_exports
# so it works outside an interactive shell too.
export GOPATH="${GOPATH:-$HOME/zerofox/go}"

# Paths relative to $HOME that copy.sh saves and install.sh restores as-is.
# Files that need filtering or merging are handled explicitly in each script.
config_files=(
    .bash_profile
    .gitconfig
    .screenrc
    .tmux.conf
    .vimrc
    .zprofile
    .zshrc
    .zsh_aliases
    .zsh_exports
    .zsh_functions
    fun/.gitconfig
    .config/btop/btop.conf
    .colima/default/colima.yaml
    .docker/config.json
    .gnupg/gpg-agent.conf
    .proto/.prototools
    .codex/AGENTS.md
    .claude/CLAUDE.md
    .claude/settings.json
    .claude/statusline.sh
    "Library/Application Support/Code/User/keybindings.json"
    "Library/Application Support/Code/User/settings.json"
    Library/Scripts/keyboardremap
)

# Directories relative to $HOME, mirrored with rsync.
config_dirs=(
    .vim
    .config/direnv
    .config/nvim
    .config/raycast/commands
    .codex/agents
    .claude/agents
)

# Automator app that runs Library/Scripts/keyboardremap at login.
keyboard_remap_app=/Applications/KeyboardRemap.app

# Wait for every background job and fail if any of them failed.
function wait_all() {
    local failed=0 pid
    for pid in $(jobs -p); do
        wait "$pid" || failed=1
    done
    return "$failed"
}
