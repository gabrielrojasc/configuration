#!/usr/bin/env bash
# Upgrade what install.sh installed for the profile in .env (DOTFILES_PROFILE):
# Homebrew formulae and casks, Mac App Store apps, the profile's toolchain
# (mise or proto), and pnpm globals.
#
# Usage: ./upgrade.sh [--apply]
#   (no flags)  list what's outdated without upgrading (brew update still
#               refreshes Homebrew's package index)
#   --apply     upgrade everything listed

set -euo pipefail
cd "$(dirname "$0")"
source ./utils.sh

apply=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) apply=1 ;;
        *) die "Unknown argument: $1 (see the usage at the top of upgrade.sh)" ;;
    esac
    shift
done

load_profile
profile_path

if ((apply)); then
    color_print "$cyan" "Upgrading profile $DOTFILES_PROFILE"
else
    color_print "$cyan" "Dry run for profile $DOTFILES_PROFILE. Nothing is upgraded until you pass --apply."
fi

# count <text>: number of non-empty lines.
function count() {
    if [[ -z "$1" ]]; then echo 0; else echo "$1" | grep -c .; fi
}

section 'Homebrew'
brew update --quiet
# --greedy includes casks that update themselves, as HOMEBREW_UPGRADE_GREEDY does in the shell.
outdated=$(brew outdated --greedy)
if [[ -z "$outdated" ]]; then
    color_print "$green" 'Homebrew packages are up to date'
    record 'Homebrew' ok 'up to date'
elif ((apply)); then
    brew upgrade --greedy
    record 'Homebrew' ok "upgraded $(count "$outdated")"
else
    brew outdated --greedy --verbose
    echo
    record 'Homebrew' change "$(count "$outdated") to upgrade"
fi

if command -v mas >/dev/null; then
    section 'Mac App Store'
    outdated=$(mas outdated)
    if [[ -z "$outdated" ]]; then
        color_print "$green" 'App Store apps are up to date'
        record 'Mac App Store' ok 'up to date'
    elif ((apply)); then
        mas upgrade
        record 'Mac App Store' ok "upgraded $(count "$outdated")"
    else
        echo "$outdated"
        echo
        record 'Mac App Store' change "$(count "$outdated") to upgrade"
    fi
fi

if declare -F profile_upgrade >/dev/null; then
    section 'Toolchain'
    profile_upgrade
fi

section 'pnpm globals'
if ! command -v pnpm >/dev/null; then
    color_print "$yellow" 'pnpm is not on PATH; skipped'
    record 'pnpm globals' fail 'skipped: pnpm not on PATH'
else
    # Run from ~ so a repo's pinned pnpm can't change the global dir.
    outdated=$(cd "$HOME" && pnpm outdated -g --format json | jq -r 'keys[]')
    if [[ -z "$outdated" ]]; then
        color_print "$green" 'pnpm globals are up to date'
        record 'pnpm globals' ok 'up to date'
    elif ((apply)); then
        (cd "$HOME" && pnpm update -g --latest)
        record 'pnpm globals' ok "upgraded $(count "$outdated")"
    else
        (cd "$HOME" && pnpm outdated -g) || true
        echo
        record 'pnpm globals' change "$(count "$outdated") to upgrade"
    fi
fi

section 'Summary'
print_summary
if ((apply)); then
    color_print "$green" 'Done.'
elif is_in change ${summary_kinds[@]+"${summary_kinds[@]}"}; then
    color_print "$cyan" 'Dry run finished. Run ./upgrade.sh --apply to upgrade these.'
else
    color_print "$green" 'Dry run finished. Everything is up to date.'
fi
