#!/usr/bin/env bash
# Set up this machine for the profile in .env (DOTFILES_PROFILE).
#
# Usage: ./install.sh [-a | --apply] [--only files] [--show <path>]
#   (no flags)     dry run: show every change without making it
#   -a, --apply    make the changes; overwritten files are backed up first
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
        -a | --apply) apply=1 ;;
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
    local brewfile="$work/Brewfile" missing
    render Brewfile "$brewfile"
    if brew bundle check --file="$brewfile" --no-upgrade >/dev/null 2>&1; then
        color_print "$green" 'Brewfile packages are all installed'
        record 'Homebrew packages' ok 'all installed'
    else
        missing=$(brew bundle check --file="$brewfile" --no-upgrade --verbose 2>&1 | grep -E '^→' || true)
        if ((apply)); then
            # Install only what's missing; upgrading is upgrade.sh's job. Some
            # entries (e.g. vscode extensions without the `code` CLI) can fail
            # on a fresh machine; report and keep going.
            if brew bundle install --file="$brewfile" --no-upgrade; then
                color_print "$green" 'Installed missing Brewfile packages'
                record 'Homebrew packages' ok "installed $(echo "$missing" | grep -c .)"
            else
                color_print "$yellow" 'Some Brewfile entries failed; see the output above'
                record 'Homebrew packages' fail 'some entries failed'
            fi
        else
            color_print "$blue" 'Would install these Brewfile entries:'
            echo "$missing"
            echo
            record 'Homebrew packages' change "$(echo "$missing" | grep -c .) to install"
        fi
    fi
    # Reads the snapshot of the previous install, so it runs before saving the new one.
    remove_unlisted_packages "$brewfile"
    if ((apply)); then save_snapshot Brewfile "$brewfile"; fi
}

# Brewfile entries as "type name" (tap, brew, cask, vscode), ignoring options.
function brewfile_entries() {
    # -E: BSD sed (a fresh Mac) has no \| in basic regexes.
    sed -nE 's/^(tap|brew|cask|vscode) "([^"]*)".*/\1 \2/p' "$1"
}

# Uninstall packages the Brewfile no longer lists. Packages installed on this
# machine since the last install were never in the repo, so they're reported
# (copy them, or uninstall them by hand) instead of removed. With no previous
# install to compare against, every unlisted package is a removal; the dry run
# lists them first.
function remove_unlisted_packages() {
    local brewfile=$1 snapshot="$snapshot_dir/Brewfile" extras entry type name
    local remove local_only
    remove=()
    local_only=()
    # Dry run by default: lists installed packages the Brewfile doesn't need,
    # leaving out dependencies of listed ones. It exits non-zero when it finds
    # any, hence the || true under pipefail.
    extras=$({ brew bundle cleanup --file="$brewfile" --formula --cask --tap --vscode 2>/dev/null || true; } | awk '
        /^Would uninstall formulae:/ { type = "brew"; next }
        /^Would uninstall casks:/ { type = "cask"; next }
        /^Would untap:/ { type = "tap"; next }
        /^Would uninstall VSCode extensions:/ { type = "vscode"; next }
        /^(Would|Run) / { type = ""; next }
        type != "" && NF { print type, $1 }
    ')
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        if [[ -f "$snapshot" ]] && ! brewfile_entries "$snapshot" | grep -qxF "$entry"; then
            local_only+=("$entry")
        else
            remove+=("$entry")
        fi
    done <<<"$extras"

    if ((${#local_only[@]})); then
        color_print "$yellow" "Installed here but not in the repo; run ./copy.sh to keep them, or uninstall them by hand:
$(printf '  %s\n' "${local_only[@]}")"
        record 'Local packages' info "${#local_only[@]} not in the repo (see above)"
    fi
    if ((${#remove[@]} == 0)); then
        return 0
    fi
    if ((apply)); then
        # Formulae and casks first, so their taps are unused when untapped.
        for type in brew cask vscode tap; do
            for entry in "${remove[@]}"; do
                [[ "${entry%% *}" == "$type" ]] || continue
                name=${entry#* }
                case "$type" in
                    brew) brew uninstall "$name" ;;
                    cask) brew uninstall --cask "$name" ;;
                    vscode) code --uninstall-extension "$name" ;;
                    tap) brew untap "$name" ;;
                esac
            done
        done
        color_print "$green" "Uninstalled packages the Brewfile no longer lists: $(printf '%s, ' "${remove[@]}" | sed 's/, $//')"
        record 'Homebrew removals' ok "removed ${#remove[@]}"
    else
        color_print "$blue" "Would uninstall these packages the Brewfile no longer lists:
$(printf '  %s\n' "${remove[@]}")"
        record 'Homebrew removals' change "${#remove[@]} to remove"
    fi
}

function install_pnpm_globals() {
    local list="$work/pnpm-globals.txt" installed="$work/pnpm-installed" missing
    render pnpm-globals.txt "$list"
    if [[ ! -s "$list" ]]; then
        color_print "$green" 'No pnpm globals for this profile'
        record 'pnpm globals' ok 'none for this profile'
        # Still record it, so copy can pick up globals added later.
        if ((apply)); then save_snapshot pnpm-globals.txt "$list"; fi
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

# Add skills the list has and this machine lacks, and remove skills the list
# dropped since the previous install. As with Homebrew, skills added on this
# machine since then are only reported; with no previous install, unlisted
# skills are only reported too, because the repo has no record of them yet.
function install_agent_skills() {
    local list="$work/agent-skills.txt" installed="$work/skills-installed" snapshot="$snapshot_dir/agent-skills.txt"
    local agents missing extra entry source name
    local add_args remove_names local_only
    render agent-skills.txt "$list"
    if ! grep -qv '^agents ' "$list"; then
        color_print "$green" 'No agent skills for this profile'
        record 'Agent skills' ok 'none for this profile'
        if ((apply)); then save_snapshot agent-skills.txt "$list"; fi
        return 0
    fi
    if ! command -v pnpx >/dev/null; then
        color_print "$yellow" 'pnpx is not on PATH; skipped agent skills'
        record 'Agent skills' fail 'skipped: pnpx not on PATH'
        return 0
    fi
    agents=$(sed -n 's/^agents //p' "$list")
    if [[ -z "$agents" ]]; then
        color_print "$red" 'agent-skills.txt has no "agents ..." line; skipped (the CLI would install into every agent it knows)'
        record 'Agent skills' fail 'skipped: no agents line'
        return 0
    fi
    read_machine agent-skills.txt "$installed" || : >"$installed"
    missing=$(grep -v '^agents ' "$list" | grep -vxFf <(grep -v '^agents ' "$installed") || true)
    extra=$(grep -v '^agents ' "$installed" | grep -vxFf <(grep -v '^agents ' "$list") || true)

    remove_names=()
    local_only=()
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        if [[ -f "$snapshot" ]] && grep -qxF "$entry" "$snapshot"; then
            remove_names+=("${entry#* }")
        else
            local_only+=("$entry")
        fi
    done <<<"$extra"
    if ((${#local_only[@]})); then
        color_print "$yellow" "Installed here but not in the repo; run ./copy.sh to keep them, or remove them by hand:
$(printf '  %s\n' "${local_only[@]}")"
        record 'Local skills' info "${#local_only[@]} not in the repo (see above)"
    fi

    if [[ -z "$missing" && ${#remove_names[@]} -eq 0 ]]; then
        color_print "$green" 'Agent skills are all installed'
        record 'Agent skills' ok 'all installed'
    elif ((apply)); then
        # One add per source repo, with every missing skill from it.
        for source in $(echo "$missing" | awk 'NF { print $1 }' | sort -u); do
            add_args=()
            for name in $(echo "$missing" | awk -v s="$source" '$1 == s { print $2 }'); do
                add_args+=(-s "$name")
            done
            for name in $agents; do
                add_args+=(-a "$name")
            done
            skills_cli add "$source" -g "${add_args[@]}" -y </dev/null
        done
        if ((${#remove_names[@]})); then
            skills_cli remove "${remove_names[@]}" -g -y </dev/null
        fi
        color_print "$green" "Agent skills: added $(count_lines "$missing"), removed ${#remove_names[@]}"
        record 'Agent skills' ok "added $(count_lines "$missing"), removed ${#remove_names[@]}"
    else
        if [[ -n "$missing" ]]; then
            color_print "$blue" "Would add these skills (for agents: $agents):
$(echo "$missing" | sed 's/^/  /')"
        fi
        if ((${#remove_names[@]})); then
            color_print "$blue" "Would remove these skills the list no longer has:
$(printf '  %s\n' "${remove_names[@]}")"
        fi
        record 'Agent skills' change "$(count_lines "$missing") to add, ${#remove_names[@]} to remove"
    fi
    if ((apply)); then save_snapshot agent-skills.txt "$list"; fi
}

# count_lines <text>: number of non-empty lines.
function count_lines() {
    if [[ -z "$1" ]]; then echo 0; else echo "$1" | grep -c .; fi
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

# The profile puts its brew (Homebrew or Workbrew) and toolchain on PATH.
profile_path
section 'Touch ID for sudo'
install_touch_id
section 'Homebrew packages'
install_brewfile
section 'Config files'
install_files
if declare -F profile_install >/dev/null; then
    section "Profile steps ($DOTFILES_PROFILE)"
    profile_install
fi
section 'pnpm globals'
install_pnpm_globals
section 'Agent skills'
install_agent_skills
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
    if is_in change ${summary_kinds[@]+"${summary_kinds[@]}"}; then
        color_print "$cyan" 'Dry run finished. Run ./install.sh --apply to make these changes.'
    else
        color_print "$green" 'Dry run finished. Nothing to change.'
    fi
fi
