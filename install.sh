#!/usr/bin/env bash
# Set up this machine for the profile in .env (DOTFILES_PROFILE).
#
# Usage: ./install.sh [--apply] [--only files] [--show <path>]
#   (no flags)     dry run: show every change without making it
#   --apply        make the changes; overwritten files are backed up first
#   --only files   limit to config files (no brew, pnpm, macOS defaults, hooks)
#   --show <path>  print the rendered file for a home path or key and exit

set -euo pipefail
cd "$(dirname "$0")"
source ./utils.sh

apply=0
only=""
show=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) apply=1 ;;
        --only) [[ $# -ge 2 ]] || die "--only needs a value: files"; only=$2; shift ;;
        --show) [[ $# -ge 2 ]] || die "--show needs a path"; show=$2; shift ;;
        *) die "Unknown argument: $1 (see the usage at the top of install.sh)" ;;
    esac
    shift
done
[[ -z "$only" || "$only" == files ]] || die "--only supports: files"

load_profile

if [[ -n "$show" ]]; then
    key=$(to_key "$show")
    [[ -n "$(source_of "$key")" ]] || die "$key is not managed by profile $DOTFILES_PROFILE"
    out=$(mktemp)
    render "$key" "$out"
    cat "$out"
    rm -f "$out"
    exit 0
fi

if ((apply)); then
    color_print "$cyan" "Installing profile $DOTFILES_PROFILE"
else
    color_print "$cyan" "Dry run for profile $DOTFILES_PROFILE. Nothing changes until you pass --apply."
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# One row per step for the summary table: name, kind (ok, change, fail), text.
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
            *) color=$red ;;
        esac
        printf "%-20s ${color}%s${default}\n" "${summary_names[i]}" "${summary_texts[i]}"
    done
    echo
}

# run <description> <command...>: run it, or only describe it in a dry run.
function run() {
    local description=$1
    shift
    if ((apply)); then
        "$@"
    else
        color_print "$blue" "Would run: $description"
    fi
}

backup="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
function backup_file() {
    local path=$1 rel=${1#"$HOME"/}
    [[ -e "$path" || -L "$path" ]] || return 0
    mkdir -p "$backup/$(dirname "$rel")"
    cp -a "$path" "$backup/$rel"
}

# Mark the changed words inside changed lines with git's diff-highlight
# (brew's git ships it; Workbrew uses the same prefix). A fresh Mac doesn't
# have it yet, so plain line diffs pass through.
diff_highlight=$(command -v diff-highlight ||
    ls "${HOMEBREW_PREFIX:-/opt/homebrew}/share/git-core/contrib/diff-highlight/diff-highlight" 2>/dev/null || true)
function highlight_words() {
    if [[ -n "$diff_highlight" ]]; then "$diff_highlight"; else cat; fi
}

function install_files() {
    local key path rendered machine="$work/machine" has_machine changed=0
    local n_change=0 n_create=0 n_link=0 n_kept=0
    while IFS= read -r key; do
        [[ "$key" == home/* ]] || continue
        path="$HOME/${key#home/}"
        rendered="$work/rendered"
        render "$key" "$rendered" </dev/null

        # Compare in the form the repo stores (sorted JSON, no auth lines, ...)
        # so formatting the tools apply on their own doesn't count as a change.
        has_machine=0
        read_machine "$key" "$machine" </dev/null 2>/dev/null && has_machine=1
        if ((has_machine)) && [[ ! -L "$path" ]] && cmp -s "$rendered" "$machine"; then
            ((apply)) && save_snapshot "$key" "$rendered"
            continue
        fi
        if is_in "$key" "${seed_only_keys[@]}" && [[ -e "$path" ]]; then
            n_kept=$((n_kept + 1))
            file_header "~/${key#home/}" "kept: only written when missing; merge by hand if needed"
            echo
            ((apply)) && save_snapshot "$key" "$rendered"
            continue
        fi

        changed=1
        if [[ -L "$path" ]]; then
            n_link=$((n_link + 1))
        elif ((has_machine)); then
            n_change=$((n_change + 1))
        else
            n_create=$((n_create + 1))
        fi
        if ((apply)); then
            backup_file "$path"
            # gpg rejects a ~/.gnupg readable by others.
            if [[ "$key" == home/.gnupg/* ]]; then mkdir -p -m 700 "$HOME/.gnupg"; fi
            mkdir -p "$(dirname "$path")"
            cp "$rendered" "$work/final"
            # Credentials stay on the machine; the repo copy leaves them out.
            if [[ ! -L "$path" ]]; then add_machine_secrets "$key" "$path" "$work/final"; fi
            # Replace symlinks instead of writing through them (an old
            # ~/.claude/CLAUDE.md pointed at ~/.codex/AGENTS.md).
            if [[ -L "$path" ]]; then rm "$path"; fi
            cat "$work/final" >"$path" # in place, so an existing file keeps its permissions
            if [[ -x "$(source_of "$key")" ]]; then chmod +x "$path"; fi
            save_snapshot "$key" "$rendered"
            echo -e "${green}Wrote ~/${key#home/}${default}"
        elif [[ -L "$path" ]]; then
            file_header "~/${key#home/}" "symlink to $(readlink "$path"); would become this file:"
            sed 's/^/    /' "$rendered"
            echo
        elif ((has_machine)); then
            file_header "~/${key#home/}" "would change:"
            # Drop git's diff/index/---/+++ lines; the header above names the file.
            git --no-pager diff --no-index --color -- "$machine" "$rendered" | highlight_words |
                awk 'body; /\+\+\+ /{body=1}' || true
            echo
        else
            file_header "~/${key#home/}" "would be created"
            echo
        fi
    done < <(list_keys)

    if ((changed == 0)); then
        color_print "$green" 'Config files already match the repo'
    elif ((apply)) && [[ -d "$backup" ]]; then
        echo
        color_print "$green" "Previous versions are in $backup"
    fi

    local parts=() verb=""
    ((apply)) || verb="to "
    ((n_change)) && parts+=("$n_change ${verb}change")
    ((n_create)) && parts+=("$n_create ${verb}create")
    ((n_link)) && parts+=("$n_link symlink ${verb}replace")
    if ((apply)); then
        parts=()
        ((n_change + n_create + n_link)) && parts+=("wrote $((n_change + n_create + n_link))")
    fi
    ((n_kept)) && parts+=("$n_kept kept as is")
    if ((${#parts[@]} == 0)); then
        record 'Config files' ok 'up to date'
    else
        local text
        text=$(printf '%s, ' "${parts[@]}")
        if ((n_change + n_create + n_link)); then
            record 'Config files' change "${text%, }"
        else
            record 'Config files' ok "${text%, }"
        fi
    fi
}

function install_brewfile() {
    local brewfile="$work/Brewfile"
    render Brewfile "$brewfile"
    if ((apply)); then
        # Some entries (e.g. vscode extensions without the `code` CLI) can fail
        # on a fresh machine; report and keep going.
        if brew bundle install --file="$brewfile"; then
            color_print "$green" 'Installed Brewfile packages'
            record 'Homebrew packages' ok 'installed'
        else
            color_print "$yellow" 'Some Brewfile entries failed; see the output above'
            record 'Homebrew packages' fail 'some entries failed'
        fi
        save_snapshot Brewfile "$brewfile"
    elif brew bundle check --file="$brewfile" --no-upgrade >/dev/null 2>&1; then
        color_print "$green" 'Brewfile packages are all installed'
        record 'Homebrew packages' ok 'all installed'
    else
        local missing
        missing=$(brew bundle check --file="$brewfile" --no-upgrade --verbose 2>&1 | grep -E '^→' || true)
        color_print "$blue" 'Would install these Brewfile entries:'
        echo "$missing"
        echo
        record 'Homebrew packages' change "$(echo "$missing" | grep -c .) to install"
    fi
}

function install_pnpm_globals() {
    local list="$work/pnpm-globals.txt" installed="$work/pnpm-installed" missing
    render pnpm-globals.txt "$list"
    if [[ ! -s "$list" ]]; then
        color_print "$green" 'No pnpm globals for this profile'
        record 'pnpm globals' ok 'none for this profile'
        return 0
    fi
    if ! command -v pnpm >/dev/null; then
        color_print "$yellow" 'pnpm is not on PATH; skipped pnpm globals'
        record 'pnpm globals' fail 'skipped: pnpm not on PATH'
        return 0
    fi
    read_machine pnpm-globals.txt "$installed" || : >"$installed"
    missing=$(grep -vxFf "$installed" "$list" || true)
    if [[ -z "$missing" ]]; then
        color_print "$green" 'pnpm globals are all installed'
        record 'pnpm globals' ok 'all installed'
    elif ((apply)); then
        # Run from ~ so no repo pin applies.
        (cd "$HOME" && echo "$missing" | xargs pnpm add -g)
        color_print "$green" 'Installed pnpm globals'
        record 'pnpm globals' ok "installed $(echo "$missing" | grep -c .)"
    else
        color_print "$blue" "Would install pnpm globals: $(echo "$missing" | tr '\n' ' ')"
        record 'pnpm globals' change "$(echo "$missing" | grep -c .) to install"
    fi
    ((apply)) && save_snapshot pnpm-globals.txt "$list"
    return 0
}

function install_touch_id() {
    if grep -qs '^auth.*pam_tid\.so' /etc/pam.d/sudo_local; then
        color_print "$green" 'Touch ID for sudo is already configured'
        record 'Touch ID for sudo' ok 'already on'
    elif ((apply)); then
        sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
        color_print "$green" 'Configured Touch ID for sudo'
        record 'Touch ID for sudo' ok 'enabled'
    else
        color_print "$blue" 'Would enable Touch ID for sudo (/etc/pam.d/sudo_local)'
        record 'Touch ID for sudo' change 'to enable'
    fi
}

function install_terminal_profile() {
    if [[ "$(defaults read com.apple.Terminal 'Default Window Settings' 2>/dev/null)" == Basic ]]; then
        color_print "$green" 'Basic Terminal profile is already the default'
        record 'Terminal profile' ok 'Basic is the default'
        return 0
    fi
    if ((apply)); then
        record 'Terminal profile' ok 'imported Basic'
    else
        record 'Terminal profile' change 'to import Basic'
    fi
    # Opening the file imports the profile (and opens a window).
    run 'import base/Basic.terminal and make it the default Terminal profile' \
        sh -c 'open base/Basic.terminal &&
            defaults write com.apple.Terminal "Default Window Settings" -string Basic &&
            defaults write com.apple.Terminal "Startup Window Settings" -string Basic'
}

if [[ "$only" == files ]]; then
    section 'Config files'
    install_files
    section 'Summary'
    print_summary
    exit 0
fi

# The profile puts the right brew on PATH (Homebrew or Workbrew).
profile_brew
section 'Touch ID for sudo'
install_touch_id
section 'Homebrew packages'
install_brewfile
section 'Config files'
install_files
if declare -F profile_install >/dev/null; then
    section "Profile steps ($DOTFILES_PROFILE)"
    profile_install
    if ((apply)); then record 'Profile steps' ok 'ran'; else record 'Profile steps' change 'to run (see above)'; fi
fi
section 'pnpm globals'
install_pnpm_globals
section 'Terminal profile'
install_terminal_profile
section 'macOS defaults'
# shellcheck source=set_defaults.sh
source ./set_defaults.sh

section 'Summary'
print_summary
if ((apply)); then
    color_print "$green" "Done. Some macOS defaults need a logout or restart to take effect."
    if declare -F profile_manual_steps >/dev/null; then profile_manual_steps; fi
else
    color_print "$cyan" 'Dry run finished. Run ./install.sh --apply to make these changes.'
fi
