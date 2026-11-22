#!/usr/bin/env bash
# Compose each Grok Bot's description for the profile in .env
# (DOTFILES_PROFILE) from its description.txt and the sections that file
# includes, and build the bundle a box checks its bots against.
# bots/README.md describes the files and the flow.
#
# Usage: bots/descriptions.sh <slug>
#        bots/descriptions.sh --sources <slug>
#        bots/descriptions.sh --stage <empty-folder>
#   <slug>      print the description the profile's bot should have
#   --sources   list the files that description is composed from, in order
#   --stage     write the description of every bot in the profile's bots.txt,
#               a manifest of their sha256, and the check a box runs; any
#               failure writes nothing

set -euo pipefail
start_dir=$PWD
cd "$(dirname "$0")/.."
source ./utils.sh

usage="Usage: bots/descriptions.sh <slug> | --sources <slug> | --stage <empty-folder>"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

function composed() {
    local slug=$1 out=$2 key
    key=$(description_key "$slug")
    [[ -n "$(source_of "$key")" ]] || die "$key is not managed by profile $DOTFILES_PROFILE"
    compose "$key" "$out" || die "$key doesn't compose for profile $DOTFILES_PROFILE"
}

function sources() {
    local key patch
    include_log="$work/keys"
    : >"$include_log"
    composed "$1" "$work/description"
    while IFS= read -r key; do
        patch=$(patch_of "$key")
        if [[ "$(source_of "$key")" == base/* && -f "$patch" ]]; then
            echo "base/$key + $patch"
        else
            source_of "$key"
        fi
    done <"$include_log"
}

function stage() {
    local staging root bundle="$work/bundle" roster="$profile_dir/bots.txt" slug id count=0
    staging=$(cd "$start_dir" && cd "$1" 2>/dev/null && pwd -P) || die "Staging folder not found: $1"
    root=$(pwd -P)
    if [[ "$staging" == "$root" || "$staging" == "$root"/* ]]; then
        die "Stage outside the repo, for example in mktemp -d: $staging is inside $root"
    fi
    [[ -z "$(ls -A "$staging")" ]] || die "$staging isn't empty"
    [[ -f "$roster" ]] || die "Profile $DOTFILES_PROFILE has no Grok Bot fleet: $roster is missing. See bots/README.md."

    mkdir -p "$bundle"
    while read -r slug id || [[ -n "$slug" ]]; do
        if [[ -z "$slug" ]]; then continue; fi
        composed "$slug" "$bundle/$slug.txt" </dev/null
        [[ -s "$bundle/$slug.txt" ]] || die "$(description_key "$slug") composes to nothing"
        if grep -qF '<machine-id>' "$bundle/$slug.txt"; then
            die "$slug's description holds <machine-id>, and a bot can't take the placeholder. Name machines in routines instead."
        fi
        echo "$slug $id $(stored_sha256 "$bundle/$slug.txt")" >>"$bundle/descriptions.txt"
        count=$((count + 1))
    done <"$roster"
    ((count > 0)) || die "$roster lists no bots"
    cp bots/check-descriptions.py "$bundle/"
    cp -R "$bundle/." "$staging/"
    color_print "$green" "Composed $count descriptions for profile $DOTFILES_PROFILE in $staging"
}

# A bot stores its description without the file's final newline.
function stored_sha256() {
    printf '%s' "$(cat "$1")" | shasum -a 256 | awk '{ print $1 }'
}

case "${1:-}" in
    --sources)
        [[ $# -eq 2 ]] || die "$usage"
        load_profile
        sources "$2"
        ;;
    --stage)
        [[ $# -eq 2 ]] || die "$usage"
        load_profile
        stage "$2"
        ;;
    "" | -*) die "$usage" ;;
    *)
        [[ $# -eq 1 ]] || die "$usage"
        load_profile
        composed "$1" "$work/description"
        cat "$work/description"
        ;;
esac
