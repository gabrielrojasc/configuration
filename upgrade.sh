#!/usr/bin/env bash
# Upgrade what install.sh installed for the profile in .env (DOTFILES_PROFILE):
# Homebrew formulae and casks (then brew cleanup --prune=all), Mac App Store
# apps, the profile's toolchain (mise or proto), pnpm globals, and global
# agent skills.
#
# Usage: ./upgrade.sh [-a | --apply]
#   (no flags)   list what's outdated without upgrading (brew update still
#                refreshes Homebrew's package index)
#   -a, --apply  upgrade everything listed

set -euo pipefail
cd "$(dirname "$0")"
source ./utils.sh

apply=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a | --apply) apply=1 ;;
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
    # --apply is the confirmation, so skip Homebrew's own prompt (ask mode is its default).
    brew upgrade --greedy --no-ask
    record 'Homebrew' ok "upgraded $(count "$outdated")"
else
    brew outdated --greedy --verbose
    echo
    record 'Homebrew' change "$(count "$outdated") to upgrade"
fi

section 'Homebrew cleanup'
# --prune=all also drops cached downloads of any age, not just old versions;
# the cost is a re-download if a package is ever reinstalled.
cleanup=$(brew cleanup --prune=all --dry-run 2>&1)
freed=$(echo "$cleanup" | sed -n 's/.*would free approximately \(.*\) of disk space.*/\1/p')
# brew update writes its command-list caches again on every run, so cleanup
# always finds them; they alone don't count as something to clean.
others=$(echo "$cleanup" | grep '^Would ' | grep -v '_commands_list\.txt ' || true)
if [[ -z "$freed" || -z "$others" ]]; then
    color_print "$green" 'Nothing to clean up'
    record 'Homebrew cleanup' ok 'nothing to clean'
elif ((apply)); then
    brew cleanup --prune=all
    record 'Homebrew cleanup' ok "freed about $freed"
else
    color_print "$blue" "Would free about $freed (old versions and cached downloads)"
    record 'Homebrew cleanup' change "about $freed to free"
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
    # Run from ~ so a repo's pinned pnpm can't change the global dir. pnpm
    # outdated exits 1 when anything is outdated, so judge it by its JSON.
    json=$(cd "$HOME" && pnpm outdated -g --format json) || true
    if ! echo "$json" | jq -e 'type == "object"' >/dev/null 2>&1; then
        color_print "$yellow" 'pnpm outdated failed; skipped'
        record 'pnpm globals' fail 'skipped: pnpm outdated failed'
    elif outdated=$(echo "$json" | jq -r 'keys[]') && [[ -z "$outdated" ]]; then
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

section 'Agent skills'
if ! command -v pnpx >/dev/null; then
    color_print "$yellow" 'pnpx is not on PATH; skipped'
    record 'Agent skills' fail 'skipped: pnpx not on PATH'
else
    if ((apply)); then
        skills_cli update -g
        record 'Agent skills' ok 'updated'
    else
        # The skills CLI can't tell which skills are outdated without updating.
        installed=$(skills_cli ls -g --json 2>/dev/null | jq length)
        color_print "$blue" "$installed global skills installed; --apply updates them to their latest versions"
        record 'Agent skills' info "$installed installed; no outdated check, --apply updates"
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
