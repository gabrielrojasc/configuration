# shellcheck shell=bash
# Personal machine. Sourced by utils.sh once this profile is selected.

function profile_brew() {
    [[ -x /opt/homebrew/bin/brew ]] || die 'Homebrew is not installed (/opt/homebrew/bin/brew). Install it first.'
    eval "$(/opt/homebrew/bin/brew shellenv)"
}
