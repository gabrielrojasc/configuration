# shellcheck shell=bash
# Shared helpers for install.sh and copy.sh. Sourced from the repo root.
#
# A "key" is a path relative to a layer root (base/ or profiles/<name>/):
#   home/<path>       a file that lives at $HOME/<path>
#   bots/<path>       a Grok Bot file, written by bots/snapshot.sh, never installed
#   Brewfile          installed with brew bundle, read back with brew bundle dump
#   pnpm-globals.txt  installed with pnpm add -g, read back with pnpm ls -g
#   agent-skills.txt  installed with skills add -g, read back with skills ls -g
#   apps.txt          apps installed by hand, read back from /Applications;
#                     install only reports the missing ones
# A key renders from the profile's own copy if it has one, otherwise from
# base plus the profile's patches/<key>.patch when that exists.

# Format helpers for color_print
green="\033[0;32m"
blue="\033[0;34m"
cyan="\033[0;36m"
yellow="\033[0;33m"
red="\033[0;31m"
# Apply after a color: the colors above start with a reset (0;).
bold="\033[1m"
default="\033[0m"

function color_print() {
    local color=$1
    local message=$2

    echo -e "${color}${message}${default}\n"
}

# section <title>: a banner that separates the steps of a run.
function section() {
    local rule="" i
    for ((i = ${#1}; i < 68; i++)); do rule+="="; done
    echo -e "\n${cyan}${bold}== $1 ${rule}${default}\n"
}

# file_header <path> <note>: introduces one file's change.
function file_header() {
    echo -e "${yellow}${bold}> $1${default}  $2"
}

# One row per step for the summary table: name, kind (ok, change, info, fail), text.
summary_names=()
summary_kinds=()
summary_texts=()
function record() {
    summary_names+=("$1")
    summary_kinds+=("$2")
    summary_texts+=("$3")
}

function print_summary() {
    local i color
    printf "${bold}%-20s %s${default}\n" Step Result
    printf '%-20s %s\n' -------------------- ----------------------------------------
    for ((i = 0; i < ${#summary_names[@]}; i++)); do
        case "${summary_kinds[i]}" in
            ok) color=$green ;;
            change) color=$yellow ;;
            info) color=$blue ;;
            *) color=$red ;;
        esac
        printf "%-20s ${color}%s${default}\n" "${summary_names[i]}" "${summary_texts[i]}"
    done
    echo
}

# Mark the changed words inside changed lines with git's diff-highlight
# (brew's git ships it; Workbrew uses the same prefix). A fresh Mac doesn't
# have it yet, so plain line diffs pass through.
diff_highlight=$(command -v diff-highlight ||
    ls "${HOMEBREW_PREFIX:-/opt/homebrew}/share/git-core/contrib/diff-highlight/diff-highlight" 2>/dev/null || true)
function highlight_words() {
    if [[ -n "$diff_highlight" ]]; then "$diff_highlight"; else cat; fi
}

function die() {
    color_print "$red" "$1" >&2
    exit 1
}

repo="$PWD"
# Files a merge couldn't settle, waiting for ./copy.sh --resolve. Gitignored.
conflicts_dir="$repo/.conflicts"
# What install last wrote (or copy last captured) per key; copy diffs $HOME
# against it so only local edits are carried into the repo.
snapshot_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/snapshot"
apps_installed="${snapshot_dir%/snapshot}/apps-installed.txt"

# Directories mirrored as a whole, so new files in them get picked up by copy.
# Profiles append their own in profile.sh.
managed_dirs=(
    home/.config/nvim
    home/.vim
    home/.claude/agents
    home/.codex/agents
)
# Files inside managed dirs that are local state, not configuration.
ignored_names=(.DS_Store lazy-lock.json .netrwhist nvim.log)
ignored_dirs=(home/.config/nvim/plugin home/.config/nvim/.nvim)

# npm settings that are credentials; they stay on the machine.
npmrc_secret_re='^[[:space:]]*//|_auth|_password'

# Where apps.txt finds apps; tests point it at a scratch folder.
apps_dir=${DOTFILES_APPS_DIR:-/Applications}

# Keys that Codex and other tools rewrite with machine state; install only
# writes them when missing.
seed_only_keys=(home/.codex/config.toml home/.t3/userdata/client-settings.json)

function load_profile() {
    # The environment wins over .env so a one-off run can target another profile.
    if [[ -z "${DOTFILES_PROFILE:-}" && -f .env ]]; then
        DOTFILES_PROFILE=$(sed -n 's/^DOTFILES_PROFILE=["'\'']\{0,1\}\([A-Za-z0-9_-]*\).*/\1/p' .env | tail -n 1)
    fi
    local profiles
    profiles=$(ls profiles | tr '\n' ' ')
    if [[ -z "${DOTFILES_PROFILE:-}" ]]; then
        die "DOTFILES_PROFILE is not set. Create $repo/.env containing DOTFILES_PROFILE=<profile> (one of: $profiles)"
    fi
    if [[ ! -d "profiles/$DOTFILES_PROFILE" ]]; then
        die "Unknown DOTFILES_PROFILE '$DOTFILES_PROFILE' (one of: $profiles)"
    fi
    profile_dir="profiles/$DOTFILES_PROFILE"
    if [[ -f "$profile_dir/profile.sh" ]]; then
        # shellcheck source=/dev/null
        source "$profile_dir/profile.sh"
    fi
}

function is_in() {
    local needle=$1 item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

function is_ignored() {
    local key=$1 dir
    is_in "$(basename "$key")" "${ignored_names[@]}" && return 0
    for dir in "${ignored_dirs[@]}"; do
        [[ "$key" == "$dir"/* ]] && return 0
    done
    return 1
}

# Every key the active profile manages, one per line.
function list_keys() {
    {
        (cd base && find home -type f)
        if [[ -d "$profile_dir/home" ]]; then
            (cd "$profile_dir" && find home -type f)
        fi
        echo Brewfile
        echo pnpm-globals.txt
        echo agent-skills.txt
        echo apps.txt
    } | while IFS= read -r key; do
        is_ignored "$key" || echo "$key"
    done | sort -u
}

# Where a key's whole-file source lives: the profile's copy, else base.
function source_of() {
    local key=$1
    if [[ -f "$profile_dir/$key" ]]; then
        echo "$profile_dir/$key"
    elif [[ -f "base/$key" ]]; then
        echo "base/$key"
    fi
}

# to_key <path>: accept a key or a path under $HOME (absolute, ~-less, or relative).
function to_key() {
    local path=${1#"$HOME"/}
    case "$path" in
        home/* | bots/* | Brewfile | pnpm-globals.txt | agent-skills.txt | apps.txt) echo "$path" ;;
        *) echo "home/$path" ;;
    esac
}

# display_name <key>: how a key reads in messages and prompts.
function display_name() {
    case "$1" in
        home/*) echo "~/${1#home/}" ;;
        *) echo "$1" ;;
    esac
}

function patch_of() {
    echo "$profile_dir/patches/$1.patch"
}

# apply_patch <patch> <key> <file>: apply in place. Fails without touching
# <file> when the patch's context no longer matches.
function apply_patch() {
    local patch=$1 key=$2 file=$3 dir
    dir=$(mktemp -d)
    mkdir -p "$dir/$(dirname "$key")"
    cat "$file" >"$dir/$key"
    if (cd "$dir" && git apply "$repo/$patch" 2>/dev/null); then
        if [[ -e "$dir/$key" ]]; then cat "$dir/$key" >"$file"; else rm -f "$file"; fi
        rm -rf "$dir"
        return 0
    fi
    rm -rf "$dir"
    return 1
}

# render <key> <out>: write the file the active profile should have. Fails
# (after saving the conflict to .conflicts/<key>) when base and the profile's
# patch can't be combined.
function render() {
    local key=$1 out=$2 src patch
    src=$(source_of "$key")
    if [[ -z "$src" ]]; then
        : >"$out"
        return 0
    fi
    cat "$src" >"$out"
    patch=$(patch_of "$key")
    [[ "$src" == base/* && -f "$patch" ]] || return 0
    apply_patch "$patch" "$key" "$out" && return 0
    merge_patch "$key" "$patch" "$out"
}

# Base changed under the patch. Rebuild the profile's file from the base the
# patch was made against (its blob id is on the patch's index line), then
# carry base's changes onto it with a 3-way merge.
function merge_patch() {
    local key=$1 patch=$2 out=$3 blob dir
    blob=$(sed -n 's/^index \([0-9a-f]*\)\.\..*/\1/p' "$patch" | head -n 1)
    if [[ -z "$blob" ]] || ! git cat-file -e "$blob" 2>/dev/null; then
        color_print "$red" "$patch no longer applies to base/$key, and the base it was made against isn't in git history. Write the file this profile should have to .conflicts/$key, then run ./copy.sh --resolve $key" >&2
        return 1
    fi
    dir=$(mktemp -d)
    git cat-file blob "$blob" >"$dir/old-base"
    cp "$dir/old-base" "$dir/old-profile"
    if ! apply_patch "$patch" "$key" "$dir/old-profile"; then
        rm -rf "$dir"
        color_print "$red" "$patch does not apply to its own base ($blob); fix the patch by hand." >&2
        return 1
    fi
    if [[ ! -e "$dir/old-profile" ]]; then
        rm -f "$out"
        rm -rf "$dir"
        return 0
    fi
    if ! git merge-file -p -L "$DOTFILES_PROFILE" -L "old base" -L "base" \
        "$dir/old-profile" "$dir/old-base" "base/$key" >"$out"; then
        mkdir -p "$(dirname "$conflicts_dir/$key")"
        cp "$out" "$conflicts_dir/$key"
        rm -rf "$dir"
        color_print "$red" "base/$key changed where $patch edits it. Fix the markers in .conflicts/$key (the file this profile should have), then run ./copy.sh --resolve $key" >&2
        return 1
    fi
    rm -rf "$dir"
}

# make_patch <key> <target>: store <target> as base/<key> plus a patch, or
# drop the patch when <target> equals base. A missing <target> makes a patch
# that deletes the file for this profile.
function make_patch() {
    local key=$1 target=$2 patch dir
    patch=$(patch_of "$key")
    dir=$(mktemp -d)
    mkdir -p "$dir/a/$(dirname "$key")" "$dir/b/$(dirname "$key")"
    cat "base/$key" >"$dir/a/$key"
    if [[ -e "$target" ]]; then
        cat "$target" >"$dir/b/$key"
        (cd "$dir" && git diff --no-index --no-prefix --full-index -- "a/$key" "b/$key") >"$dir/patch" || true
    else
        (cd "$dir" && git diff --no-index --no-prefix --full-index -- "a/$key" /dev/null) >"$dir/patch" || true
    fi
    if [[ -s "$dir/patch" ]]; then
        mkdir -p "$(dirname "$patch")"
        cat "$dir/patch" >"$patch"
    else
        rm -f "$patch"
    fi
    rm -rf "$dir"
}

# Codex keeps project trust, MCP servers, and UI state in its config; copy
# keeps only user settings.
function filter_codex_config() {
    awk '
    function normalized_header(line, header) {
      header = line
      sub(/^[[:space:]]*/, "", header)
      sub(/\][[:space:]]*#.*$/, "]", header)
      sub(/[[:space:]]*$/, "", header)
      return header
    }

    function is_header(line) {
      return line ~ /^[[:space:]]*\[\[[^]]+\]\][[:space:]]*(#.*)?$/ ||
        line ~ /^[[:space:]]*\[[^[][^]]*\][[:space:]]*(#.*)?$/
    }

    function is_dropped_section(line, header) {
      header = normalized_header(line)
      return header ~ /^\[projects\."/ ||
        header == "[notice]" ||
        header == "[tui.model_availability_nux]" ||
        header ~ /^\[marketplaces\./ ||
        header ~ /^\[\[?mcp_servers[[:space:]]*\.[[:space:]]*([A-Za-z0-9_-]+|"([^"\\]|\\.)*"|\047[^\047]*\047)[[:space:]]*\./
    }

    is_header($0) {
      section = normalized_header($0)
      drop_section = is_dropped_section($0)
      pending_environment = ""

      if (section == "[shell_environment_policy.set]") {
        pending_environment = $0 ORS
        next
      }

      if (!drop_section) {
        print
      }
      next
    }

    !drop_section &&
      !(section == "[shell_environment_policy.set]" &&
        $0 ~ /^[[:space:]]*NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S[[:space:]]*=/) {
      # Emit this table only when a retained environment override needs it.
      if (pending_environment != "") {
        pending_environment = pending_environment $0 ORS
        if ($0 ~ /^[[:space:]]*(#.*)?$/) {
          next
        }
        printf "%s", pending_environment
        pending_environment = ""
        next
      }
      print
    }
  '
}

# read_machine <key> <out>: the machine's current version of a key, in the
# form the repo stores. Fails when the machine doesn't have it.
function read_machine() {
    local key=$1 out=$2 path
    case "$key" in
        Brewfile)
            # npm globals come with the toolchain (node bundles corepack); the
            # ones that matter are in pnpm-globals.txt.
            brew bundle dump --file=- --no-npm >"$out"
            ;;
        pnpm-globals.txt)
            command -v pnpm >/dev/null || return 1
            # Run from ~ so a repo's pinned pnpm can't change the global dir.
            pnpm -C "$HOME" ls -g --json | jq -r '.[0].dependencies // {} | keys[]' >"$out"
            ;;
        agent-skills.txt)
            # The CLI's lock file can't restore global skills, so the repo keeps
            # a list instead: sections of an "agents ..." line (where the skills
            # below it install; with none the CLI installs into every agent it
            # knows) and one "<source> <skill>" line per skill, separated by
            # blank lines. Skills without a source (put there by another tool)
            # can't be reinstalled, so they're left out.
            command -v pnpx >/dev/null || return 1
            local skills lock rendered headers paths='{}'
            # The CLI's lock file follows XDG_STATE_HOME when set.
            lock="${XDG_STATE_HOME:+$XDG_STATE_HOME/skills/.skill-lock.json}"
            [[ -n "$lock" && -f "$lock" ]] || lock="$HOME/.agents/.skill-lock.json"
            if [[ -f "$lock" ]]; then paths=$(jq -c '.skills // {} | map_values(.skillPath // "")' "$lock"); fi
            # The agents lines belong to the repo: installing with explicit
            # agents doesn't record them anywhere. Fall back to the agents last
            # picked in the CLI.
            rendered=$(mktemp)
            if render agent-skills.txt "$rendered" 2>/dev/null && grep -q '^agents ' "$rendered"; then
                headers=$(sed -n 's/^agents //p' "$rendered")
            elif [[ -f "$lock" ]]; then
                headers=$(jq -r '(.lastSelectedAgents // []) | sort | join(" ")' "$lock")
            else
                headers=""
            fi
            rm -f "$rendered"
            # Adding from a repo's root finds only some of its skills (cursor/plugins
            # has a root skills/ dir that hides pstack/skills/), and the CLI keeps
            # the repo but not the subpath it was added from. So a GitHub source
            # gets the subpath back from the skill's path: everything before the
            # last skills/ dir, as in cursor/plugins/pstack.
            # The CLI lists a skill's agents by display name ("Claude Code"), so
            # they're matched to the agents lines' ids ("claude-code") by
            # lowercasing and hyphenating. A listed agent that no skill reaches
            # (not installed here) counts as reached, so skills stay in their
            # section. Sections keep the repo's order; new agent sets go last.
            skills_cli ls -g --json 2>/dev/null | jq -r --argjson paths "$paths" --arg headers "$headers" '
                ($headers | split("\n") | map(split(" ") | map(select(length > 0))) | map(select(length > 0))) as $order
                | ([$order[][]] | reduce .[] as $a ([]; if any(.[]; . == $a) then . else . + [$a] end)) as $want
                | map(select(.source) | .ids = ((.agents // []) | map(ascii_downcase | gsub(" "; "-"))))
                | ([.[].ids[]] | unique) as $present
                | map(
                    .ids as $ids
                    | (if any($want[]; IN($ids[])) then $want | map(select(IN($ids[]) or (IN($present[]) | not)))
                       elif $ids == [] then $want
                       else $ids end) as $set
                    | (($paths[.name] // "") | split("/") | .[:-2]) as $dir
                    | ($dir | indices("skills") | last) as $i
                    | (if .sourceType == "github" and $i != null and $i > 0 then "/" + ($dir[:$i] | join("/")) else "" end) as $sub
                    | {set: $set, key: ($set | sort), line: "\(.source)\($sub) \(.name)"})
                | . as $skills
                | ($order + ($skills | map(.set)))
                | reduce .[] as $h ([]; if any(.[]; sort == ($h | sort)) then . else . + [$h] end)
                | map(. as $h | ($h | sort) as $k
                    | [$skills[] | select(.key == $k) | .line] | sort
                    | select(length > 0) | ["agents " + ($h | join(" "))] + .)
                | if length == 0 then $order[:1] | map("agents " + join(" ")) else [map(join("\n")) | join("\n\n")] end
                | .[]' >"$out" || return 1
            ;;
        apps.txt)
            # Cask and App Store apps belong to the Brewfile; the rest were
            # installed by hand and update themselves. Cask apps are matched by
            # bundle or cask name, since pkg casks list no app.
            command -v brew >/dev/null || return 1
            local casks app name
            casks=$(brew info --cask --installed --json=v2 |
                jq -r '.casks[] | .name[], (.artifacts[] | objects | .app? // empty | .[] | strings | sub("\\.app$"; ""))') || return 1
            for app in "$apps_dir"/*.app; do
                name=$(basename "$app" .app)
                # Apple's apps there are symlinks (Safari); App Store apps carry a receipt.
                if [[ ! -d "$app" || -L "$app" || -d "$app/Contents/_MASReceipt" ]]; then continue; fi
                if ! grep -qxF "$name" <<<"$casks"; then echo "$name"; fi
            done | LC_ALL=C sort -u >"$out"
            ;;
        home/*)
            path="$HOME/${key#home/}"
            [[ -f "$path" ]] || return 1
            case "$key" in
                home/.codex/config.toml) filter_codex_config <"$path" >"$out" ;;
                # Credentials stay on the machine.
                home/.npmrc) grep -vE "$npmrc_secret_re" "$path" >"$out" || true ;;
                home/.docker/config.json)
                    jq 'if .auths then .auths |= map_values(del(.auth, .identitytoken, .registrytoken)) else . end' "$path" >"$out"
                    ;;
                # Claude Code rewrites this file in its own key order.
                home/.claude/settings.json) jq -S . "$path" >"$out" ;;
                # T3 Code writes every UI setting on one line, plus onboarding
                # and notification state.
                home/.t3/userdata/client-settings.json)
                    jq 'del(.onboardingCompletedAt, .dismissedProviderUpdateNotificationKeys)' "$path" >"$out"
                    ;;
                *) cat "$path" >"$out" ;;
            esac
            ;;
    esac
}

# Keys under managed dirs that exist on the machine but not in the repo.
function list_new_keys() {
    local dir rel
    for dir in "${managed_dirs[@]}"; do
        [[ -d "$HOME/${dir#home/}" ]] || continue
        (cd "$HOME" && find "${dir#home/}" -type f) | while IFS= read -r rel; do
            key="home/$rel"
            # if, not &&: a false last test would fail the pipeline under set -e.
            if ! is_ignored "$key" && [[ -z "$(source_of "$key")" ]]; then echo "$key"; fi
        done
    done
}

# The layer a new file in a managed dir belongs to.
function layer_of_dir() {
    local key=$1 dir
    for dir in "${managed_dirs[@]}"; do
        if [[ "$key" == "$dir"/* ]]; then
            # Shared if base has the directory, even when the profile keeps
            # some files of its own in it.
            if [[ -d "base/$dir" ]]; then echo base; else echo "$profile_dir"; fi
            return
        fi
    done
}

# skills_cli <args...>: the skills CLI, from ~ and without telemetry, as the
# skills-update-global alias in .zsh_aliases runs it.
# skill_entries <file>: one "<source> <skill> <agent>..." line per skill in an
# agent-skills.txt, with the agents of its section.
function skill_entries() {
    awk '$1 == "agents" { agents = ""; for (i = 2; i <= NF; i++) agents = agents " " $i; next }
        NF { print $1 " " $2 agents }' "$1"
}

function skills_cli() {
    (cd "$HOME" && env DISABLE_TELEMETRY=1 DO_NOT_TRACK=1 pnpx skills@latest "$@")
}

function snapshot_of() {
    if [[ "$1" == apps.txt ]]; then echo "$apps_installed"; else echo "$snapshot_dir/$1"; fi
}

function save_snapshot() {
    local path
    path=$(snapshot_of "$1")
    mkdir -p "$(dirname "$path")"
    cat "$2" >"$path"
}

# add_machine_secrets <key> <machine file> <file>: put back into <file> the
# credentials read_machine leaves out, taken from the machine's current file.
function add_machine_secrets() {
    local key=$1 machine=$2 file=$3
    [[ -f "$machine" ]] || return 0
    case "$key" in
        home/.npmrc)
            grep -E "$npmrc_secret_re" "$machine" >>"$file" || true
            ;;
        home/.docker/config.json)
            jq -s '.[0] * {auths: ((.[0].auths // {}) * (.[1].auths // {}))}' "$file" "$machine" >"$file.tmp"
            mv "$file.tmp" "$file"
            ;;
    esac
}

# Scratch repo whose index holds the repo version of each changed file and
# whose worktree holds the machine version. Each hunk answered y is applied to
# the index; whatever the index holds at the end goes to base.
function sort_init() {
    sort_repo="$work/sort"
    git init -q "$sort_repo"
    candidates=()
    new_files=()
    deleted_files=()
    # One line per file changed in the repo, for the summary at the end.
    copied=()
    sort_mode=ask
    keep_unmoved_patches=0
}

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

function stage_new() {
    mkdir -p "$sort_repo/$(dirname "$1")"
    cat "$2" >"$sort_repo/$1"
    git -C "$sort_repo" add -N -- "$1"
    new_files+=("$1")
}

function stage_deleted() {
    mkdir -p "$work/deleted/$(dirname "$1")"
    cat "$2" >"$work/deleted/$1"
    deleted_files+=("$1")
}

# show_lines <file>: print diff lines colored, with changed words marked.
function show_lines() {
    highlight_words <"$1" | awk -v plus="$(printf '%b' "$green")" -v minus="$(printf '%b' "$red")" \
        -v reset="$(printf '%b' "$default")" '
        /^\+/ { print plus $0 reset; next }
        /^-/ { print minus $0 reset; next }
        { print }
    '
}

# ask: read y, n, or q into $answer. Running out of input (the end of a piped
# answer list) counts as q, so nothing moves to base without an explicit y.
function ask() {
    local reply
    while true; do
        printf '%b' "Who gets this change?  ${bold}y${default} every profile (base)   ${bold}n${default} only $DOTFILES_PROFILE   ${bold}q${default} only $DOTFILES_PROFILE, and every change after it   ${bold}?${default} help\n> "
        if ! IFS= read -r reply; then
            echo
            answer=q
            answers_ran_out=1
            return
        fi
        case "$reply" in
            y | n | q) answer=$reply; return ;;
            '?' | h | help)
                echo "  y  move this change to base/, so every profile's install gets it"
                echo "  n  keep it in profiles/$DOTFILES_PROFILE/, so only this profile gets it"
                echo "  q  like n, for this change and every one after it (no more questions)"
                echo "  The change stays where it was made either way; the answer decides who else gets it."
                ;;
            *) echo "Answer y, n, or q (? for help)." ;;
        esac
    done
}

# tally <key> <where>: remember where a change went, for the summary.
function tally() {
    echo "$2" >>"$work/tally/$(echo "$1" | tr / %)"
}

function offer() {
    echo
    if [[ "$sort_mode" == list ]]; then
        echo "$(display_name "$1")   $2"
        cat "$work/lines"
        return 1
    fi
    echo -e "${cyan}${bold}$(display_name "$1")${default}   $2"
    show_lines "$work/lines"
    ask
}

# sort_changes: ask about every hunk of every changed file, then every new file,
# then every deleted file.
function sort_changes() {
    local key hunk total=0 i=0 quitting=0 line
    mkdir -p "$work/hunks" "$work/tally"
    : >"$work/delete-from-base"
    # One patch file per hunk (the file's diff header plus that hunk), numbered
    # in order, so a y can apply exactly that hunk to the index.
    for key in ${candidates[@]+"${candidates[@]}"}; do
        git -C "$sort_repo" diff --no-color --no-ext-diff -- "$key" | awk -v dir="$work/hunks" -v start="$total" -v key="$key" '
            /^@@/ { n++; file = sprintf("%s/%05d.patch", dir, start + n); printf "%s", header > file; print key > (file ".key") }
            n == 0 { header = header $0 "\n"; next }
            { print > file }
        '
        total=$(find "$work/hunks" -name '*.patch' | wc -l | tr -d ' ')
    done
    total=$((total + ${#new_files[@]} + ${#deleted_files[@]}))

    for hunk in "$work"/hunks/*.patch; do
        [[ -f "$hunk" ]] || continue
        i=$((i + 1))
        key=$(cat "$hunk.key")
        if ((quitting)) || [[ "$sort_mode" == keep ]]; then
            tally "$key" kept
            continue
        fi
        line=$(sed -n 's/^@@ -[0-9,]* +\([0-9]*\).*/\1/p' "$hunk" | head -n 1)
        sed -n '/^@@/,$p' "$hunk" | sed 1d >"$work/lines"
        offer "$key" "change $i of $total, near line $line" || continue
        case "$answer" in
            y)
                if git -C "$sort_repo" apply --cached "$hunk" 2>/dev/null; then
                    tally "$key" base
                else
                    color_print "$yellow" "Couldn't place this change apart from the ones before it; kept in $DOTFILES_PROFILE."
                    tally "$key" kept
                fi
                ;;
            q) quitting=1; tally "$key" kept ;;
            *) tally "$key" kept ;;
        esac
    done

    for key in ${new_files[@]+"${new_files[@]}"}; do
        i=$((i + 1))
        if ((quitting)) || [[ "$sort_mode" == keep ]]; then
            continue
        fi
        sed 's/^/+/' "$sort_repo/$key" >"$work/lines"
        offer "$key" "change $i of $total, new file" || continue
        case "$answer" in
            y) git -C "$sort_repo" add -- "$key" ;;
            q) quitting=1 ;;
        esac
    done

    for key in ${deleted_files[@]+"${deleted_files[@]}"}; do
        i=$((i + 1))
        if ((quitting)) || [[ "$sort_mode" == keep ]]; then
            continue
        fi
        sed 's/^/-/' "$work/deleted/$key" >"$work/lines"
        offer "$key" "change $i of $total, deleted file" || continue
        case "$answer" in
            y) echo "$key" >>"$work/delete-from-base" ;;
            q) quitting=1 ;;
        esac
    done
}

function patched_elsewhere() {
    local patch
    for patch in profiles/*/patches/"$1".patch; do
        [[ -f "$patch" && "$patch" != "$(patch_of "$1")" ]] || continue
        if ! grep -qx '+++ /dev/null' "$patch"; then echo "$patch" | cut -d/ -f2; fi
    done
}

function place_changes() {
    local key to_base kept other
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
        elif ((keep_unmoved_patches)); then
            # Nothing moved, so the patch stays byte for byte, even one made
            # against an older base that still renders.
            continue
        fi
        make_patch "$key" "$sort_repo/$key"
        to_base=$(grep -c '^base$' "$work/tally/$(echo "$key" | tr / %)" 2>/dev/null || true)
        kept=$(grep -c '^kept$' "$work/tally/$(echo "$key" | tr / %)" 2>/dev/null || true)
        copied+=("$(display_name "$key"): ${to_base:-0} to base, ${kept:-0} kept in $DOTFILES_PROFILE")
    done

    for key in ${new_files[@]+"${new_files[@]}"}; do
        git -C "$sort_repo" show ":$key" >"$work/staged"
        if [[ -s "$work/staged" ]]; then
            mkdir -p "$(dirname "base/$key")"
            cat "$work/staged" >"base/$key"
            if [[ "$key" == home/* && -x "$HOME/${key#home/}" ]]; then chmod +x "base/$key"; fi
            make_patch "$key" "$sort_repo/$key"
            copied+=("$(display_name "$key"): new file in base")
        else
            mkdir -p "$(dirname "$profile_dir/$key")"
            cat "$sort_repo/$key" >"$profile_dir/$key"
            if [[ "$key" == home/* && -x "$HOME/${key#home/}" ]]; then chmod +x "$profile_dir/$key"; fi
            copied+=("$(display_name "$key"): new file in $DOTFILES_PROFILE")
        fi
    done

    for key in ${deleted_files[@]+"${deleted_files[@]}"}; do
        other=""
        if grep -qxF -- "$key" "$work/delete-from-base"; then
            other=$(patched_elsewhere "$key" | paste -sd , -)
            if [[ -z "$other" ]]; then
                rm -f "base/$key" profiles/*/patches/"$key".patch
                copied+=("$(display_name "$key"): deleted from base")
                continue
            fi
            color_print "$yellow" "Kept base/$key: $other changes it, so it's deleted only in $DOTFILES_PROFILE."
        fi
        make_patch "$key" "$work/absent"
        copied+=("$(display_name "$key"): deleted in $DOTFILES_PROFILE only")
    done
}
