#!/usr/bin/env bash
# Bring a Grok Bot fleet's snapshot into the repo for the profile in .env
# (DOTFILES_PROFILE), asking for each change who gets it, like copy.sh.
# bots/README.md describes the staging layout and the flow.
#
# Usage: bots/snapshot.sh [--list | --expect <fingerprint>] <staging-dir>
#        bots/snapshot.sh --discard <staging-dir>
#        bots/snapshot.sh --seed
#        bots/snapshot.sh --sync-record
#   (no flags)        ask at the terminal for each change:
#                     y = every profile (base), n = only this profile,
#                     q = only this profile, for this and every remaining change
#   --list            print the numbered changes and their fingerprint; writes nothing
#   --expect <fp>     read the answers from stdin, one y, n, or q per line in
#                     --list order; refuse if the changes differ from that list
#   --discard         delete the staging folder without applying it
#   --seed            record this profile's bots in the repo as what its fleet
#                     has now, as the starting point for later snapshots
#   --sync-record     update that record to bots.txt: follow renamed slugs and
#                     drop bots it no longer lists; writes nothing in the repo
#
# The record matches bots.txt by bot id, so a slug renamed there keeps its
# bot's last snapshot, and a bot removed from it drops out. Of bots/shared/,
# snapshots handle only setup-map.md; they never list, record, or delete any
# other file there. The staged ledger must match the format in
# bots/shared/unsettled-threads.shape.json, which the repo decides; a ledger
# that doesn't stops the snapshot.
#
# After it applies every change without a warning, and with --discard, the
# script deletes the staging folder and every file beside it named
# <staging-dir>.*, such as a tarball. It does so only for a staging folder
# directly inside /tmp, $TMPDIR, or the user's temp folder, where mktemp -d
# makes one. When it stops on an error or ends with a warning, it keeps them.
#
# Each machine ID listed in ~/.local/state/dotfiles/bots/<profile>.machine-ids
# becomes <machine-id> in the script's copies of the staging folder and the
# record. A labelled machine ID the list doesn't name stops the snapshot.
#
# Each bot's <bot id>/routines.json is its own report of its routines. A bot
# without one, or whose report doesn't match its staged routines, stops the
# snapshot: a missing routine is never read as a deleted one.

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
        --discard) mode=discard ;;
        --sync-record) mode=sync ;;
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
machine_ids="$baseline.machine-ids"
uuid_re='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

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
fleet_shared=(bots/shared/setup-map.md)
ledger_format=bots/shared/unsettled-threads.shape.json
record="$work/record"

function repo_keys() {
    local layer slug key
    for layer in base "$profile_dir"; do
        for slug in "${slugs[@]}"; do
            if [[ -d "$layer/bots/$slug" ]]; then
                (cd "$layer" && find "bots/$slug" -type f ! -name .DS_Store)
            fi
        done
        for key in "${fleet_shared[@]}"; do
            if [[ -f "$layer/$key" ]]; then echo "$key"; fi
        done
    done | sort -u
}

function rendered() {
    rm -f "$2"
    if [[ -n "$(source_of "$1")" ]]; then render "$1" "$2"; fi
}

function recorded_slug() {
    if [[ -f "$baseline/bots.txt" ]]; then awk -v id="$1" '$2 == id { print $1; exit }' "$baseline/bots.txt"; fi
}

function hide_machine_ids() {
    local dir=$1 id file
    if [[ ! -f "$machine_ids" ]]; then return 0; fi
    while IFS= read -r id || [[ -n "$id" ]]; do
        if [[ -z "$id" ]]; then continue; fi
        [[ "$id" =~ ^$uuid_re$ ]] || die "$machine_ids must hold one machine ID per line"
        while IFS= read -r file; do
            LC_ALL=C sed "s/$id/<machine-id>/Ig" "$file" >"$file.tmp"
            mv "$file.tmp" "$file"
        done < <(LC_ALL=C grep -rliF -- "$id" "$dir" || true)
    done <"$machine_ids"
}

function translate_record() {
    local i key old
    rm -rf "$record"
    mkdir -p "$record/bots"
    cp "$roster" "$record/bots.txt"
    for key in "${fleet_shared[@]}"; do
        if [[ -f "$baseline/$key" ]]; then
            mkdir -p "$(dirname "$record/$key")"
            cp "$baseline/$key" "$record/$key"
        fi
    done
    for i in "${!ids[@]}"; do
        old=$(recorded_slug "${ids[i]}")
        if [[ -n "$old" && -d "$baseline/bots/$old" ]]; then cp -R "$baseline/bots/$old" "$record/bots/${slugs[i]}"; fi
    done
    hide_machine_ids "$record"
}

function baseline_of() {
    if [[ -f "$record/$1" ]]; then echo "$record/$1"; fi
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
    hide_machine_ids "$work/seed"
    rm -rf "$baseline"
    mkdir -p "$(dirname "$baseline")"
    cp -R "$work/seed" "$baseline"
    color_print "$green" "Recorded $(find "$baseline/bots" -type f 2>/dev/null | wc -l | tr -d ' ') files as what the $DOTFILES_PROFILE fleet has now."
    exit 0
fi

if [[ "$mode" == sync ]]; then
    [[ -z "$staging_arg" ]] || die "--sync-record takes no staging folder"
    [[ -d "$baseline" ]] || die "There's no record of the $DOTFILES_PROFILE fleet to update. See bots/README.md."
    translate_record
    if [[ -f "$baseline/bots.txt" ]]; then
        while read -r slug id; do
            [[ -n "$slug" ]] || continue
            now=$(awk -v id="$id" '$2 == id { print $1; exit }' "$roster")
            if [[ -z "$now" ]]; then
                echo "Dropped $slug: $roster no longer lists it."
            elif [[ "$now" != "$slug" ]]; then
                echo "Renamed $slug to $now."
            fi
        done <"$baseline/bots.txt"
    fi
    for f in "$baseline"/bots/shared/*; do
        if [[ -f "$f" && ! -f "$record/bots/shared/${f##*/}" ]]; then
            echo "Dropped bots/shared/${f##*/}: snapshots don't handle it."
        fi
    done
    rm -rf "$baseline"
    cp -R "$record" "$baseline"
    color_print "$green" "Updated the record of the $DOTFILES_PROFILE fleet to match $roster."
    exit 0
fi

[[ -n "$staging_arg" ]] || die "Usage: bots/snapshot.sh [--list | --expect <fingerprint> | --discard] <staging-dir>"
staging=$(cd "$start_dir" && cd "$staging_arg" 2>/dev/null && pwd -P) || die "Staging folder not found: $staging_arg"
root=$(pwd -P)
if [[ "$staging" == "$root" || "$staging" == "$root"/* ]]; then
    die "Stage outside the repo, for example in mktemp -d: $staging is inside $root"
fi
routine_re='^[a-z0-9][a-z0-9-]*\.md$'

function expected() {
    local rel=$1 id
    case "$rel" in
        setup-map.md | unsettled-threads.json) return 0 ;;
    esac
    for id in "${ids[@]}"; do
        case "$rel" in
            "$id" | "$id/profile.json" | "$id/settings.json" | "$id/routines.json" | "$id/routines") return 0 ;;
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

function in_temp_folder() {
    local dir
    for dir in /tmp ${TMPDIR:+"$TMPDIR"} "$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)"; do
        dir=$(cd "${dir:-/nonexistent}" 2>/dev/null && pwd -P) || continue
        if [[ "$(dirname "$staging")" == "$dir" ]]; then return 0; fi
    done
    return 1
}

function clean_staging() {
    local f
    if ! in_temp_folder; then
        color_print "$yellow" "Left $staging in place: the script deletes only a staging folder directly inside a temp folder. Delete it yourself; it holds the live ledger and each bot's serverId."
        return 0
    fi
    if rm -rf "$staging"; then
        echo "Deleted $staging"
    else
        color_print "$yellow" "Couldn't delete $staging. Delete it yourself."
    fi
    for f in "$staging".*; do
        if [[ ! -f "$f" || -L "$f" ]]; then continue; fi
        if rm -f "$f"; then
            echo "Deleted $f"
        else
            color_print "$yellow" "Couldn't delete $f. Delete it yourself."
        fi
    done
}

if [[ "$mode" == discard ]]; then
    in_temp_folder || die "Delete $staging yourself: --discard deletes only a staging folder directly inside /tmp, \$TMPDIR, or the user's temp folder."
    clean_staging
    exit 0
fi

[[ -d "$baseline" ]] || die "There's no record of what the $DOTFILES_PROFILE fleet had at its last snapshot. If the repo matches the fleet now, run bots/snapshot.sh --seed first. See bots/README.md."
translate_record

missing=""
for f in setup-map.md unsettled-threads.json; do
    if [[ ! -f "$staging/$f" ]]; then missing+="  $f"$'\n'; fi
done
for i in "${!ids[@]}"; do
    for f in profile.json settings.json; do
        if [[ ! -f "$staging/${ids[i]}/$f" ]]; then missing+="  ${ids[i]}/$f (${slugs[i]})"$'\n'; fi
    done
done
[[ -z "$missing" ]] || die "Incomplete snapshot; missing from $staging:
$missing"
unreported=""
for i in "${!ids[@]}"; do
    if [[ ! -f "$staging/${ids[i]}/routines.json" ]]; then unreported+="  ${ids[i]}/routines.json (${slugs[i]})"$'\n'; fi
done
[[ -z "$unreported" ]] || die "Unverified routines; nothing was written. These bots haven't reported their routines, so the snapshot can't tell no routines from missed ones. Ask each bot for its routine report, as bots/README.md describes, then rerun:
$unreported"

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

report_defs='
def text: type == "string" and length > 0;
if type != "object" then "must be a JSON object"
else
  ((keys - ["reportedBy", "reportedOn", "confirmedBy", "routines"])[] | "has field \(.), which a routine report never has"),
  (if .reportedBy == $name then empty else "needs reportedBy: the bot name in profile.json, \($name)" end),
  (if (.reportedOn | text and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")) then empty else "needs reportedOn: the report date, such as 2026-11-07" end),
  (if has("confirmedBy") and (.confirmedBy | text | not) then "needs confirmedBy to name who confirmed the report, or no confirmedBy" else empty end),
  (if (.routines | type) != "array" then "needs routines: a list, empty when the bot has none"
   else
     (.routines[] | select(type != "object" or (keys - ["file", "folderId"]) != [] or (.file | text and test($file_re) | not) or (.folderId | text | not))
       | "needs each routine as {\"file\": \"<slug>.md\", \"folderId\": \"<folder slug>\"}, with the folder slug the bot reports, not \(tojson)"),
     ([.routines[] | .file?] | group_by(.) | map(select(length > 1) | .[0]) | .[] | "lists \(.) twice")
   end)
end'
reports=()

function check_report() {
    local slug=$1 dir=$2 profile=$3 report="$2/routines.json" name problems listed staged routine count
    name=$(jq -r '.name // empty' "$profile")
    [[ -n "$name" ]] || die "$slug/profile.json has no name to match its routine report against"
    problems=$(jq -r --arg name "$name" --arg file_re "$routine_re" "$report_defs" "$report" 2>&1) ||
        die "$slug/routines.json is not valid JSON"
    [[ -z "$problems" ]] || die "$slug/routines.json, the bot's routine report, is invalid. Ask the bot to report again, then rerun:
$(sed 's/^/  /' <<<"$problems")"
    listed=$(jq -r '.routines[].file' "$report" | LC_ALL=C sort)
    staged=$(for routine in "$dir"/routines/*.md; do
        if [[ -e "$routine" ]]; then basename "$routine"; fi
    done | LC_ALL=C sort)
    problems=$({
        LC_ALL=C comm -23 <(echo "$listed") <(echo "$staged") | sed '/^$/d; s/$/: in the report, but not staged/'
        LC_ALL=C comm -13 <(echo "$listed") <(echo "$staged") | sed '/^$/d; s/$/: staged, but not in the report/'
    })
    [[ -z "$problems" ]] || die "$slug's routine report doesn't match its staged routines; nothing was written. Stage exactly the routines the bot reports, then rerun:
$(sed 's/^/  /' <<<"$problems")"
    count=$(jq '.routines | length' "$report")
    reports+=("$slug: $(jq -r --argjson n "$count" '
        (if $n == 0 then "no routines" elif $n == 1 then "1 routine" else "\($n) routines" end)
        + ", reported by \(.reportedBy) on \(.reportedOn)"
        + (if has("confirmedBy") then ", confirmed by \(.confirmedBy)" else "" end)' "$report")")
}

fleet_copy="$work/fleet"
cp -R "$staging" "$fleet_copy"
hide_machine_ids "$fleet_copy"
hits=$({ LC_ALL=C grep -rniE --exclude unsettled-threads.json -e "(^|[^<])machine[ _-]?id.{0,12}$uuid_re" "$fleet_copy" || true; } |
    cut -d: -f1,2 | sed "s|^$fleet_copy/||" | sort -u)
[[ -z "$hits" ]] || die "Machine IDs; nothing was written. Add each ID to $machine_ids, one per line, then rerun:
$(sed 's/^/  /' <<<"$hits")"

out="$work/out"
mkdir -p "$out/bots/shared"

for i in "${!ids[@]}"; do
    slug=${slugs[i]}
    src="$fleet_copy/${ids[i]}"
    mkdir -p "$out/bots/$slug"
    filter_json profile.json "$slug" "$src/profile.json" "$out/bots/$slug/profile.json"
    filter_json settings.json "$slug" "$src/settings.json" "$out/bots/$slug/settings.json"
    check_report "$slug" "$src" "$out/bots/$slug/profile.json"
    for routine in "$src"/routines/*.md; do
        [[ -e "$routine" ]] || continue
        check_routine "$slug" "$routine"
        mkdir -p "$out/bots/$slug/routines"
        cp "$routine" "$out/bots/$slug/routines/"
    done
done

cp "$fleet_copy/setup-map.md" "$out/bots/shared/setup-map.md"

rendered "$ledger_format" "$work/ledger-format.json"
[[ -f "$work/ledger-format.json" ]] || die "$ledger_format doesn't render for $DOTFILES_PROFILE; the ledger check needs it."
ledger_problems=$(jq -r --slurpfile format "$work/ledger-format.json" '
def fits($spec):
  if ($spec | type) == "array" then . as $v | any($spec[]; . == $v)
  elif . == null then $spec | endswith("|null")
  else ($spec | split("|")[0]) as $kind
    | if $kind == "string" then type == "string" and . != ""
      elif $kind == "boolean" then type == "boolean"
      elif $kind == "string[]" then type == "array" and all(.[]; type == "string" and . != "")
      else false
      end
  end;
def check($where; $spec):
  if type != "object" then "\($where): not an object"
  else
    . as $obj
    | ((keys - ($spec | keys))[] | "\($where): unknown field \(.)"),
      ((($spec | keys) - keys)[] | "\($where): missing field \(.)"),
      (($spec | keys) - ["threads"] | .[]
        | select(. as $k | $obj | has($k)) | select(. as $k | $obj[$k] | fits($spec[$k]) | not)
        | "\($where): \(.) must be \($spec[.] | if type == "array" then "one of " + join(", ") else . end)")
  end;
$format[0] as $f
| check("ledger"; $f),
  if (.threads | type) == "object" then .threads | to_entries[] | .key as $k | .value | check($k; $f.threads["<thread id>"])
  else "ledger: threads must be an object"
  end
' "$staging/unsettled-threads.json") || die "$staging/unsettled-threads.json isn't valid JSON; nothing was written."
[[ -z "$ledger_problems" ]] || die "The staged ledger doesn't match $ledger_format; nothing was written. Fix the ledger at the source with T3 Tots' ledger check, as bots/README.md describes, then rerun:
$(sed 's/^/  /' <<<"$ledger_problems")"

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
    (cd "$record" && find bots -type f)
} | while IFS= read -r key; do
    slug=$(echo "$key" | cut -d/ -f2)
    if [[ "$slug" == shared ]] || grep -q "^$slug " "$roster"; then echo "$key"; fi
done | LC_ALL=C sort -u)

function fingerprint() {
    local key f id
    {
        echo "$DOTFILES_PROFILE"
        shasum <bots/fields.txt
        shasum <"$roster"
        for id in "${ids[@]}"; do shasum <"$fleet_copy/$id/routines.json"; done
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

echo "Routine reports:"
printf '  %s\n' ${reports[@]+"${reports[@]}"}
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

warned=$answers_ran_out
for other in profiles/*; do
    p=${other#profiles/}
    if [[ "$p" == "$DOTFILES_PROFILE" || ! -d "$other/patches/bots" ]]; then continue; fi
    while IFS= read -r patch; do
        key=${patch#"$other"/patches/}
        key=${key%.patch}
        if ! (DOTFILES_PROFILE=$p profile_dir=$other rendered "$key" "$work/check") 2>/dev/null; then
            color_print "$yellow" "$key no longer renders for $p. Fix it with DOTFILES_PROFILE=$p ./copy.sh --resolve $key"
            warned=1
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
if ((warned)); then
    color_print "$yellow" "Kept $staging because of the warning above. Once you've dealt with it, delete it with bots/snapshot.sh --discard $staging_arg"
else
    clean_staging
fi
