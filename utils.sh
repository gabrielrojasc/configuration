# shellcheck shell=bash
# Shared helpers for install.sh and copy.sh. Sourced from the repo root.
#
# A "key" is a path relative to a layer root (base/ or profiles/<name>/):
#   home/<path>       a file that lives at $HOME/<path>
#   Brewfile          installed with brew bundle, read back with brew bundle dump
#   pnpm-globals.txt  installed with pnpm add -g, read back with pnpm ls -g
# A key renders from the profile's own copy if it has one, otherwise from
# base plus the profile's patches/<key>.patch when that exists.

# Format helpers for color_print
green="\033[0;32m"
blue="\033[0;34m"
cyan="\033[0;36m"
yellow="\033[0;33m"
red="\033[0;31m"
default="\033[0m"

function color_print() {
    local color=$1
    local message=$2

    echo -e "${color}${message}${default}\n"
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

# Directories mirrored as a whole, so new files in them get picked up by copy.
# Profiles append their own in profile.sh.
managed_dirs=(
    home/.config/nvim
    home/.vim
    home/.claude/agents
    home/.codex/agents
)
# Files inside managed dirs that are local state, not configuration.
ignored_names=(.DS_Store lazy-lock.json .netrwhist)
ignored_dirs=(home/.config/nvim/plugin home/.config/nvim/.nvim)

# npm settings that are credentials; they stay on the machine.
npmrc_secret_re='^[[:space:]]*//|_auth|_password'

# Keys that Codex and other tools rewrite with machine state; install only
# writes them when missing.
seed_only_keys=(home/.codex/config.toml)

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
        home/* | Brewfile | pnpm-globals.txt) echo "$path" ;;
        *) echo "home/$path" ;;
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
        cat "$dir/$key" >"$file"
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
# drop the patch when <target> equals base.
function make_patch() {
    local key=$1 target=$2 patch dir
    patch=$(patch_of "$key")
    dir=$(mktemp -d)
    mkdir -p "$dir/a/$(dirname "$key")" "$dir/b/$(dirname "$key")"
    cat "base/$key" >"$dir/a/$key"
    cat "$target" >"$dir/b/$key"
    (cd "$dir" && git diff --no-index --no-prefix --full-index -- "a/$key" "b/$key") >"$dir/patch" || true
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
            brew bundle dump --file=- >"$out"
            ;;
        pnpm-globals.txt)
            command -v pnpm >/dev/null || return 1
            # Run from ~ so a repo's pinned pnpm can't change the global dir.
            pnpm -C "$HOME" ls -g --json | jq -r '.[0].dependencies // {} | keys[]' >"$out"
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

function save_snapshot() {
    local key=$1 file=$2
    mkdir -p "$(dirname "$snapshot_dir/$key")"
    cat "$file" >"$snapshot_dir/$key"
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
