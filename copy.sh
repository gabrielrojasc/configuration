#!/usr/bin/env bash
# Bring this machine's config changes into the repo for the profile in .env.
#
# Usage: ./copy.sh [--no-sort | --sort | --resolve <path>] [--only files]
#   (no flags)        copy, then ask hunk by hunk where each new change belongs:
#                     y = base (every profile), n = this profile
#   --no-sort         copy without asking; new changes stay in this profile
#   --sort            don't copy; offer every hunk already in this profile's
#                     patches for promotion to base
#   --resolve <path>  store a fixed .conflicts/<key> file as this profile's version
#   --only files      limit to config files (skip Brewfile, pnpm globals, hooks)
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
        --only) [[ $# -ge 2 ]] || die "--only needs a value: files"; only=$2; shift ;;
        *) die "Unknown argument: $1 (see the usage at the top of copy.sh)" ;;
    esac
    shift
done
[[ -z "$only" || "$only" == files ]] || die "--only supports: files"

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

# brew bundle dump and pnpm ls must use this profile's tools (Workbrew on zerofox).
if [[ -z "$only" && "$mode" != sort-only ]]; then profile_path; fi

# Scratch repo whose index holds the repo version of each changed file and
# whose worktree holds the machine version; `git add -p` sorts the hunks.
sort_repo="$work/sort"
git init -q "$sort_repo"
candidates=()
new_files=()
skipped=()

# stage <key> <index version> <worktree version>
function stage() {
    local key=$1
    mkdir -p "$sort_repo/$(dirname "$key")" "$work/candidates/$(dirname "$key")"
    cat "$2" >"$sort_repo/$key"
    git -C "$sort_repo" add -- "$key"
    cat "$3" >"$sort_repo/$key"
    cat "$2" >"$work/candidates/$key"
    candidates+=("$key")
}

# Snapshots are saved only after the repo holds the change, so an abort
# (including Ctrl-C in the prompt) never marks an edit as already copied.
function defer_snapshot() {
    mkdir -p "$work/pending/$(dirname "$1")"
    cat "$2" >"$work/pending/$1"
}

# capture <key>: fold the machine's version of <key> into the repo.
function capture() {
    local key=$1 machine="$work/machine" repo_version="$work/repo" merged="$work/merged" snapshot
    snapshot="$snapshot_dir/$key"
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
    if ! git merge-file -p -L "this machine" -L "last install" -L repo \
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
        # Offered as one all-new hunk: y puts it in base, n in this profile.
        mkdir -p "$sort_repo/$(dirname "$key")"
        cat "$work/new" >"$sort_repo/$key"
        git -C "$sort_repo" add -N -- "$key"
        new_files+=("$key")
        defer_snapshot "$key" "$work/new"
    else
        mkdir -p "$(dirname "$layer/$key")"
        cat "$work/new" >"$layer/$key"
        [[ -x "$HOME/${key#home/}" ]] && chmod +x "$layer/$key"
        save_snapshot "$key" "$work/new"
        color_print "$green" "New file: $layer/$key"
    fi
}

if [[ "$mode" == sort-only ]]; then
    while IFS= read -r patch; do
        key=${patch#patches/}
        key=${key%.patch}
        render "$key" "$work/rendered" || continue
        stage "$key" "base/$key" "$work/rendered"
    done < <(cd "$profile_dir" && find patches -name '*.patch' 2>/dev/null | sort)
else
    while IFS= read -r key; do
        [[ -n "$only" && "$key" != home/* ]] && continue
        # </dev/null: brew and git must not eat the key list on stdin.
        capture "$key" </dev/null
    done < <(list_keys)
    while IFS= read -r key; do
        capture_new "$key" </dev/null
    done < <(list_new_keys)
    if [[ -z "$only" ]] && declare -F profile_copy >/dev/null; then profile_copy; fi
fi

if ((${#candidates[@]} + ${#new_files[@]})) && [[ "$mode" != no-sort ]]; then
    color_print "$cyan" 'Sort each change: y = base (every profile), n = keep in this profile, q = keep the rest here'
    git -C "$sort_repo" add -p || true
fi

for key in ${candidates[@]+"${candidates[@]}"}; do
    # Staged hunks are the ones promoted to base; carry them onto base
    # (which may differ from the index version by this profile's patch).
    git -C "$sort_repo" show ":$key" >"$work/staged"
    if ! cmp -s "$work/staged" "$work/candidates/$key"; then
        if git merge-file -p "base/$key" "$work/candidates/$key" "$work/staged" >"$work/new-base"; then
            cat "$work/new-base" >"base/$key"
        else
            # Happens when a promoted hunk sits right next to lines only this
            # profile has, so there's no base context to place it in.
            color_print "$yellow" "Kept the chosen $key hunks in this profile: they sit next to profile-only lines. Move them into base/$key by hand, then rerun ./copy.sh --sort."
        fi
    fi
    make_patch "$key" "$sort_repo/$key"
done

for key in ${new_files[@]+"${new_files[@]}"}; do
    git -C "$sort_repo" show ":$key" >"$work/staged"
    if [[ -s "$work/staged" ]]; then
        cat "$work/staged" >"base/$key"
        [[ -x "$HOME/${key#home/}" ]] && chmod +x "base/$key"
        make_patch "$key" "$sort_repo/$key"
        color_print "$green" "New file: base/$key"
    else
        mkdir -p "$(dirname "$profile_dir/$key")"
        cat "$sort_repo/$key" >"$profile_dir/$key"
        [[ -x "$HOME/${key#home/}" ]] && chmod +x "$profile_dir/$key"
        color_print "$green" "New file: $profile_dir/$key"
    fi
done

if [[ -d "$work/pending" ]]; then
    while IFS= read -r key; do
        save_snapshot "$key" "$work/pending/$key"
    done < <(cd "$work/pending" && find . -type f | sed 's#^\./##')
fi

if ((${#skipped[@]})); then
    color_print "$yellow" "Skipped ${#skipped[@]} files never installed on this machine (run ./install.sh --apply first, so copy can tell local edits from repo changes):
$(printf '  %s\n' "${skipped[@]}")"
fi

git --no-pager status --short -- .
