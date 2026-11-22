#!/usr/bin/env bash
# Pin the Grok Bot skills in bots/shared/skills.txt and build the bundle a box
# applies them from. bots/README.md describes the manifest and the flow.
#
# Usage: bots/skills.sh --stage <empty-folder>
#        bots/skills.sh --bump <repo> [<ref>]
#   --stage   download the skills the profile in .env (DOTFILES_PROFILE)
#             declares, verify each sha256, and write the bundle; any failure
#             writes nothing
#   --bump    pin <repo> to the commit its ref points at and record every skill
#             there in base/, for every profile, or only the skills already
#             listed when its source line ends in "listed"; <ref> replaces the
#             recorded ref, as in a new release tag

set -euo pipefail
start_dir=$PWD
cd "$(dirname "$0")/.."
source ./utils.sh

manifest=bots/shared/skills.txt
usage="Usage: bots/skills.sh --stage <empty-folder> | --bump <repo> [<ref>]"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

function sha256_of() {
    shasum -a 256 "$1" | awk '{ print $1 }'
}

# fetch <repo> <commit> <path> <out>
function fetch() {
    gh api "repos/$1/contents/$3?ref=$2" -H 'Accept: application/vnd.github.raw' </dev/null >"$4" ||
        die "Couldn't download $3 from $1 at $2"
}

function stage() {
    local staging bundle="$work/bundle" upstream="" dir="" commit="" count=0
    local first second third fourth fifth _
    staging=$(staging_folder "$start_dir" "$1") || exit 1
    [[ -z "$(ls -A "$staging")" ]] || die "$staging isn't empty"

    load_profile
    mkdir -p "$bundle"
    render "$manifest" "$bundle/skills.txt"
    [[ -e "$bundle/skills.txt" ]] || die "$manifest is deleted for profile $DOTFILES_PROFILE"
    while read -r first second third fourth fifth _ || [[ -n "$first" ]]; do
        case "$first" in
            "") ;;
            source)
                upstream=$second
                dir=$third
                commit=$fifth
                ;;
            *)
                mkdir -p "$bundle/$first"
                fetch "$upstream" "$commit" "$dir/$first/SKILL.md" "$bundle/$first/SKILL.md"
                [[ "$(sha256_of "$bundle/$first/SKILL.md")" == "$second" ]] ||
                    die "HASH_MISMATCH: $first from $upstream at $commit isn't what $manifest pins. Nothing written."
                count=$((count + 1))
                ;;
        esac
    done <"$bundle/skills.txt"
    ((count > 0)) || die "$manifest lists no skills for profile $DOTFILES_PROFILE"
    sha256_of "$bundle/skills.txt" >"$bundle/skills.txt.sha256"
    cp bots/check-skills.py "$bundle/"
    cp -R "$bundle/." "$staging/"
    color_print "$green" "Verified $count skills for profile $DOTFILES_PROFILE in $staging"
}

# supported_skill <id> <file> [<field>]: stop on a skill UpdateSkill can't write
# as it is. <field> names one more frontmatter field the skill may set.
function supported_skill() {
    local keys
    case "$1" in
        plan | source) die "$1 can't be a skill id: bots/skills.sh and check-skills.py use that name" ;;
    esac
    keys=$(awk -v allowed="${3:-}" 'NR == 1 { next } /^---$/ { exit } /^[^[:space:]]/ { sub(/:.*/, ""); if ($0 != allowed) print }' "$2" | sort | tr '\n' ' ')
    [[ "$keys" == "description name " ]] ||
        die "$1 has the frontmatter fields $keys, and UpdateSkill can write only name and description"
    [[ "$(sed -n '2,/^---$/s/^name: *//p' "$2")" == "$1" ]] || die "$1 has a name that differs from its folder"
}

function bump() {
    local upstream=$1 ref=$2 file="base/$manifest" recorded dir old_ref commit path id count=0 profile
    local skill_re='^[a-z0-9][a-z0-9-]*/SKILL\.md$'
    local old_commit mode listed=""
    recorded=$(awk -v r="$upstream" '$1 == "source" && $2 == r' "$file")
    [[ -n "$recorded" ]] || die "$file has no source $upstream"
    [[ "$recorded" != *$'\n'* ]] || die "$file lists $upstream twice; give each repo one section"
    read -r _ _ dir old_ref old_commit mode <<<"$recorded"
    case "$mode" in
        "") ;;
        listed)
            listed=$(awk -v r="$upstream" '$1 == "source" { in_section = ($2 == r); next } !NF { in_section = 0 } in_section { print $1 }' "$file")
            [[ -n "$listed" ]] || die "$file lists no skills under source $upstream, and listed pins only those"
            ;;
        *) die "$file ends source $upstream with $mode, and only listed can go there" ;;
    esac
    ref=${ref:-$old_ref}
    commit=$(gh api "repos/$upstream/commits/$ref" --jq .sha </dev/null) || die "Couldn't resolve $ref in $upstream"
    gh api "repos/$upstream/git/trees/$commit?recursive=1" </dev/null >"$work/tree.json" ||
        die "Couldn't list $upstream at $commit"
    jq -e '.truncated | not' "$work/tree.json" >/dev/null || die "GitHub truncated the file list of $upstream"

    echo "source $upstream $dir $ref $commit${mode:+ $mode}" >"$work/section"
    while IFS= read -r path; do
        if [[ -n "$listed" ]] && ! grep -qxF "${path%%/*}" <<<"$listed"; then continue; fi
        [[ "$path" =~ $skill_re ]] ||
            die "$upstream has $dir/$path, and UpdateSkill can write only a skill's SKILL.md"
        id=${path%/SKILL.md}
        fetch "$upstream" "$commit" "$dir/$path" "$work/skill"
        supported_skill "$id" "$work/skill" "${mode:+disable-model-invocation}"
        echo "$id $(sha256_of "$work/skill")" >>"$work/section"
        count=$((count + 1))
    done < <(jq -r --arg d "$dir/" '.tree[] | select(.type == "blob") | .path | select(startswith($d)) | ltrimstr($d)' "$work/tree.json")
    for id in $listed; do
        grep -q "^$id " "$work/section" || die "$upstream has no $dir/$id/SKILL.md at $ref"
    done
    ((count > 0)) || die "$upstream has no skills in $dir at $ref"

    awk -v r="$upstream" -v section="$work/section" '
        $1 == "source" {
            replacing = ($2 == r)
            if (replacing) while ((getline line <section) > 0) print line
        }
        !NF { replacing = 0 }
        !replacing { print }
    ' "$file" >"$work/manifest"
    cat "$work/manifest" >"$file"
    for profile in profiles/*/; do
        profile=${profile%/}
        DOTFILES_PROFILE=${profile#profiles/} ./install.sh --show "$manifest" >/dev/null ||
            color_print "$yellow" "${profile#profiles/} no longer renders $manifest; see .conflicts/"
    done
    color_print "$green" "Pinned $count skills from $upstream at $ref ($commit) in $file. Was $old_commit."
}

case "${1:-}" in
    --stage)
        [[ $# -eq 2 ]] || die "$usage"
        stage "$2"
        ;;
    --bump)
        [[ $# -eq 2 || $# -eq 3 ]] || die "$usage"
        bump "$2" "${3:-}"
        ;;
    *) die "$usage" ;;
esac
