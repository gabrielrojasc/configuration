#!/usr/bin/env bash
# Bring a Grok Bot fleet's snapshot into the repo for the profile in .env
# (DOTFILES_PROFILE), asking for each change who gets it, like copy.sh.
# bots/README.md describes the staging layout and the flow.
#
# Usage: bots/snapshot.sh [--list | --expect <fingerprint>] <staging-dir>
#        bots/snapshot.sh --seed
#   (no flags)        ask at the terminal for each change:
#                     y = every profile (base), n = only this profile,
#                     q = only this profile, for this and every remaining change
#   --list            print the numbered changes and their fingerprint; writes nothing
#   --expect <fp>     read the answers from stdin, one y, n, or q per line in
#                     --list order; refuse if the changes differ from that list
#   --seed            record this profile's bots in the repo as what its fleet
#                     has now, as the starting point for later snapshots

set -euo pipefail
start_dir=$PWD
cd "$(dirname "$0")/.."
source ./utils.sh

mode=ask
expect=""
staging_arg=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --list) mode=list ;;
        --seed) mode=seed ;;
        --expect) [[ $# -ge 2 ]] || die "--expect needs the fingerprint from --list"; mode=expect; expect=$2; shift ;;
        -*) die "Unknown argument: $1 (see the usage at the top of bots/snapshot.sh)" ;;
        *) [[ -z "$staging_arg" ]] || die "Give one staging folder"; staging_arg=$1 ;;
    esac
    shift
done

load_profile
roster="$profile_dir/bots.txt"
[[ -f "$roster" ]] || die "Profile $DOTFILES_PROFILE has no Grok Bot fleet: $roster is missing. See bots/README.md."
baseline="${snapshot_dir%/snapshot}/bots/$DOTFILES_PROFILE"

slugs=()
ids=()
while read -r slug id; do
    if [[ -n "$slug" ]]; then
        slugs+=("$slug")
        ids+=("$id")
    fi
done <"$roster"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

function repo_keys() {
    local layer slug
    for layer in base "$profile_dir"; do
        for slug in "${slugs[@]}" shared; do
            if [[ -d "$layer/bots/$slug" ]]; then
                (cd "$layer" && find "bots/$slug" -type f ! -name .DS_Store)
            fi
        done
    done | sort -u
}

function rendered() {
    rm -f "$2"
    if [[ -n "$(source_of "$1")" ]]; then render "$1" "$2"; fi
}

function baseline_of() {
    local key=$1 slug
    slug=$(echo "$key" | cut -d/ -f2)
    if [[ "$slug" != shared ]] && ! cmp -s <(grep "^$slug " "$roster") <(grep "^$slug " "$baseline/bots.txt" 2>/dev/null); then
        return 0
    fi
    if [[ -f "$baseline/$key" ]]; then echo "$baseline/$key"; fi
}

if [[ "$mode" == seed ]]; then
    [[ -z "$staging_arg" ]] || die "--seed takes no staging folder"
    rm -rf "$work/seed"
    mkdir -p "$work/seed"
    while IFS= read -r key; do
        mkdir -p "$(dirname "$work/seed/$key")"
        rendered "$key" "$work/seed/$key" || die "$key doesn't render for $DOTFILES_PROFILE; fix that first"
    done < <(repo_keys)
    cp "$roster" "$work/seed/bots.txt"
    rm -rf "$baseline"
    mkdir -p "$(dirname "$baseline")"
    cp -R "$work/seed" "$baseline"
    color_print "$green" "Recorded $(find "$baseline/bots" -type f 2>/dev/null | wc -l | tr -d ' ') files as what the $DOTFILES_PROFILE fleet has now."
    exit 0
fi

[[ -n "$staging_arg" ]] || die "Usage: bots/snapshot.sh [--list | --expect <fingerprint>] <staging-dir>"
staging=$(cd "$start_dir" && cd "$staging_arg" 2>/dev/null && pwd -P) || die "Staging folder not found: $staging_arg"
root=$(pwd -P)
if [[ "$staging" == "$root" || "$staging" == "$root"/* ]]; then
    die "Stage outside the repo, for example in mktemp -d: $staging is inside $root"
fi
[[ -d "$baseline" ]] || die "There's no record of what the $DOTFILES_PROFILE fleet had at its last snapshot. If the repo matches the fleet now, run bots/snapshot.sh --seed first. See bots/README.md."

out="$work/out"
mkdir -p "$out/bots/shared"

routine_re='^[a-z0-9][a-z0-9-]*\.md$'

function expected() {
    local rel=$1 id
    case "$rel" in
        setup-map.md | unsettled-threads.json) return 0 ;;
    esac
    for id in "${ids[@]}"; do
        case "$rel" in
            "$id" | "$id/profile.json" | "$id/settings.json" | "$id/routines") return 0 ;;
            "$id"/routines/*)
                if [[ "${rel#"$id"/routines/}" =~ $routine_re ]]; then return 0; fi
                ;;
        esac
    done
    return 1
}

unexpected=$(cd "$staging" && find . -mindepth 1 ! -name .DS_Store | sed 's|^\./||' | sort |
    while IFS= read -r rel; do
        if ! expected "$rel"; then echo "  $rel"; fi
    done)
[[ -z "$unexpected" ]] || die "Unexpected files in $staging (see bots/README.md for the layout):
$unexpected"

missing=""
for f in setup-map.md unsettled-threads.json; do
    if [[ ! -f "$staging/$f" ]]; then missing+="  $f"$'\n'; fi
done
for i in "${!ids[@]}"; do
    for f in profile.json settings.json; do
        if [[ ! -f "$staging/${ids[i]}/$f" ]]; then missing+="  ${ids[i]}/$f (${slugs[i]})"$'\n'; fi
    done
    if [[ ! -d "$staging/${ids[i]}/routines" ]]; then missing+="  ${ids[i]}/routines/ (${slugs[i]})"$'\n'; fi
done
[[ -z "$missing" ]] || die "Incomplete snapshot; missing from $staging:
$missing"

json_defs='
def norm: map(if type == "number" then "[]" else . end) | join(".");
def leaves: paths(if type == "object" or type == "array" then length == 0 else true end);
def lines: split("\n") | map(select(length > 0));
def kept($keep): . as $p | $keep | lines | any(. == $p);
def dropped($drop): . as $p | $drop | lines | any(. as $r | $p == $r or ($p | startswith($r + ".")) or ($p | startswith($r + "[]")));
'

function rules() {
    awk -v f="$1" -v a="$2" '$1 == f && $2 == a { print $3 }' bots/fields.txt
}

function filter_json() {
    local file=$1 bot=$2 in=$3 dest=$4 keep drop unknown
    keep=$(rules "$file" keep)
    drop=$(rules "$file" drop)
    jq -e 'type == "object"' "$in" >/dev/null || die "$bot/$file is not a JSON object"
    unknown=$(jq -r --arg keep "$keep" --arg drop "$drop" "$json_defs"'
        [leaves | norm] | unique[] | select((kept($keep) or dropped($drop)) | not)' "$in")
    [[ -z "$unknown" ]] || die "$bot/$file has fields bots/fields.txt doesn't list. Add each as keep or drop, then rerun:
$(sed 's/^/  /' <<<"$unknown")"
    jq -S --arg keep "$keep" "$json_defs"'
        . as $in | reduce (leaves | select(norm | kept($keep))) as $p ({}; setpath($p; $in | getpath($p)))' "$in" >"$dest"
}

function check_routine() {
    local name="$1/routines/$(basename "$2")" front line key keep
    front=$(awk 'NR == 1 { if ($0 != "---") exit 1; next } $0 == "---" { closed = 1; exit } { print } END { if (!closed) exit 1 }' "$2") ||
        die "$name must open with front matter between --- lines"
    keep=$(rules routine keep)
    while IFS= read -r line; do
        key=${line%%:*}
        if [[ "$line" != *:* ]] || ! grep -qxF -- "$key" <<<"$keep"; then
            die "$name has front matter field '$key', which bots/fields.txt doesn't keep"
        fi
    done <<<"$front"
    for key in name trigger enabled; do
        grep -q "^$key:" <<<"$front" || die "$name is missing $key"
    done
    grep -qxE 'enabled: (true|false)' <<<"$front" || die "$name needs enabled: true or enabled: false"
}

for i in "${!ids[@]}"; do
    slug=${slugs[i]}
    src="$staging/${ids[i]}"
    mkdir -p "$out/bots/$slug"
    filter_json profile.json "$slug" "$src/profile.json" "$out/bots/$slug/profile.json"
    filter_json settings.json "$slug" "$src/settings.json" "$out/bots/$slug/settings.json"
    for routine in "$src"/routines/*.md; do
        [[ -e "$routine" ]] || continue
        check_routine "$slug" "$routine"
        mkdir -p "$out/bots/$slug/routines"
        cp "$routine" "$out/bots/$slug/routines/"
    done
done

cp "$staging/setup-map.md" "$out/bots/shared/setup-map.md"

jq -S '
def merge($a; $b):
  if $a == null then $b
  elif $b == null then $a
  elif ($a | type) == "object" and ($b | type) == "object" then
    reduce ($b | keys[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]))
  elif ($a | type) == "array" and ($b | type) == "array" then
    if ($a | length) == 0 then $b elif ($b | length) == 0 then $a else [merge($a[0]; $b[0])] end
  else
    [$a, $b] | map(if type == "string" then split("|")[] else type end) | unique | join("|")
  end;
def shape:
  if type == "object" then
    if all(keys[]; test("^[A-Za-z_]{1,40}$")) then map_values(shape)
    else {"<key>": (reduce (.[] | shape) as $s (null; merge(.; $s)))}
    end
  elif type == "array" then
    if length == 0 then [] else [reduce (.[] | shape) as $s (null; merge(.; $s))] end
  else type
  end;
shape' "$staging/unsettled-threads.json" >"$out/bots/shared/unsettled-threads.shape.json"

token_re='-----BEGIN [A-Z ]*PRIVATE KEY|(^|[^A-Za-z0-9])(sk|pk|rk)-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
assign_re='(token|secret|password|passwd|api[_-]?key)["'\'']?[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9/+_.-]{12,}|serverid'
hits=$({
    grep -rnE -e "$token_re" "$out" || true
    grep -rniE -e "$assign_re" "$out" || true
} | cut -d: -f1,2 | sed "s|^$out/||" | sort -u)
[[ -z "$hits" ]] || die "Possible secrets; nothing was written. Remove them at the source or in staging, then rerun:
$(sed 's/^/  /' <<<"$hits")"

all_keys=$({
    (cd "$out" && find bots -type f)
    repo_keys
    if [[ -d "$baseline/bots" ]]; then (cd "$baseline" && find bots -type f); fi
} | while IFS= read -r key; do
    slug=$(echo "$key" | cut -d/ -f2)
    if [[ "$slug" == shared ]] || grep -q "^$slug " "$roster"; then echo "$key"; fi
done | LC_ALL=C sort -u)

function fingerprint() {
    local key f
    {
        echo "$DOTFILES_PROFILE"
        shasum <bots/fields.txt
        shasum <"$roster"
        while IFS= read -r key; do
            [[ -n "$key" ]] || continue
            echo "$key"
            for f in "$out/$key" "$(baseline_of "$key")" "base/$key" "$profile_dir/$key" "$(patch_of "$key")"; do
                if [[ -n "$f" && -f "$f" ]]; then shasum <"$f"; else echo -; fi
            done
        done <<<"$all_keys"
    } | shasum -a 256 | cut -c1-16
}

sort_init
if [[ "$mode" == list ]]; then sort_mode=list; fi
owned=()
conflicts=()
mkdir -p "$work/repo" "$work/merged"
while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    fleet="$out/$key"
    last=$(baseline_of "$key")
    repo_version="$work/repo/$key"
    mkdir -p "$(dirname "$repo_version")" "$(dirname "$work/merged/$key")"
    rendered "$key" "$repo_version" || die "$key doesn't render for $DOTFILES_PROFILE; fix that first"

    if [[ -f "$fleet" && -f "$repo_version" ]]; then
        if [[ -f "$profile_dir/$key" ]]; then
            if ! cmp -s "$fleet" "$repo_version"; then owned+=("$key"); fi
            continue
        fi
        if ! git merge-file -p -L fleet -L "last snapshot" -L repo \
            "$fleet" "${last:-$repo_version}" "$repo_version" >"$work/merged/$key"; then
            conflicts+=("$key")
            continue
        fi
        if ! cmp -s "$work/merged/$key" "$repo_version"; then stage "$key" "$repo_version" "$work/merged/$key"; fi
    elif [[ -f "$fleet" ]]; then
        if [[ -n "$last" ]] && cmp -s "$fleet" "$last"; then continue; fi
        if [[ -f "base/$key" ]]; then
            stage "$key" "base/$key" "$fleet"
        else
            stage_new "$key" "$fleet"
        fi
    elif [[ -f "$repo_version" && -n "$last" ]]; then
        if [[ -f "$profile_dir/$key" ]]; then
            owned+=("$key")
        else
            stage_deleted "$key" "$repo_version"
        fi
    fi
done <<<"$all_keys"

if ((${#conflicts[@]})); then
    if [[ "$mode" == list ]]; then
        die "The fleet and the repo changed the same lines since the last snapshot in:
$(printf '  %s\n' "${conflicts[@]}")
Run bots/snapshot.sh $staging_arg at a terminal to write them to .conflicts/ for fixing."
    fi
    for key in "${conflicts[@]}"; do
        mkdir -p "$(dirname "$conflicts_dir/$key")"
        cp "$work/merged/$key" "$conflicts_dir/$key"
    done
    die "The fleet and the repo changed the same lines since the last snapshot. Nothing was written. For each file, fix the markers in .conflicts/<key> (the file $DOTFILES_PROFILE should have), run ./copy.sh --resolve <key>, then rerun:
$(printf '  %s\n' "${conflicts[@]}")"
fi

print=$(fingerprint)
changes=$((${#candidates[@]} + ${#new_files[@]} + ${#deleted_files[@]}))

if [[ "$mode" == list ]]; then
    if ((changes)); then sort_changes; fi
    for key in ${owned[@]+"${owned[@]}"}; do
        echo
        echo "$(display_name "$key")   only $DOTFILES_PROFILE has this file; it's updated without asking"
    done
    echo
    if ((changes + ${#owned[@]} == 0)); then echo "No changes."; fi
    echo "Fingerprint: $print"
    if ((changes)); then
        echo "Answer each numbered change with y (every profile), n (only $DOTFILES_PROFILE), or q (only $DOTFILES_PROFILE, for it and every later change), one per line:"
        echo "  printf 'y\\nn\\n' | bots/snapshot.sh --expect $print <staging-dir>"
    else
        echo "Apply with: bots/snapshot.sh --expect $print <staging-dir> </dev/null"
    fi
    exit 0
fi

if [[ "$mode" == expect && "$expect" != "$print" ]]; then
    die "The changes differ from the --list with fingerprint $expect (now $print): the staging folder, the repo, or the last snapshot changed since. Nothing was written. Run --list again."
fi
if [[ "$mode" == ask && ! -t 0 ]]; then
    die "To read answers from stdin, pass --expect with the fingerprint from --list."
fi

answers_ran_out=0
if ((changes)); then sort_changes; fi
place_changes

for key in ${owned[@]+"${owned[@]}"}; do
    if [[ -f "$out/$key" ]]; then
        cat "$out/$key" >"$profile_dir/$key"
        copied+=("$(display_name "$key"): updated in $DOTFILES_PROFILE (only this profile has it)")
    else
        rm -f "$profile_dir/$key"
        copied+=("$(display_name "$key"): deleted from $DOTFILES_PROFILE (only this profile had it)")
    fi
done

for dir in base/bots "$profile_dir/bots" "$profile_dir/patches/bots"; do
    if [[ -d "$dir" ]]; then find "$dir" -type d -empty -delete; fi
done

rm -rf "$baseline"
mkdir -p "$baseline"
cp -R "$out/bots" "$baseline/bots"
cp "$roster" "$baseline/bots.txt"

for other in profiles/*; do
    p=${other#profiles/}
    if [[ "$p" == "$DOTFILES_PROFILE" || ! -d "$other/patches/bots" ]]; then continue; fi
    while IFS= read -r patch; do
        key=${patch#"$other"/patches/}
        key=${key%.patch}
        if ! (DOTFILES_PROFILE=$p profile_dir=$other rendered "$key" "$work/check") 2>/dev/null; then
            color_print "$yellow" "$key no longer renders for $p. Fix it with DOTFILES_PROFILE=$p ./copy.sh --resolve $key"
        fi
    done < <(find "$other/patches/bots" -name '*.patch' | sort)
done

if ((answers_ran_out)); then
    color_print "$yellow" "The answers ran out before the last change; the rest stay in $DOTFILES_PROFILE only."
fi
section 'Snapshot'
if ((${#copied[@]})); then
    printf '%s\n' "${copied[@]}"
    echo
    echo 'Review with git diff, then commit.'
else
    echo 'Nothing changed.'
fi
