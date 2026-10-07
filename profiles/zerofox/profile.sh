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
    install_keyboard_remap
    install_proto_tools
}

# Key remap: login item that runs ~/Library/Scripts/keyboardremap
function install_keyboard_remap() {
    local app_current=0 login_item=0
    if diff -rq "$profile_dir/Applications/$(basename "$keyboard_remap_app")" "$keyboard_remap_app" >/dev/null 2>&1; then
        app_current=1
    fi
    if [[ "$(osascript -e 'tell application "System Events" to exists login item "KeyboardRemap"' 2>/dev/null)" == true ]]; then
        login_item=1
    fi
    if ((app_current && login_item)); then
        color_print "$green" 'KeyboardRemap app and login item are installed'
        record 'KeyboardRemap' ok 'installed'
    elif ((apply)); then
        rsync --archive --delete "$profile_dir/Applications/$(basename "$keyboard_remap_app")" /Applications/
        if ((!login_item)); then
            osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$keyboard_remap_app\", hidden:true}" >/dev/null
        fi
        # Apply the remap now instead of waiting for the next login.
        "$HOME/Library/Scripts/keyboardremap" >/dev/null
        color_print "$green" 'Installed KeyboardRemap'
        record 'KeyboardRemap' ok 'installed'
    else
        ((app_current)) || color_print "$blue" "Would copy $keyboard_remap_app"
        ((login_item)) || color_print "$blue" 'Would add the KeyboardRemap login item'
        record 'KeyboardRemap' change 'to install'
    fi
}

# proto_tools: tool names pinned at the top of the global proto config.
function proto_tools() {
    sed -n '/^\[/q; s/^\([A-Za-z0-9_-]*\)[[:space:]]*=.*/\1/p' "$profile_dir/home/.proto/.prototools"
}

# Toolchain: node and pnpm from the global proto config. Only missing tools
# install here; newer versions come from upgrade.sh. Run from ~ so no repo pin
# applies. pnpm globals install after this, in install.sh.
function install_proto_tools() {
    local tool missing=()
    for tool in $(proto_tools); do
        (cd "$HOME" && proto bin "$tool" >/dev/null 2>&1) || missing+=("$tool")
    done
    if ((${#missing[@]} == 0)); then
        color_print "$green" 'proto tools are installed'
        record 'proto tools' ok 'installed'
    elif ((apply)); then
        (cd "$HOME" && proto install --config-mode global)
        color_print "$green" "Installed proto tools: ${missing[*]}"
        record 'proto tools' ok "installed ${#missing[@]}"
    else
        color_print "$blue" "Would install proto tools: ${missing[*]}"
        record 'proto tools' change "${#missing[@]} to install"
    fi
}

# proto_targets: "<tool> <version>" lines, the newest version in each range of
# the global config (node lts, pnpm 12). proto resolves a range to an installed
# version when one matches, even in `proto outdated`'s "newest" column, so
# resolve in an empty proto home where nothing is installed.
function proto_targets() {
    local home json status=0
    home=$(mktemp -d) || return
    # One chain, because callers run this under `if !`, where set -e is off.
    # PROTO_VERSION_CHECK=false: when a newer proto exists, proto appends its
    # upgrade notice to stdout as a second JSON value, which breaks jq.
    json=$(cp "$PROTO_HOME/.prototools" "$home/" &&
        ln -s "$PROTO_HOME/plugins" "$home/plugins" &&
        cd "$HOME" && PROTO_HOME="$home" PROTO_VERSION_CHECK=false proto outdated --config-mode global --json) || status=$?
    rm -rf "$home"
    if ((status)); then return "$status"; fi
    echo "$json" | jq -r 'to_entries[] | "\(.key) \(.value.current_version)"'
}

function profile_upgrade() {
    # Run from ~ so no repo pin applies.
    local targets tool version entry pending=()
    if ! targets=$(proto_targets); then
        color_print "$yellow" 'Could not resolve the newest proto tool versions; skipped'
        record 'proto tools' fail 'skipped: could not resolve versions'
        return 0
    fi
    while read -r tool version; do
        if [[ -z "$tool" ]]; then continue; fi
        (cd "$HOME" && proto bin "$tool" "$version" >/dev/null 2>&1 </dev/null) || pending+=("$tool $version")
    done <<<"$targets"
    if ((${#pending[@]} == 0)); then
        color_print "$green" 'proto tools are up to date'
        record 'proto tools' ok 'up to date'
    elif ((apply)); then
        for entry in "${pending[@]}"; do
            (cd "$HOME" && proto install "${entry% *}" "${entry#* }" --config-mode global)
        done
        record 'proto tools' ok "upgraded ${#pending[@]}"
    else
        color_print "$blue" 'Would install these proto tool versions:'
        printf '  %s\n' "${pending[@]}"
        echo
        record 'proto tools' change "${#pending[@]} to upgrade"
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
