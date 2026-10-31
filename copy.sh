#!/usr/bin/env bash
# Bring this machine's config changes into the repo for the profile in .env.
#
# Usage: ./copy.sh [--no-sort | --sort | --resolve <path>] [--only files | --only apps]
#   (no flags)        copy, then ask for each new change who gets it:
#                     y = every profile (base), n = only this profile,
#                     q = only this profile, for this and every remaining change
#   --no-sort         copy without asking; new changes stay in this profile
#   --sort            don't copy; offer every hunk already in this profile's
#                     patches for promotion to base
#   --resolve <path>  store a fixed .conflicts/<key> file as this profile's version
#   --only files      limit to config files (skip Brewfile, pnpm globals, hooks)
#   --only apps       limit to apps.txt
#
# Changes are found by comparing $HOME with what install.sh last wrote, so
# edits from other machines that this one hasn't installed yet are kept.
# Files never installed on this machine are skipped for the same reason.

set -euo pipefail
cd "$(dirname "$0")"
source ./utils.sh

mode=copy
only=""
resolve=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-sort) mode=no-sort ;;
        --sort) mode=sort-only ;;
        --resolve) [[ $# -ge 2 ]] || die "--resolve needs a path"; mode=resolve; resolve=$2; shift ;;
        --only) [[ $# -ge 2 ]] || die "--only needs a value: files or apps"; only=$2; shift ;;
        *) die "Unknown argument: $1 (see the usage at the top of copy.sh)" ;;
    esac
    shift
done
[[ -z "$only" || "$only" == files || "$only" == apps ]] || die "--only supports: files, apps"

load_profile

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# store <key> <file>: make <file> this profile's version of <key>.
function store() {
    local key=$1 file=$2
    if [[ -f "$profile_dir/$key" || ! -f "base/$key" ]]; then
        mkdir -p "$(dirname "$profile_dir/$key")"
        cat "$file" >"$profile_dir/$key"
    else
        make_patch "$key" "$file"
    fi
}

if [[ "$mode" == resolve ]]; then
    key=$(to_key "$resolve")
    fixed="$conflicts_dir/$key"
    [[ -f "$fixed" ]] || die "No conflict file at ${fixed#"$repo"/}"
    if grep -qE '^(<<<<<<<|>>>>>>>) ' "$fixed"; then
        die "${fixed#"$repo"/} still has conflict markers"
    fi
    store "$key" "$fixed"
    # A copy conflict was between this machine and the repo; the fixed file now
    # covers both, so the machine's current version is the new common point.
    if [[ -f "$fixed.from-copy" ]]; then
        read_machine "$key" "$work/machine" && save_snapshot "$key" "$work/machine"
    fi
    rm -f "$fixed" "$fixed.from-copy"
    color_print "$green" "Stored the resolved $key for profile $DOTFILES_PROFILE"
    git --no-pager status --short -- .
    exit 0
fi

# brew bundle dump, pnpm ls, and the apps.txt cask lookup must use this
# profile's tools (Workbrew on zerofox).
if [[ "$only" != files && "$mode" != sort-only ]]; then profile_path; fi

sort_init
if [[ "$mode" == no-sort ]]; then sort_mode=keep; fi
if [[ "$mode" == sort-only ]]; then keep_unmoved_patches=1; fi
skipped=()

# Snapshots are saved only after the repo holds the change, so an abort
# (including Ctrl-C in the prompt) never marks an edit as already copied.
function defer_snapshot() {
    mkdir -p "$work/pending/$(dirname "$1")"
    cat "$2" >"$work/pending/$1"
}

function merge_apps() {
    local had="$work/apps-had" now="$work/apps-now"
    LC_ALL=C sort -u "$1" >"$now"
    LC_ALL=C sort -u "$2" >"$had"
    {
        LC_ALL=C sort -u "$3" | LC_ALL=C comm -23 - <(LC_ALL=C comm -23 "$had" "$now")
        LC_ALL=C comm -13 "$had" "$now"
    } | LC_ALL=C sort -u
}

# capture <key>: fold the machine's version of <key> into the repo.
function capture() {
    local key=$1 machine="$work/machine" repo_version="$work/repo" merged="$work/merged" snapshot
    snapshot=$(snapshot_of "$key")
    if [[ -f "$conflicts_dir/$key" ]]; then
        color_print "$yellow" "Skipped $key: resolve .conflicts/$key first (./copy.sh --resolve $key)"
        return 0
    fi
    if [[ ! -f "$snapshot" ]]; then
        skipped+=("$key")
        return 0
    fi
    read_machine "$key" "$machine" || return 0
    render "$key" "$repo_version" || return 0

    # Local edits are machine minus snapshot; replay them onto the repo version.
    if [[ "$key" == apps.txt ]]; then
        merge_apps "$machine" "$snapshot" "$repo_version" >"$merged"
    elif ! git merge-file -p -L "this machine" -L "last install" -L repo \
        "$machine" "$snapshot" "$repo_version" >"$merged"; then
        mkdir -p "$(dirname "$conflicts_dir/$key")"
        cp "$merged" "$conflicts_dir/$key"
        touch "$conflicts_dir/$key.from-copy"
        color_print "$red" "Conflict in $key: local edits overlap repo changes. Fix the markers in .conflicts/$key, then run ./copy.sh --resolve $key"
        return 0
    fi
    if cmp -s "$merged" "$repo_version"; then
        save_snapshot "$key" "$machine"
        return 0
    fi

    if [[ -f "$profile_dir/$key" ]]; then
        # Whole files owned by the profile need no sorting.
        cat "$merged" >"$profile_dir/$key"
        save_snapshot "$key" "$machine"
        copied+=("$(display_name "$key"): updated in $DOTFILES_PROFILE (only this profile has it)")
    else
        stage "$key" "$repo_version" "$merged"
        defer_snapshot "$key" "$machine"
    fi
}

# capture_new <key>: a file that appeared in a managed directory.
function capture_new() {
    local key=$1 layer
    layer=$(layer_of_dir "$key")
    read_machine "$key" "$work/new" || return 0
    if [[ "$layer" == base ]]; then
        stage_new "$key" "$work/new"
        defer_snapshot "$key" "$work/new"
    else
        mkdir -p "$(dirname "$layer/$key")"
        cat "$work/new" >"$layer/$key"
        [[ -x "$HOME/${key#home/}" ]] && chmod +x "$layer/$key"
        save_snapshot "$key" "$work/new"
        copied+=("$(display_name "$key"): new file in $DOTFILES_PROFILE")
    fi
}

if [[ "$mode" == sort-only ]]; then
    while IFS= read -r patch; do
        key=${patch#patches/}
        key=${key%.patch}
        render "$key" "$work/rendered" || continue
        [[ -e "$work/rendered" ]] || continue
        stage "$key" "base/$key" "$work/rendered"
    done < <(cd "$profile_dir" && find patches -name '*.patch' 2>/dev/null | sort)
else
    while IFS= read -r key; do
        case "$only" in
            files) [[ "$key" == home/* ]] || continue ;;
            apps) [[ "$key" == apps.txt ]] || continue ;;
        esac
        # </dev/null: brew and git must not eat the key list on stdin.
        capture "$key" </dev/null
    done < <(list_keys)
    if [[ "$only" != apps ]]; then
        while IFS= read -r key; do
            capture_new "$key" </dev/null
        done < <(list_new_keys)
    fi
    if [[ -z "$only" ]] && declare -F profile_copy >/dev/null; then profile_copy; fi
fi

if ((${#candidates[@]} + ${#new_files[@]})); then
    sort_changes
fi
place_changes


if [[ -d "$work/pending" ]]; then
    while IFS= read -r key; do
        save_snapshot "$key" "$work/pending/$key"
    done < <(cd "$work/pending" && find . -type f | sed 's#^\./##')
fi

if ((${#skipped[@]})); then
    # Only these keys were skipped; everything else above was copied.
    color_print "$yellow" "Not compared: install.sh --apply hasn't written these on this machine yet, so copy can't tell your edits from repo changes. Every other file was copied. ./install.sh -a starts tracking them:
$(printf '  %s\n' "${skipped[@]}")"
fi

section 'Copied'
if ((${#copied[@]})); then
    printf '%s\n' "${copied[@]}"
    echo
    echo 'Review with git diff, then commit.'
else
    echo 'Nothing new to copy.'
fi
