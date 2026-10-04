# shellcheck shell=bash
# Personal machine. Sourced by utils.sh once this profile is selected.

# Put Homebrew and mise's tools (node, pnpm) on PATH, as ~/.zprofile does.
function profile_path() {
    [[ -x /opt/homebrew/bin/brew ]] || die 'Homebrew is not installed (/opt/homebrew/bin/brew). Install it first.'
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="$HOME/.local/share/mise/shims:$PATH"
}

function profile_upgrade() {
    if ! command -v mise >/dev/null; then
        color_print "$yellow" 'mise is not installed; skipped'
        record 'mise tools' fail 'skipped: mise not installed'
        return 0
    fi
    # Upgrades stay within the versions ~/.config/mise/config.toml asks for.
    # Run from ~ so a repo's mise.toml doesn't add or pin tools.
    local outdated
    outdated=$(cd "$HOME" && mise outdated --json | jq -r 'keys[]')
    if [[ -z "$outdated" ]]; then
        color_print "$green" 'mise tools are up to date'
        record 'mise tools' ok 'up to date'
    elif ((apply)); then
        (cd "$HOME" && mise upgrade)
        record 'mise tools' ok "upgraded $(echo "$outdated" | grep -c .)"
    else
        (cd "$HOME" && mise outdated)
        echo
        record 'mise tools' change "$(echo "$outdated" | grep -c .) to upgrade"
    fi
}
