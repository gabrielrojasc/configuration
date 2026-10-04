# shellcheck shell=bash
# ZeroFox work laptop. Sourced by utils.sh once this profile is selected.

managed_dirs+=(
    home/.config/direnv
    home/.config/raycast/commands
)

# brew bundle dumps and installs `go` entries from $GOPATH/bin; match .zsh_exports
# so it works outside an interactive shell too.
export GOPATH="${GOPATH:-$HOME/zerofox/go}"

# Automator app that runs ~/Library/Scripts/keyboardremap at login.
keyboard_remap_app=/Applications/KeyboardRemap.app

# Put Workbrew and proto's tools (node, pnpm) on PATH, as the shell config does.
function profile_path() {
    # Workbrew owns /opt/homebrew on this machine; install it before running this script.
    [[ -x /opt/workbrew/bin/brew ]] || die 'Workbrew is not installed (/opt/workbrew/bin/brew). Install it first.'
    eval "$(/opt/workbrew/bin/brew shellenv)"
    export PROTO_HOME="$HOME/.proto"
    export PNPM_HOME="$HOME/Library/pnpm"
    export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH:$PNPM_HOME/bin"
}

function profile_install() {
    # Key remap: login item that runs ~/Library/Scripts/keyboardremap
    if ((apply)); then
        rsync --archive "$profile_dir/Applications/$(basename "$keyboard_remap_app")" /Applications/
        osascript -e "tell application \"System Events\" to if not (exists login item \"KeyboardRemap\") then make login item at end with properties {path:\"$keyboard_remap_app\", hidden:true}" >/dev/null
        "$HOME/Library/Scripts/keyboardremap" >/dev/null
        color_print "$green" 'Installed KeyboardRemap login item'
    else
        color_print "$blue" "Would install $keyboard_remap_app and its login item"
    fi

    # Toolchain: node and pnpm from the global proto config. Run from ~ so no
    # repo pin applies. pnpm globals install after this, in install.sh.
    if ((apply)); then
        (cd "$HOME" && proto install --config-mode global)
        color_print "$green" 'Installed proto tools'
    else
        color_print "$blue" 'Would run: proto install --config-mode global'
    fi
}

function profile_upgrade() {
    # The global config asks for ranges (node lts, pnpm 12); installing again
    # fetches the newest version in each range. Run from ~ so no repo pin applies.
    (cd "$HOME" && proto outdated --config-mode all) || true
    echo
    if ((apply)); then
        (cd "$HOME" && proto install --config-mode global)
        record 'proto tools' ok 'installed newest in range'
    else
        record 'proto tools' change 'see the table above'
    fi
}

function profile_copy() {
    # The key remap app lives outside $HOME.
    mkdir -p "$profile_dir/Applications"
    rsync --archive --delete "$keyboard_remap_app" "$profile_dir/Applications/"
}

function profile_manual_steps() {
    color_print "$yellow" 'Manual steps:
  1. Sign in to 1Password; enable its SSH agent and CLI integration (.zshrc reads secrets with `op`).
  2. Run `gh auth login`.
  3. Open a new terminal.'
}
