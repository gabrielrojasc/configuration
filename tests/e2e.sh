#!/usr/bin/env bash
# End-to-end check of install.sh and copy.sh for every profile, using a
# throwaway copy of this repo and a throwaway $HOME. Touches neither.
#
# Usage: tests/e2e.sh [log-dir]   (default: ~/tmp/dotfiles-e2e/<timestamp>)
# Only config files are exercised (--only files): brew, pnpm, and macOS
# defaults act on the real machine regardless of $HOME.

set -euo pipefail
# The scripts read these; values from the calling shell must not leak in.
unset DOTFILES_PROFILE XDG_STATE_HOME DOTFILES_APPS_DIR
src="$(cd "$(dirname "$0")/.." && pwd)"
log_dir="${1:-$HOME/tmp/dotfiles-e2e/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$log_dir"
log="$log_dir/e2e.log"
exec > >(tee "$log") 2>&1
echo "# Reproduce: $src/tests/e2e.sh $log_dir"
dirty=""
[[ -z "$(git -C "$src" status --porcelain)" ]] || dirty=" plus uncommitted changes"
echo "# Repo: $(git -C "$src" rev-parse --short HEAD)$dirty"
echo

failures=0
function check() {
    local name=$1
    shift
    if "$@"; then
        echo "PASS  $name"
    else
        echo "FAIL  $name"
        failures=$((failures + 1))
    fi
}

# fresh <profile>: new repo copy ($repo) and empty $HOME ($home) for <profile>.
function fresh() {
    local root
    root=$(mktemp -d)
    repo="$root/repo"
    home="$root/home"
    mkdir -p "$home"
    rsync -a --exclude .env --exclude .conflicts "$src/" "$repo/"
    # Commit so patches' base blobs are in history, as they are after a real commit.
    git -C "$repo" add -A
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -q --no-gpg-sign --allow-empty -m e2e
    echo "DOTFILES_PROFILE=$1" >"$repo/.env"
}

function in_repo() { (cd "$repo" && HOME="$home" XDG_STATE_HOME="$home/.local/state" "$@"); }
function repo_clean() { [[ -z "$(git -C "$repo" status --porcelain)" ]]; }
function show_status() { git -C "$repo" status --short; }

for profile in $(ls "$src/profiles"); do
    echo "== $profile"

    fresh "$profile"
    rm "$repo/.env"
    check "fails without .env" bash -c "! (cd '$repo' && HOME='$home' ./install.sh --only files) 2>/dev/null"
    check "fails on unknown profile" bash -c "! (cd '$repo' && DOTFILES_PROFILE=nope HOME='$home' ./install.sh --only files) 2>/dev/null"

    fresh "$profile"
    # An old setup linked CLAUDE.md to AGENTS.md; install must not write through it.
    mkdir -p "$home/.claude" "$home/.codex"
    echo "keep me" >"$home/.codex/AGENTS.md.orig"
    cp "$home/.codex/AGENTS.md.orig" "$home/.codex/AGENTS.md"
    ln -s "$home/.codex/AGENTS.md" "$home/.claude/CLAUDE.md"
    in_repo ./install.sh --only files >"$log_dir/$profile-dry-run.txt"
    check "dry run writes nothing" test ! -e "$home/.zshrc"
    in_repo ./install.sh --only files --apply >"$log_dir/$profile-install.txt"
    check "install replaces the CLAUDE.md symlink" test ! -L "$home/.claude/CLAUDE.md"
    check "install renders AGENTS.md from the repo, not via the symlink" \
        bash -c "cmp -s '$home/.codex/AGENTS.md' <(cd '$repo' && HOME='$home' ./install.sh --show .codex/AGENTS.md)"
    check "every managed file is installed" bash -c "
        cd '$repo' && source ./utils.sh && DOTFILES_PROFILE=$profile load_profile >/dev/null
        list_keys | grep '^home/' | while read -r k; do [[ -f '$home'/\${k#home/} ]] || { echo missing \$k; exit 1; }; done"

    in_repo ./copy.sh --only files --no-sort >"$log_dir/$profile-copy-roundtrip.txt"
    check "install then copy leaves the repo unchanged" repo_clean || show_status

    # A local edit lands in the profile's patch, not in base.
    echo "alias e2e-local='true'" >>"$home/.zsh_aliases"
    in_repo ./copy.sh --only files --no-sort >/dev/null
    check "local edit goes to the profile patch" bash -c "grep -q e2e-local '$repo/profiles/$profile/patches/home/.zsh_aliases.patch' && ! grep -q e2e-local '$repo/base/home/.zsh_aliases'"
    check "render matches the machine after copy" bash -c "cmp -s '$home/.zsh_aliases' <(cd '$repo' && HOME='$home' ./install.sh --show .zsh_aliases)"

    # A second edit, answered y in the sort prompt, goes to base instead.
    sed -i.bak "s/^alias l='ls -C'\$/&\\
alias e2e-shared='true'/" "$home/.zsh_aliases" && rm "$home/.zsh_aliases.bak"
    printf 'y\n' | in_repo ./copy.sh --only files >/dev/null
    check "sort y moves the new hunk to base" grep -q e2e-shared "$repo/base/home/.zsh_aliases"
    check "sort y leaves it out of the patch" bash -c "! grep -q e2e-shared '$repo/profiles/$profile/patches/home/.zsh_aliases.patch'"
    check "the earlier local edit stays in the patch" grep -q e2e-local "$repo/profiles/$profile/patches/home/.zsh_aliases.patch"
    check "render matches the machine after sorting" bash -c "cmp -s '$home/.zsh_aliases' <(cd '$repo' && HOME='$home' ./install.sh --show .zsh_aliases)"

    # A y next to a profile-only line can't move to base; it stays in the patch.
    echo "alias e2e-adjacent='true'" >>"$home/.zsh_aliases"
    printf 'y\n' | in_repo ./copy.sh --only files >/dev/null
    check "adjacent y stays out of base" bash -c "! grep -q e2e-adjacent '$repo/base/home/.zsh_aliases'"
    check "adjacent y is kept in the patch" grep -q e2e-adjacent "$repo/profiles/$profile/patches/home/.zsh_aliases.patch"
    git -C "$repo" add -A
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -q --no-gpg-sign -m sorted
    printf 'q\n' | in_repo ./copy.sh --sort >/dev/null
    check "copy --sort with q changes nothing" repo_clean || show_status

    # Another machine changes base; this one hasn't installed it yet but has
    # its own edit. Copy must keep both and not "remove" the other change.
    fresh "$profile"
    in_repo ./install.sh --only files --apply >/dev/null
    printf '# from-other-machine\n' >>"$repo/base/home/.tmux.conf"
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -qam other-machine --no-gpg-sign
    { echo '# local-edit'; cat "$home/.tmux.conf"; } >"$home/.tmux.conf.new" && mv "$home/.tmux.conf.new" "$home/.tmux.conf"
    in_repo ./copy.sh --only files --no-sort >/dev/null
    rendered=$(cd "$repo" && HOME="$home" ./install.sh --show .tmux.conf)
    check "stale copy keeps the other machine's change" grep -q from-other-machine <<<"$rendered"
    check "stale copy keeps the local edit" grep -q local-edit <<<"$rendered"

    # Both machines edit the same spot: copy reports a conflict, changes nothing.
    git -C "$repo" add -A
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -q --no-gpg-sign -m stale
    in_repo ./install.sh --only files --apply >/dev/null
    printf '# repo-side\n' >>"$repo/base/home/.vimrc"
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -qam repo-side --no-gpg-sign
    printf '# machine-side\n' >>"$home/.vimrc"
    in_repo ./copy.sh --only files --no-sort >/dev/null
    check "overlapping edits are reported in .conflicts" test -f "$repo/.conflicts/home/.vimrc"
    check "overlapping edits leave the repo file alone" bash -c "! grep -q machine-side '$repo/base/home/.vimrc'"

    # Base edits a line inside a patch hunk's context: git apply refuses, and
    # render falls back to a 3-way merge with the base the patch was made on.
    fresh "$profile"
    sed -i.bak '6s/# for gnu-sed/# for gnu-sed (e2e)/' "$repo/base/home/.zshrc" && rm "$repo/base/home/.zshrc.bak"
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -qam base-moved --no-gpg-sign
    rendered=$(cd "$repo" && HOME="$home" ./install.sh --show .zshrc)
    check "3-way render keeps the base edit" grep -q 'gnu-sed (e2e)' <<<"$rendered"
    # Each profile's first .zshrc hunk adds a PATH line two lines below line 6.
    check "3-way render keeps the profile patch" grep -qE '\.docker/bin|\.local/bin' <<<"$rendered"

    # Base and patch edit the same lines: render stops, saves a conflict file,
    # and --resolve stores the fixed file as the profile's version.
    fresh "$profile"
    in_repo ./install.sh --only files --apply >/dev/null
    sed -i.bak '8s/$/ # e2e-conflict/' "$repo/base/home/.zshrc" && rm "$repo/base/home/.zshrc.bak"
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -qam base-conflict --no-gpg-sign
    echo "alias e2e-unrelated='true'" >>"$home/.zsh_aliases"
    in_repo ./copy.sh --only files --no-sort >"$log_dir/$profile-copy-conflict.txt" 2>&1 || true
    check "render conflict is saved to .conflicts" test -f "$repo/.conflicts/home/.zshrc"
    check "other files are still copied past a conflict" grep -q e2e-unrelated "$repo/profiles/$profile/patches/home/.zsh_aliases.patch"
    check "install stops on the conflict" bash -c "! (cd '$repo' && HOME='$home' ./install.sh --show .zshrc) >/dev/null 2>&1"
    # Resolve by keeping both sides.
    grep -vE '^(<<<<<<<|=======|>>>>>>>)( |$)' "$repo/.conflicts/home/.zshrc" >"$repo/.conflicts/home/.zshrc.fixed"
    mv "$repo/.conflicts/home/.zshrc.fixed" "$repo/.conflicts/home/.zshrc"
    in_repo ./copy.sh --resolve .zshrc >/dev/null
    check "--resolve clears the conflict" test ! -e "$repo/.conflicts/home/.zshrc"
    check "render works after --resolve" bash -c "(cd '$repo' && HOME='$home' ./install.sh --show .zshrc) | grep -q e2e-conflict"

    # Copy skips files this machine never installed instead of reverting them.
    fresh "$profile"
    echo "alias e2e-preinstall='true'" >"$home/.zsh_aliases"
    in_repo ./copy.sh --only files --no-sort >"$log_dir/$profile-copy-before-install.txt"
    check "copy before install changes nothing" repo_clean || show_status
    check "copy before install says why" grep -q 'Not compared' "$log_dir/$profile-copy-before-install.txt"

    # A new file in a shared directory: n keeps it in the profile, y puts it in base.
    fresh "$profile"
    in_repo ./install.sh --only files --apply >/dev/null
    echo "# e2e agent" >"$home/.claude/agents/e2e-n.md"
    printf 'n\n' | in_repo ./copy.sh --only files >/dev/null
    check "new shared-dir file answered n goes to the profile" test -f "$repo/profiles/$profile/home/.claude/agents/e2e-n.md"
    echo "# e2e agent" >"$home/.claude/agents/e2e-y.md"
    printf 'y\n' | in_repo ./copy.sh --only files >/dev/null
    check "new shared-dir file answered y goes to base" test -f "$repo/base/home/.claude/agents/e2e-y.md"
    check "a y file gets no patch" test ! -e "$repo/profiles/$profile/patches/home/.claude/agents/e2e-y.md.patch"
    echo
done

# zerofox-only files: credentials and gpg permissions.
echo "== zerofox secrets"
fresh zerofox
mkdir -p "$home/.docker"
printf 'registry=https://example.invalid/\n  //example.invalid/:_authToken=SECRET1\n_auth=SECRET2\n' >"$home/.npmrc"
printf '{"auths": {"r.example": {"auth": "SECRET3"}}, "credsStore": "osxkeychain"}\n' >"$home/.docker/config.json"
in_repo ./install.sh --only files --apply >/dev/null
check "install keeps npm credentials on the machine" bash -c "grep -q SECRET1 '$home/.npmrc' && grep -q SECRET2 '$home/.npmrc'"
check "install keeps docker credentials on the machine" grep -q SECRET3 "$home/.docker/config.json"
check "~/.gnupg is private" bash -c "[[ \$(stat -f %Lp '$home/.gnupg') == 700 ]]"
echo "  //other.invalid/:_authToken=SECRET4" >>"$home/.npmrc"
in_repo ./copy.sh --only files --no-sort >/dev/null
check "credentials never reach the repo" bash -c "! grep -rqE 'SECRET[0-9]' '$repo/base' '$repo/profiles'"
check "credentials never reach the snapshot" bash -c "! grep -rqE 'SECRET[0-9]' '$home/.local/state/dotfiles'"
echo

# T3 Code rewrites its client settings with app state.
echo "== T3 Code client settings"
fresh personal
t3_settings="$home/.t3/userdata/client-settings.json"
mkdir -p "$(dirname "$t3_settings")"
printf '{"wordWrap":false,"onboardingCompletedAt":"2026-01-01T00:00:00.000Z","dismissedProviderUpdateNotificationKeys":["e2e"]}\n' >"$t3_settings"
in_repo ./install.sh --only files --apply >/dev/null
check "install keeps existing T3 Code client settings" grep -q '"wordWrap":false' "$t3_settings"
in_repo ./copy.sh --only files --no-sort >/dev/null
check "copy carries T3 Code client settings" grep -rq '"wordWrap": false' "$repo/profiles/personal/patches/home/.t3"
check "T3 Code app state never reaches the repo" bash -c "! grep -rqE 'onboardingCompletedAt|dismissedProviderUpdateNotificationKeys' '$repo/base' '$repo/profiles'"
echo

# Agent skills keep the subpath they were added from, which the CLI's list
# drops and its lock file keeps. A stub stands in for the skills CLI (via pnpx)
# and prints what `skills ls -g --json` prints for this lock.
echo "== agent skills"
fresh personal
mkdir -p "$home/bin" "$home/.local/state/skills"
cat >"$home/bin/pnpx" <<'EOF'
#!/bin/sh
echo "$*" >>"$HOME/skills-calls.txt"
if [ "$2" = ls ]; then cat "$HOME/skills-ls.json"; fi
EOF
chmod +x "$home/bin/pnpx"
cat >"$home/skills-ls.json" <<'EOF'
[{"name":"bro","source":"cursor/plugins","sourceType":"github","agents":["Claude Code","Codex","Cursor"]},
{"name":"frontend-design","source":"anthropics/skills","sourceType":"github","agents":["Claude Code","Codex"]},
{"name":"frontend-slides","source":"zarazhangrui/frontend-slides","sourceType":"github","agents":["Claude Code","Codex"]},
{"name":"google-docs","source":"gabrielrojasc/skills","sourceType":"github","agents":["Claude Code"]}]
EOF
cat >"$home/.local/state/skills/.skill-lock.json" <<'EOF'
{"version": 3, "skills": {
  "bro": {"source": "cursor/plugins", "sourceType": "github", "skillPath": "pstack/skills/bro/SKILL.md"},
  "frontend-design": {"source": "anthropics/skills", "sourceType": "github", "skillPath": "skills/frontend-design/SKILL.md"},
  "frontend-slides": {"source": "zarazhangrui/frontend-slides", "sourceType": "github", "skillPath": "SKILL.md"}}}
EOF
in_repo env PATH="$home/bin:$PATH" bash -c 'source ./utils.sh && load_profile >/dev/null && read_machine agent-skills.txt /dev/stdout' >"$log_dir/skills-machine.txt"
check "a skill added from a subpath keeps it" grep -qx 'cursor/plugins/pstack bro' "$log_dir/skills-machine.txt"
check "a skill under the repo's skills/ keeps the bare repo" grep -qx 'anthropics/skills frontend-design' "$log_dir/skills-machine.txt"
check "a skill at the repo root keeps the bare repo" grep -qx 'zarazhangrui/frontend-slides frontend-slides' "$log_dir/skills-machine.txt"
check "a skill for only some listed agents goes in their own section" \
    bash -c "tail -3 '$log_dir/skills-machine.txt' | cmp -s - <(printf '%s\\n' '' 'agents claude-code' 'gabrielrojasc/skills google-docs')"

# install_skills: run install_agent_skills alone with --apply, since the rest
# of install.sh acts on the real machine.
function install_skills() {
    : >"$home/skills-calls.txt"
    in_repo env PATH="$home/bin:$PATH" bash -c '
        source ./utils.sh && load_profile >/dev/null
        apply=1 work=$(mktemp -d)
        eval "$(sed -n "/^function count_lines/,/^}/p; /^function install_agent_skills/,/^}/p" install.sh)"
        install_agent_skills'
}

# The list moves frontend-design to the Claude Code section, so it's reinstalled.
printf '%s\n' 'agents claude-code codex' 'cursor/plugins/pstack bro' 'openclaw/openclaw summarize' \
    'zarazhangrui/frontend-slides frontend-slides' '' 'agents claude-code' 'anthropics/skills frontend-design' \
    'gabrielrojasc/skills google-docs' 'gabrielrojasc/skills slack-message' >"$repo/base/agent-skills.txt"
install_skills >"$log_dir/skills-install.txt"
grep -v ' ls ' "$home/skills-calls.txt" >"$log_dir/skills-calls.txt"
check "install removes a skill before reinstalling it for other agents" \
    bash -c "head -1 '$log_dir/skills-calls.txt' | grep -qx 'skills@latest remove frontend-design -g -y'"
check "install adds a skill for its own agents" \
    grep -qx 'skills@latest add anthropics/skills -g -s frontend-design -a claude-code -y' "$log_dir/skills-calls.txt"
check "install adds a missing skill for its own agents" \
    grep -qx 'skills@latest add gabrielrojasc/skills -g -s slack-message -a claude-code -y' "$log_dir/skills-calls.txt"
check "install adds other skills for the agents line" \
    grep -qx 'skills@latest add openclaw/openclaw -g -s summarize -a claude-code -a codex -y' "$log_dir/skills-calls.txt"
check "install makes no other skills calls" test "$(wc -l <"$log_dir/skills-calls.txt" | tr -d ' ')" -eq 4

printf '%s\n' 'openclaw/openclaw summarize' '' 'agents claude-code codex' 'cursor/plugins/pstack bro' >"$repo/base/agent-skills.txt"
install_skills >"$log_dir/skills-install-unsectioned.txt"
check "install skips a list with skills before its first agents line" \
    bash -c "! grep -qv ' ls ' '$home/skills-calls.txt' && grep -q 'before its first' '$log_dir/skills-install-unsectioned.txt'"
echo

# Apps installed by hand: install reports the missing ones, copy adds new ones
# and drops uninstalled ones.
# Needs Homebrew, which copy asks for installed casks.
echo "== apps"
fresh personal
export DOTFILES_APPS_DIR="$home/Applications-e2e"
mkdir -p "$DOTFILES_APPS_DIR/E2E Manual.app" "$DOTFILES_APPS_DIR/E2E Store.app/Contents/_MASReceipt" "$home/elsewhere/E2E Linked.app"
ln -s "$home/elsewhere/E2E Linked.app" "$DOTFILES_APPS_DIR/E2E Linked.app"
in_repo ./install.sh --only apps --apply >"$log_dir/apps-install.txt"
check "install lists listed apps that are missing" grep -q 'WhatsApp' "$log_dir/apps-install.txt"
in_repo ./copy.sh --only apps --no-sort >"$log_dir/apps-copy.txt"
rendered=$(in_repo ./install.sh --show apps.txt)
check "copy adds a hand-installed app" grep -qx 'E2E Manual' <<<"$rendered"
check "copy keeps listed apps that are missing" grep -qx 'WhatsApp' <<<"$rendered"
check "copy leaves out App Store apps and symlinks" bash -c "! grep -qE 'E2E (Store|Linked)' <<<'$rendered'"
rm -r "$DOTFILES_APPS_DIR/E2E Manual.app"
in_repo ./copy.sh --only apps --no-sort >"$log_dir/apps-copy-uninstalled.txt"
rendered=$(in_repo ./install.sh --show apps.txt)
check "copy drops an app after it's uninstalled" bash -c "! grep -qx 'E2E Manual' <<<'$rendered'"
check "copy still keeps listed apps never installed here" grep -qx 'WhatsApp' <<<"$rendered"
mkdir -p "$DOTFILES_APPS_DIR/E2E Gone.app"
in_repo ./copy.sh --only apps --no-sort >/dev/null
check "copy lists an app before it's uninstalled" bash -c "(cd '$repo' && ./install.sh --show apps.txt) | grep -qx 'E2E Gone'"
rm -r "$DOTFILES_APPS_DIR/E2E Gone.app"
in_repo ./install.sh --only apps --apply >/dev/null
in_repo ./copy.sh --only apps --no-sort >"$log_dir/apps-copy-after-install.txt"
rendered=$(in_repo ./install.sh --show apps.txt)
check "copy drops an app uninstalled before an install" bash -c "! grep -qx 'E2E Gone' <<<'$rendered'"
mkdir -p "$DOTFILES_APPS_DIR/E2E Next.app"
in_repo ./copy.sh --only apps --no-sort >/dev/null
mkdir -p "$repo/.conflicts"
{ in_repo ./install.sh --show apps.txt; echo 'E2E Next2'; } | LC_ALL=C sort >"$repo/.conflicts/apps.txt"
in_repo ./copy.sh --resolve apps.txt >/dev/null
check "copy lists an app before the repo gains one beside it" bash -c "(cd '$repo' && ./install.sh --show apps.txt) | grep -qx 'E2E Next'"
rm -r "$DOTFILES_APPS_DIR/E2E Next.app"
in_repo ./copy.sh --only apps --no-sort >"$log_dir/apps-copy-beside-repo-add.txt"
rendered=$(in_repo ./install.sh --show apps.txt)
check "an uninstall beside a repo addition doesn't conflict" test ! -e "$repo/.conflicts/apps.txt"
check "an uninstall beside a repo addition drops only the uninstalled app" bash -c "! grep -qx 'E2E Next' <<<'$rendered' && grep -qx 'E2E Next2' <<<'$rendered'"
unset DOTFILES_APPS_DIR
echo

echo "== bots"
fresh zerofox
rm -rf "${repo:?}/base/bots" "${repo:?}"/profiles/*/patches/bots "${repo:?}"/profiles/*/bots "${repo:?}"/profiles/*/bots.txt
printf 'router %s\ncloser %s\n' "$(uuidgen | tr A-Z a-z)" "$(uuidgen | tr A-Z a-z)" >"$repo/profiles/zerofox/bots.txt"
git -C "$repo" add -A
git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -q --no-gpg-sign -m fleets
planted_server="srv-planted-$(date +%s)"
planted_token="ghp_$(printf '%036d' 7)"
planted_thread="planted thread title $RANDOM"
planted_thread_id=$(uuidgen)
zf="$home/staging-zerofox"
pf="$home/staging-personal"
bad="$home/staging-bad"
state="$home/.local/state/dotfiles/bots"

function id_of() { awk -v s="$2" '$1 == s { print $2 }' "$repo/profiles/$1/bots.txt"; }
function add_routine() {
    printf -- '---\nname: %s\ntrigger: every weekday at 09:00\nenabled: false\n---\n%s\n' "$2" "$3" >"$1/routines/$2.md"
}
function stage_fleet() {
    local profile=$1 dir=$2 slug id
    rm -rf "${dir:?}"
    mkdir -p "$dir"
    printf '# Setup map\n\nRouter sends work to Closer.\n' >"$dir/setup-map.md"
    printf '{"threads": [{"id": "%s", "title": "%s", "settled": false}], "byThread": {"%s": {"owner": "closer"}}}\n' \
        "$planted_thread_id" "$planted_thread" "$planted_thread_id" >"$dir/unsettled-threads.json"
    while read -r slug id; do
        mkdir -p "$dir/$id/routines"
        printf '{"name": "%s", "description": "%s bot", "title": "t", "avatarShape": "circle", "avatarColor": "blue", "harness": "h", "serverId": "%s"}\n' \
            "$slug" "$slug" "$planted_server" >"$dir/$id/profile.json"
        echo '{"notifyOnAgentUpdates": true}' >"$dir/$id/settings.json"
    done <"$repo/profiles/$profile/bots.txt"
    add_routine "$dir/$(id_of "$profile" router)" daily-sweep "List unsettled threads."
}
function copy_fleet() {
    rm -rf "${bad:?}"
    cp -R "$1" "$bad"
}
function set_field() { jq "$2" "$1" >"$1.tmp" && mv "$1.tmp" "$1"; }
function snap() { in_repo env DOTFILES_PROFILE="$1" bots/snapshot.sh "${@:2}"; }
function snap_list() { snap "$1" --list "$2" >"$3" 2>&1; }
function fingerprint_in() { sed -n 's/^Fingerprint: //p' "$1"; }
function snap_answer() {
    snap_list "$1" "$2" "$4.list" || return 1
    printf "$3" | snap "$1" --expect "$(fingerprint_in "$4.list")" "$2" >"$4" 2>&1
}
function snap_expect() { echo y | snap zerofox --expect "$1" "$2"; }
function snap_piped() { echo y | snap zerofox "$zf"; }
function snap_without_env() {
    local status=0
    mv "$repo/.env" "$repo/.env.off"
    in_repo bots/snapshot.sh --list "$zf" || status=$?
    mv "$repo/.env.off" "$repo/.env"
    return "$status"
}
function snap_stops() {
    local reason=$1 log_file=$2
    shift 2
    if "$@" >"$log_file" 2>&1 </dev/null; then return 1; fi
    grep -q -- "$reason" "$log_file"
}
function lists() { snap_list "$1" "$2" "$3" && grep -q -- "$4" "$3"; }
function lists_count() { snap_list "$1" "$2" "$3" && test "$(grep -c -- "$4" "$3")" -eq "$5"; }
function lists_no_changes() { snap_list "$1" "$2" "$3" && grep -qx 'No changes.' "$3"; }
function shows() { in_repo env DOTFILES_PROFILE="$1" ./install.sh --show "$2" 2>/dev/null; }
function renders() { shows "$1" "$2" >/dev/null; }
function hides() { ! renders "$1" "$2"; }
function copy_sort_n() { printf 'n\n%.0s' $(seq 200) | in_repo ./copy.sh --sort >"$1" 2>&1 && grep -q 'bots/closer/profile.json' "$1"; }
function commit_all() {
    git -C "$repo" add -A
    git -C "$repo" -c user.name=e2e -c user.email=e2e@localhost commit -q --no-gpg-sign --allow-empty -m "$1"
}
function no_planted_values() {
    ! grep -rqF -e "$planted_server" -e "$planted_token" -e "$planted_thread" -e "$planted_thread_id" --exclude-dir .git "$repo" "$state" &&
        ! git -C "$repo" log -p --all | grep -qF -e "$planted_server" -e "$planted_token" -e "$planted_thread" -e "$planted_thread_id"
}

stage_fleet zerofox "$zf"
check "snapshot stops without .env" snap_stops 'DOTFILES_PROFILE is not set' "$log_dir/bots-no-env.txt" snap_without_env
check "snapshot stops on an unknown profile" snap_stops "Unknown DOTFILES_PROFILE 'nope'" "$log_dir/bots-unknown-profile.txt" snap nope --list "$zf"
check "snapshot stops for a profile without a fleet" snap_stops 'profiles/personal/bots.txt is missing' "$log_dir/bots-no-fleet.txt" snap personal --list "$zf"
check "snapshot reads the profile from .env and stops before a baseline exists" \
    snap_stops 'run bots/snapshot.sh --seed first' "$log_dir/bots-no-baseline.txt" in_repo bots/snapshot.sh --list "$zf"
snap zerofox --seed >"$log_dir/bots-seed.txt" 2>&1
check "snapshot refuses piped answers without --expect" snap_stops 'pass --expect' "$log_dir/bots-no-expect.txt" snap_piped
check "a refused snapshot changes nothing" repo_clean || show_status

check "the first snapshot lists seven new files" lists_count zerofox "$zf" "$log_dir/bots-first-list.txt" ', new file$' 7
check "the first snapshot takes y for every file" snap_answer zerofox "$zf" 'y\ny\ny\ny\ny\ny\ny\n' "$log_dir/bots-first.txt"
check "y puts a new file in base" test "$(jq -r .name "$repo/base/bots/router/profile.json")" = router
check "snapshot drops serverId" test "$(jq 'has("serverId")' "$repo/base/bots/router/profile.json")" = false
check "a routine reaches base verbatim" cmp -s "$zf/$(id_of zerofox router)/routines/daily-sweep.md" "$repo/base/bots/router/routines/daily-sweep.md"
check "a bot without routines gets no routines folder" test ! -e "$repo/base/bots/closer/routines"
check "the ledger shape keeps fields and types" test "$(jq -r '.threads[0].title' "$repo/base/bots/shared/unsettled-threads.shape.json")" = string
check "the ledger shape collapses keys that are data" test "$(jq -r '.byThread | keys[0]' "$repo/base/bots/shared/unsettled-threads.shape.json")" = "<key>"
check "the snapshot records what the fleet had" test -f "$state/zerofox/bots/router/profile.json"
commit_all first

printf 'router %s\ncloser %s\n' "$(uuidgen | tr A-Z a-z)" "$(uuidgen | tr A-Z a-z)" >"$repo/profiles/personal/bots.txt"
commit_all personal-fleet
stage_fleet personal "$pf"
snap personal --seed >/dev/null 2>&1
check "a second fleet that matches base has no changes" lists_no_changes personal "$pf" "$log_dir/bots-personal-first.txt"

set_field "$zf/$(id_of zerofox router)/profile.json" '.description = "routes work, v2"'
set_field "$zf/$(id_of zerofox closer)/profile.json" '.title = "zerofox closer"'
check "two edits list as two numbered changes" lists_count zerofox "$zf" "$log_dir/bots-yn-list.txt" 'change [12] of 2, near line' 2
check "answers n then y apply, in list order" snap_answer zerofox "$zf" 'n\ny\n' "$log_dir/bots-yn.txt"
check "y moves the change to base" test "$(jq -r .description "$repo/base/bots/router/profile.json")" = "routes work, v2"
check "n leaves base unchanged" test "$(jq -r .title "$repo/base/bots/closer/profile.json")" = t
check "n puts the change in the profile patch" grep -q 'zerofox closer' "$repo/profiles/zerofox/patches/bots/closer/profile.json.patch"
check "the profile renders its n change" test "$(shows zerofox bots/closer/profile.json | jq -r .title)" = "zerofox closer"
check "another profile doesn't get an n change" test "$(shows personal bots/closer/profile.json | jq -r .title)" = t
check "another profile gets a y change" test "$(shows personal bots/router/profile.json | jq -r .description)" = "routes work, v2"
commit_all y-n

copy_fleet "$zf"
set_field "$bad/$(id_of zerofox router)/settings.json" '.notifyOnAgentUpdates = false'
snap_list zerofox "$bad" "$log_dir/bots-fingerprint-list.txt"
set_field "$bad/$(id_of zerofox router)/profile.json" '.title = "changed after the list"'
check "apply refuses when the staging changed after --list" snap_stops 'Run --list again' "$log_dir/bots-fingerprint-staging.txt" \
    snap_expect "$(fingerprint_in "$log_dir/bots-fingerprint-list.txt")" "$bad"
snap_list zerofox "$bad" "$log_dir/bots-fingerprint-list2.txt"
echo "# edited after the list" >>"$repo/base/bots/shared/setup-map.md"
check "apply refuses when the repo changed after --list" snap_stops 'Run --list again' "$log_dir/bots-fingerprint-repo.txt" \
    snap_expect "$(fingerprint_in "$log_dir/bots-fingerprint-list2.txt")" "$bad"
git -C "$repo" checkout -q -- base/bots/shared/setup-map.md
check "a refused apply changes nothing" repo_clean || show_status

check "a fleet that hasn't applied a promotion has no changes" lists_no_changes personal "$pf" "$log_dir/bots-promotion-list.txt"
check "applying that snapshot succeeds" snap_answer personal "$pf" '' "$log_dir/bots-promotion.txt"
check "the promotion stays in base" test "$(jq -r .description "$repo/base/bots/router/profile.json")" = "routes work, v2"
check "a snapshot with no changes leaves the repo clean" repo_clean || show_status

add_routine "$zf/$(id_of zerofox router)" shared-new "Post the daily summary."
add_routine "$zf/$(id_of zerofox router)" zf-only "Check ZeroFox tickets."
check "new routines list as new files" lists_count zerofox "$zf" "$log_dir/bots-new-list.txt" 'routines/.*, new file$' 2
check "answers y then n apply to new routines" snap_answer zerofox "$zf" 'y\nn\n' "$log_dir/bots-new.txt"
check "a new routine answered y goes to base" test -f "$repo/base/bots/router/routines/shared-new.md"
check "a new routine answered n goes to the profile" test -f "$repo/profiles/zerofox/bots/router/routines/zf-only.md"
check "another profile doesn't get a profile-only routine" hides personal bots/router/routines/zf-only.md
commit_all new-routines

rm "${zf:?}/$(id_of zerofox router)/routines/daily-sweep.md" "${zf:?}/$(id_of zerofox router)/routines/zf-only.md"
check "a deleted base routine lists as one change" lists zerofox "$zf" "$log_dir/bots-delete-list.txt" 'daily-sweep.md   change 1 of 1, deleted file'
check "answer n to a deleted routine applies" snap_answer zerofox "$zf" 'n\n' "$log_dir/bots-delete-n.txt"
check "n writes a deletion patch" grep -qx '+++ /dev/null' "$repo/profiles/zerofox/patches/bots/router/routines/daily-sweep.md.patch"
check "n keeps the routine in base" test -f "$repo/base/bots/router/routines/daily-sweep.md"
check "the profile no longer renders a routine it deleted" snap_stops 'is deleted for profile zerofox' "$log_dir/bots-delete-show.txt" \
    in_repo env DOTFILES_PROFILE=zerofox ./install.sh --show bots/router/routines/daily-sweep.md
check "another profile still renders it" renders personal bots/router/routines/daily-sweep.md
check "a deleted profile-only routine goes without asking" test ! -e "$repo/profiles/zerofox/bots/router/routines/zf-only.md"
check "the next snapshot has no changes" lists_no_changes zerofox "$zf" "$log_dir/bots-delete-stable.txt"
commit_all delete-n
check "copy.sh --sort skips a deletion patch and offers other bot patches" copy_sort_n "$log_dir/bots-copy-sort.txt"
check "copy.sh --sort with n leaves the repo unchanged" repo_clean || show_status

rm "${pf:?}/$(id_of personal router)/routines/daily-sweep.md"
check "answer y to a deleted routine applies" snap_answer personal "$pf" 'y\n' "$log_dir/bots-delete-y.txt"
check "y deletes the routine from base" test ! -e "$repo/base/bots/router/routines/daily-sweep.md"
check "y also drops other profiles' deletion patches" test ! -e "$repo/profiles/zerofox/patches/bots/router/routines/daily-sweep.md.patch"
commit_all delete-y

copy_fleet "$zf"
jq --arg t "$planted_token" '. + {apiToken: $t}' "$bad/$(id_of zerofox closer)/profile.json" >"$home/profile.json"
mv "$home/profile.json" "$bad/$(id_of zerofox closer)/profile.json"
check "snapshot stops on a field fields.txt doesn't list" snap_stops 'apiToken' "$log_dir/bots-unknown-field.txt" snap zerofox --list "$bad"

copy_fleet "$zf"
printf -- '---\nname: Leaky\ntrigger: on demand\nenabled: true\n---\nUse %s to call GitHub.\n' "$planted_token" \
    >"$bad/$(id_of zerofox router)/routines/leaky.md"
check "snapshot stops on a token in a routine prompt" snap_stops 'bots/router/routines/leaky.md:6' "$log_dir/bots-secret-prompt.txt" snap zerofox --list "$bad"
check "the stop message names the line, not the token" bash -c "! grep -qF '$planted_token' '$log_dir/bots-secret-prompt.txt'"

copy_fleet "$zf"
printf -- '---\nname: Odd\ntrigger: on demand\nenabled: true\nowner: me\n---\nHi.\n' >"$bad/$(id_of zerofox router)/routines/odd.md"
check "snapshot stops on a routine field fields.txt doesn't keep" snap_stops "field 'owner'" "$log_dir/bots-routine-field.txt" snap zerofox --list "$bad"

copy_fleet "$zf"
rmdir "$bad/$(id_of zerofox closer)/routines"
check "snapshot stops when a bot's routines are missing" snap_stops "$(id_of zerofox closer)/routines/ (closer)" "$log_dir/bots-missing.txt" snap zerofox --list "$bad"

copy_fleet "$zf"
mkdir -p "$bad/$(id_of zerofox router)/memory" && echo note >"$bad/$(id_of zerofox router)/memory/m.md"
check "snapshot stops on files outside the layout, such as memory" snap_stops "$(id_of zerofox router)/memory" "$log_dir/bots-memory.txt" snap zerofox --list "$bad"

cp -R "$zf" "$repo/.staging"
check "snapshot refuses a staging folder inside the repo" snap_stops 'Stage outside the repo' "$log_dir/bots-inside-repo.txt" snap zerofox --list .staging
rm -rf "${repo:?}/.staging"
check "no serverId, token, or ledger data reaches the repo, a commit, or the baseline" no_planted_values
check "the refused snapshots leave the repo clean" repo_clean || show_status
echo

echo "Failures: $failures"
echo "Log: $log"
((failures == 0))
