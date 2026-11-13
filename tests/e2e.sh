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

echo "== locale"
check "scripts set LANG=C when it is unset" env -u LANG bash -c "source '$src/utils.sh' && [[ \$LANG == C ]]"
check "scripts keep a LANG that is set" env LANG=en_US.UTF-8 bash -c "source '$src/utils.sh' && [[ \$LANG == en_US.UTF-8 ]]"
echo

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

    echo "alias e2e-adjacent='true'" >>"$home/.zsh_aliases"
    printf 'y\n' | in_repo ./copy.sh --only files >"$log_dir/$profile-copy-adjacent.txt"
    check "sort y next to a profile-only line moves the hunk to base" grep -q e2e-adjacent "$repo/base/home/.zsh_aliases"
    check "sort y next to a profile-only line stops the patch adding it" bash -c "! grep -q '^+alias e2e-adjacent' '$repo/profiles/$profile/patches/home/.zsh_aliases.patch'"
    check "the profile-only neighbour stays out of base" bash -c "! grep -q e2e-local '$repo/base/home/.zsh_aliases'"
    check "the summary counts the adjacent hunk as moved to base" grep -q '1 to base, 0 kept' "$log_dir/$profile-copy-adjacent.txt"
    check "render matches the machine after the adjacent hunk moves" bash -c "cmp -s '$home/.zsh_aliases' <(cd '$repo' && HOME='$home' ./install.sh --show .zsh_aliases)"

    sed -i.bak "s/^alias e2e-local='true'\$/alias e2e-local='false'/" "$home/.zsh_aliases" && rm "$home/.zsh_aliases.bak"
    cp "$repo/base/home/.zsh_aliases" "$log_dir/$profile-base-before-profile-only-edit.txt"
    printf 'y\n' | in_repo ./copy.sh --only files >"$log_dir/$profile-copy-profile-only-edit.txt"
    check "sort y on an edit of a profile-only line leaves base unchanged" cmp -s "$repo/base/home/.zsh_aliases" "$log_dir/$profile-base-before-profile-only-edit.txt"
    check "sort y on an edit of a profile-only line keeps it in the patch" grep -q "e2e-local='false'" "$repo/profiles/$profile/patches/home/.zsh_aliases.patch"
    check "the summary counts the edit of a profile-only line as kept" grep -q '0 to base, 1 kept' "$log_dir/$profile-copy-profile-only-edit.txt"
    check "render matches the machine after the profile-only edit" bash -c "cmp -s '$home/.zsh_aliases' <(cd '$repo' && HOME='$home' ./install.sh --show .zsh_aliases)"
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

function ledger_fixture() {
    jq -n --arg id "$2" --arg title "$3" '{
        about: "Unsettled T3 threads", seedNote: null,
        statusValues: "needs-you, working, waiting-on-others, done-to-settle", updatedAt: "2026-11-07T10:00:00-03:00",
        threads: {($id): {title: $title, machine: "e2e-mac", project: null, owner: "closer", ownerGuessed: false,
            status: "needs-you", reason: "open-question", links: [], since: "2026-11-07T09:00:00-03:00",
            updatedAt: "2026-11-07T10:00:00-03:00", updatedNote: null, requestIds: [], decision: "Pick A or B",
            followUp: null, notifiedAt: null, notifiedFingerprint: null}}}' >"$1"
}

echo "== ledger check"
fresh zerofox
lc="$home/ledger-check"
mkdir -p "$lc"
for profile in personal zerofox; do
    in_repo env DOTFILES_PROFILE="$profile" ./install.sh --show bots/t3-tots/routines/t3-questions-to-chat.md >"$lc/routine-$profile.md"
    awk '/^```python$/ { on = 1; next } /^```$/ { on = 0 } on' "$lc/routine-$profile.md" >"$lc/ledger-check-$profile.py"
    check "the $profile routine pins its ledger check by sha256" \
        grep -qF "doesn't print $(shasum -a 256 "$lc/ledger-check-$profile.py" | cut -c1-64), write it again" "$lc/routine-$profile.md"
    check "the $profile ledger check uses the repo's ledger format" python3 -c '
import json, runpy, sys
sys.exit(runpy.run_path(sys.argv[1])["FORMAT"] != json.load(open(sys.argv[2])))' \
        "$lc/ledger-check-$profile.py" "$repo/base/bots/shared/unsettled-threads.shape.json"
done
function ledger_check() { python3 "$lc/ledger-check-zerofox.py" "$@"; }
function ledger_refuses() {
    jq "$2" "$lc/good.json" >"$lc/bad.json"
    ! ledger_check check "$lc/bad.json" >"$lc/bad.txt" && grep -q -- "$1" "$lc/bad.txt"
}
function fingerprint_after() {
    jq "$1" "$lc/good.json" >"$lc/changed.json"
    ledger_check fingerprint "$lc/changed.json" e2e-thread
}
ledger_fixture "$lc/good.json" e2e-thread "E2E thread"
check "the ledger check passes a ledger in the format" bash -c "python3 '$lc/ledger-check-zerofox.py' check '$lc/good.json' | grep -qx ok"
check "the ledger check refuses an unknown field" ledger_refuses 'e2e-thread: unknown field holdSettle' '.threads[].holdSettle = true'
check "the ledger check refuses a missing field" ledger_refuses 'e2e-thread: missing field notifiedFingerprint' '.threads[] |= del(.notifiedFingerprint)'
check "the ledger check refuses an old status" ledger_refuses 'status must be one of needs-you' '.threads[].status = "idle"'
check "the ledger check refuses an empty string for null" ledger_refuses 'decision must be string|null' '.threads[].decision = ""'
check "the ledger check refuses null where a value is required" ledger_refuses 'title must be string' '.threads[].title = null'
check "the ledger check refuses an unknown top-level field" ledger_refuses 'ledger: unknown field byThread' '.byThread = {}'
told=$(ledger_check fingerprint "$lc/good.json" e2e-thread)
check "the fingerprint ignores changes the closer isn't told" test "$(fingerprint_after '.threads[].updatedNote = "checked CI"')" = "$told"
check "the fingerprint changes with the decision" test "$(fingerprint_after '.threads[].decision = "Pick C"')" != "$told"
check "the fingerprint changes with the status" test "$(fingerprint_after '.threads[].status = "done-to-settle"')" != "$told"
echo

echo "== bots"
fresh zerofox
rm -rf "${repo:?}/base/bots" "${repo:?}"/profiles/*/patches/bots "${repo:?}"/profiles/*/bots "${repo:?}"/profiles/*/bots.txt
mkdir -p "$repo/base/bots/shared"
cp "$src/base/bots/shared/unsettled-threads.shape.json" "$repo/base/bots/shared/"
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
function write_report() {
    local dir=$1
    for routine in "$dir"/routines/*.md; do
        if [[ -e "$routine" ]]; then basename "$routine"; fi
    done | jq -R '{file: ., folderId: ("folder-" + .)}' |
        jq -s --arg name "$(jq -r .name "$dir/profile.json")" '{reportedBy: $name, reportedOn: "2026-11-07", routines: .}' >"$dir/routines.json"
}
function add_routine() {
    printf -- '---\nname: %s\ntrigger: every weekday at 09:00\nenabled: false\n---\n%s\n' "$2" "$3" >"$1/routines/$2.md"
    write_report "$1"
}
function stage_ledger() { ledger_fixture "$1/unsettled-threads.json" "$planted_thread_id" "$planted_thread"; }
function stage_fleet() {
    local profile=$1 dir=$2 slug id
    rm -rf "${dir:?}"
    mkdir -p "$dir"
    printf '# Setup map\n\nRouter sends work to Closer.\n' >"$dir/setup-map.md"
    stage_ledger "$dir"
    while read -r slug id; do
        mkdir -p "$dir/$id/routines"
        printf '{"name": "%s", "description": "%s bot", "title": "t", "avatarShape": "circle", "avatarColor": "blue", "harness": "h", "serverId": "%s"}\n' \
            "$slug" "$slug" "$planted_server" >"$dir/$id/profile.json"
        echo '{"notifyOnAgentUpdates": true}' >"$dir/$id/settings.json"
        write_report "$dir/$id"
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

check "the first snapshot lists six new files" lists_count zerofox "$zf" "$log_dir/bots-first-list.txt" ', new file$' 6
check "the first snapshot takes y for every file" snap_answer zerofox "$zf" 'y\ny\ny\ny\ny\ny\n' "$log_dir/bots-first.txt"
check "y puts a new file in base" test "$(jq -r .name "$repo/base/bots/router/profile.json")" = router
check "snapshot drops serverId" test "$(jq 'has("serverId")' "$repo/base/bots/router/profile.json")" = false
check "a routine reaches base verbatim" cmp -s "$zf/$(id_of zerofox router)/routines/daily-sweep.md" "$repo/base/bots/router/routines/daily-sweep.md"
check "a bot that reports no routines gets no routines folder" test ! -e "$repo/base/bots/closer/routines"
check "the snapshot leaves the ledger format to the repo" cmp -s "$src/base/bots/shared/unsettled-threads.shape.json" "$repo/base/bots/shared/unsettled-threads.shape.json"
check "the snapshot records what the fleet had" test -f "$state/zerofox/bots/router/profile.json"
commit_all first

function snap_ledger_stops() {
    copy_fleet "$zf"
    set_field "$bad/unsettled-threads.json" "$3"
    snap_stops "$1" "$log_dir/bots-ledger-$2.txt" snap zerofox --list "$bad"
}
check "a staged ledger with an unknown field stops" snap_ledger_stops "  $planted_thread_id: unknown field holdSettle" unknown '.threads[].holdSettle = true'
check "a staged ledger with a missing field stops" snap_ledger_stops "  $planted_thread_id: missing field followUp" missing '.threads[] |= del(.followUp)'
check "a staged ledger with an old status stops" snap_ledger_stops 'status must be one of needs-you, working, waiting-on-others, done-to-settle' status '.threads[].status = "kept-open"'
check "a staged ledger with a wrong type stops" snap_ledger_stops 'links must be string\[\]' type '.threads[].links = "none"'
check "a refused ledger never prints its values" bash -c "! grep -qF '$planted_thread' '$log_dir'/bots-ledger-*.txt"
check "a refused ledger leaves the repo clean" repo_clean || show_status

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
write_report "$zf/$(id_of zerofox router)"
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
write_report "$pf/$(id_of personal router)"
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
write_report "$bad/$(id_of zerofox router)"
check "snapshot stops on a token in a routine prompt" snap_stops 'bots/router/routines/leaky.md:6' "$log_dir/bots-secret-prompt.txt" snap zerofox --list "$bad"
check "the stop message names the line, not the token" bash -c "! grep -qF '$planted_token' '$log_dir/bots-secret-prompt.txt'"

copy_fleet "$zf"
printf -- '---\nname: Odd\ntrigger: on demand\nenabled: true\nowner: me\n---\nHi.\n' >"$bad/$(id_of zerofox router)/routines/odd.md"
write_report "$bad/$(id_of zerofox router)"
check "snapshot stops on a routine field fields.txt doesn't keep" snap_stops "field 'owner'" "$log_dir/bots-routine-field.txt" snap zerofox --list "$bad"

copy_fleet "$zf"
rm "$bad/$(id_of zerofox closer)/routines.json"
check "snapshot stops when a bot hasn't reported its routines" \
    snap_stops "$(id_of zerofox closer)/routines.json (closer)" "$log_dir/bots-unreported.txt" snap zerofox --list "$bad"
check "that stop says the bot's routines are unverified" grep -q 'Unverified routines' "$log_dir/bots-unreported.txt"
copy_fleet "$zf"
rm "$bad/$(id_of zerofox router)/routines.json" "$bad/$(id_of zerofox router)/routines/"*.md
check "an unreported bot with an empty routines folder stops instead of losing its routines" \
    snap_stops "$(id_of zerofox router)/routines.json (router)" "$log_dir/bots-unreported-empty.txt" snap_expect 0000000000000000 "$bad"
check "the unreported bot's routine stays in the repo and the record" \
    bash -c "test -f '$repo/base/bots/router/routines/shared-new.md' && test -f '$state/zerofox/bots/router/routines/shared-new.md'"
copy_fleet "$zf"
rm "$bad/$(id_of zerofox router)/routines/shared-new.md"
check "a reported routine that isn't staged stops the snapshot" \
    snap_stops 'shared-new.md: in the report, but not staged' "$log_dir/bots-report-unstaged.txt" snap zerofox --list "$bad"
copy_fleet "$zf"
printf -- '---\nname: Extra\ntrigger: on demand\nenabled: true\n---\nHi.\n' >"$bad/$(id_of zerofox router)/routines/extra.md"
check "a staged routine the bot didn't report stops the snapshot" \
    snap_stops 'extra.md: staged, but not in the report' "$log_dir/bots-report-unreported-routine.txt" snap zerofox --list "$bad"
copy_fleet "$zf"
set_field "$bad/$(id_of zerofox closer)/routines.json" '.reportedBy = "router"'
check "a report that names another bot stops the snapshot" \
    snap_stops 'needs reportedBy: the bot name in profile.json, closer' "$log_dir/bots-report-other-bot.txt" snap zerofox --list "$bad"
copy_fleet "$zf"
set_field "$bad/$(id_of zerofox router)/routines.json" '.routines |= map(del(.folderId))'
check "a reported routine without a folder id stops the snapshot" \
    snap_stops 'needs each routine as .*"file":"shared-new.md"' "$log_dir/bots-report-no-folder.txt" snap zerofox --list "$bad"
copy_fleet "$zf"
set_field "$bad/$(id_of zerofox router)/routines.json" '.routines |= map(.folderId = "")'
check "a reported routine with an empty folder id stops the snapshot" \
    snap_stops 'needs each routine as' "$log_dir/bots-report-empty-folder.txt" snap zerofox --list "$bad"
copy_fleet "$zf"
set_field "$bad/$(id_of zerofox router)/routines.json" '.confirmedBy = "Gabriel"'
rmdir "$bad/$(id_of zerofox closer)/routines"
check "a bot that reports no routines, as an empty list, needs no routines folder" lists_no_changes zerofox "$bad" "$log_dir/bots-report-none.txt"
check "the list shows each bot's report, with its source, date, and confirmation" \
    bash -c "grep -qx '  closer: no routines, reported by closer on 2026-11-07' '$log_dir/bots-report-none.txt' &&
        grep -qx '  router: 1 routine, reported by router on 2026-11-07, confirmed by Gabriel' '$log_dir/bots-report-none.txt'"
snap_list zerofox "$bad" "$log_dir/bots-report-fingerprint.txt"
set_field "$bad/$(id_of zerofox router)/routines.json" 'del(.confirmedBy)'
check "apply refuses when a report changed after --list" snap_stops 'Run --list again' "$log_dir/bots-report-fingerprint-apply.txt" \
    snap_expect "$(fingerprint_in "$log_dir/bots-report-fingerprint.txt")" "$bad"
check "the refused report snapshots change nothing" repo_clean || show_status

copy_fleet "$zf"
mkdir -p "$bad/$(id_of zerofox router)/memory" && echo note >"$bad/$(id_of zerofox router)/memory/m.md"
check "snapshot stops on files outside the layout, such as memory" snap_stops "$(id_of zerofox router)/memory" "$log_dir/bots-memory.txt" snap zerofox --list "$bad"

cp -R "$zf" "$repo/.staging"
check "snapshot refuses a staging folder inside the repo" snap_stops 'Stage outside the repo' "$log_dir/bots-inside-repo.txt" snap zerofox --list .staging
rm -rf "${repo:?}/.staging"
function mktemp_staging() {
    local dir
    dir=$(mktemp -d)
    cp -R "$zf/." "$dir/"
    touch "$dir.tgz" "$dir-unrelated.txt"
    mkdir "$dir.keep"
    echo "$dir"
}
function gone() { test ! -e "$1" && test ! -e "$1.tgz" && test -e "$1-unrelated.txt" && test -d "$1.keep"; }
function kept() { test -d "$1" && test -e "$1.tgz"; }

nested="$home/staging-nested"
cp -R "$zf" "$nested"
touch "$nested.tgz"
check "applying from a staging folder that isn't directly in a temp folder succeeds" snap_answer zerofox "$nested" '' "$log_dir/bots-clean-nested.txt"
check "that staging folder and its copies stay, and the script says so" bash -c "test -d '$nested' && test -e '$nested.tgz' && grep -q 'Left .* in place' '$log_dir/bots-clean-nested.txt'"
applied=$(mktemp_staging)
check "applying a snapshot from a mktemp -d folder succeeds" snap_answer zerofox "$applied" '' "$log_dir/bots-clean-apply.txt"
check "the applied staging folder and its file copies are deleted, but not other files or a folder named after it" gone "$applied"
refused=$(mktemp_staging)
check "a refused apply keeps the staging folder and its copies" snap_stops 'Run --list again' "$log_dir/bots-clean-refused.txt" snap_expect 0000000000000000 "$refused"
check "the refused staging folder is still there" kept "$refused"
check "--discard deletes a mktemp -d staging folder and its copies" snap zerofox --discard "$refused" >"$log_dir/bots-discard.txt" 2>&1
check "the discarded staging folder and its file copies are gone, but not other files or a folder named after it" gone "$refused"
check "--discard refuses a folder that isn't directly in a temp folder" snap_stops 'Delete .* yourself' "$log_dir/bots-discard-nested.txt" snap zerofox --discard "$nested"
check "the refused nested folder is still there" kept "$nested"
odd=$(mktemp_staging)
mkdir "$odd/memory"
check "--discard refuses a folder with files outside the layout" snap_stops 'Unexpected files' "$log_dir/bots-discard-odd.txt" snap zerofox --discard "$odd"
check "the refused odd folder is still there" kept "$odd"
ran_out=$(mktemp_staging)
set_field "$ran_out/$(id_of zerofox closer)/profile.json" '.title = "answers ran out"'
check "an apply whose answers run out succeeds" snap_answer zerofox "$ran_out" '' "$log_dir/bots-clean-ran-out.txt"
check "an apply whose answers ran out keeps the staging folder and says so" \
    bash -c "grep -q 'answers ran out' '$log_dir/bots-clean-ran-out.txt' && grep -q 'Kept .* because of the warning' '$log_dir/bots-clean-ran-out.txt'"
check "the ran-out staging folder is still there" kept "$ran_out"
commit_all ran-out
mkdir -p "$repo/.conflicts/bots/router"
shows personal bots/router/profile.json | jq '.description = "personal router"' >"$repo/.conflicts/bots/router/profile.json"
in_repo env DOTFILES_PROFILE=personal ./copy.sh --resolve bots/router/profile.json >/dev/null
commit_all personal-router
unrendered=$(mktemp_staging)
set_field "$unrendered/$(id_of zerofox closer)/profile.json" '.title = "answers ran out"'
set_field "$unrendered/$(id_of zerofox router)/profile.json" '.description = "routes work, v3"'
check "an apply that breaks another profile's patch succeeds" snap_answer zerofox "$unrendered" 'y\n' "$log_dir/bots-clean-unrendered.txt"
check "an apply that breaks another profile's patch keeps the staging folder and says so" \
    bash -c "grep -q 'bots/router/profile.json no longer renders for personal' '$log_dir/bots-clean-unrendered.txt' && ! grep -q 'answers ran out' '$log_dir/bots-clean-unrendered.txt' && grep -q 'Kept .* because of the warning' '$log_dir/bots-clean-unrendered.txt'"
check "the staging folder for the broken patch is still there" kept "$unrendered"
commit_all unrendered
for dir in "$applied" "$refused" "$odd" "$ran_out" "$nested" "$unrendered"; do
    rm -rf "${dir:?}" "$dir.tgz" "$dir-unrelated.txt" "$dir.keep"
done

function stage_from_record() {
    local profile=$1 dir=$2 slug id
    rm -rf "${dir:?}"
    mkdir -p "$dir"
    cp "$state/$profile/bots/shared/setup-map.md" "$dir/setup-map.md"
    stage_ledger "$dir"
    while read -r slug id; do
        mkdir -p "$dir/$id/routines"
        cp "$state/$profile/bots/$slug/profile.json" "$state/$profile/bots/$slug/settings.json" "$dir/$id/"
        if [[ -d "$state/$profile/bots/$slug/routines" ]]; then cp "$state/$profile/bots/$slug/routines/"*.md "$dir/$id/routines/"; fi
        write_report "$dir/$id"
    done <"$state/$profile/bots.txt"
}
function rename_bot() {
    local old=$1 new=$2 file dir
    for file in "$repo"/profiles/*/bots.txt; do
        awk -v o="$old" -v n="$new" '$1 == o { $1 = n } { print }' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
    done
    for dir in "$repo/base/bots" "$repo"/profiles/*/bots "$repo"/profiles/*/patches/bots; do
        if [[ -d "$dir/$old" ]]; then mv "$dir/$old" "$dir/$new"; fi
    done
    for dir in "$repo"/profiles/*/patches/bots/"$new"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -name '*.patch' -exec perl -pi -e "s#bots/$old/#bots/$new/#g if /^(diff --git|--- |\\+\\+\\+ )/" {} +
        fi
    done
}
function renders_both() { renders zerofox "$1" && renders personal "$1"; }
function synced() { snap "$1" --sync-record >"$2" 2>&1 && grep -q -- "$3" "$2"; }

moved="$home/staging-moved"
stage_from_record zerofox "$moved"
check "a stage built from the last snapshot has no changes" lists_no_changes zerofox "$moved" "$log_dir/bots-rename-before.txt"
rename_bot closer finisher
set_field "$repo/base/bots/finisher/profile.json" '.description = "finishes work, edited in the repo"'
commit_all rename
check "both profiles render a renamed bot" renders_both bots/finisher/profile.json
check "a renamed bot keeps its last snapshot, so a repo edit isn't offered back" lists_no_changes zerofox "$moved" "$log_dir/bots-rename-list.txt"
check "the list doesn't name the old slug" bash -c "! grep -q 'bots/closer/' '$log_dir/bots-rename-list.txt'"
check "--sync-record says it followed the rename" synced zerofox "$log_dir/bots-sync-rename.txt" 'Renamed closer to finisher'
check "the record files the bot under its new slug" \
    bash -c "test -f '$state/zerofox/bots/finisher/profile.json' && test ! -e '$state/zerofox/bots/closer' && grep -q '^finisher ' '$state/zerofox/bots.txt'"
check "the renamed bot still has no changes after --sync-record" lists_no_changes zerofox "$moved" "$log_dir/bots-rename-synced.txt"

removed_id=$(id_of zerofox finisher)
awk '$1 != "finisher"' "$repo/profiles/zerofox/bots.txt" >"$repo/profiles/zerofox/bots.txt.tmp"
mv "$repo/profiles/zerofox/bots.txt.tmp" "$repo/profiles/zerofox/bots.txt"
rm -rf "${moved:?}/$removed_id"
commit_all remove
check "a fleet without a removed bot has no changes" lists_no_changes zerofox "$moved" "$log_dir/bots-remove-list.txt"
check "--sync-record says it dropped the removed bot" synced zerofox "$log_dir/bots-sync-remove.txt" 'Dropped finisher'
check "the record no longer has the removed bot" \
    bash -c "test ! -e '$state/zerofox/bots/finisher' && ! grep -q '$removed_id' '$state/zerofox/bots.txt'"

mkdir -p "$repo/profiles/zerofox/bots/shared"
printf '# Workflow map\n\nHow work moves through the bots.\n' >"$repo/profiles/zerofox/bots/shared/workflow-map.md"
commit_all workflow-map
cp "$repo/profiles/zerofox/bots/shared/workflow-map.md" "$state/zerofox/bots/shared/workflow-map.md"
check "a repo-only shared file isn't listed, even when an old record has it" lists_no_changes zerofox "$moved" "$log_dir/bots-shared-list.txt"
check "applying that snapshot succeeds" snap_answer zerofox "$moved" '' "$log_dir/bots-shared-apply.txt"
check "the apply keeps the repo-only shared file" test -f "$repo/profiles/zerofox/bots/shared/workflow-map.md"
check "the apply leaves it out of the record" test ! -e "$state/zerofox/bots/shared/workflow-map.md"
check "the shared-file snapshot leaves the repo clean" repo_clean || show_status
snap zerofox --seed >"$log_dir/bots-shared-seed.txt" 2>&1
check "--seed leaves a repo-only shared file out of the record" test ! -e "$state/zerofox/bots/shared/workflow-map.md"
cp "$repo/profiles/zerofox/bots/shared/workflow-map.md" "$state/zerofox/bots/shared/workflow-map.md"
check "--sync-record drops a repo-only shared file from the record" synced zerofox "$log_dir/bots-sync-shared.txt" 'Dropped bots/shared/workflow-map.md'
check "the record no longer has the repo-only shared file" test ! -e "$state/zerofox/bots/shared/workflow-map.md"
rm -rf "${moved:?}"

check "no serverId, token, or ledger data reaches the repo, a commit, or the baseline" no_planted_values
check "the refused snapshots leave the repo clean" repo_clean || show_status

machine_id=$(uuidgen | tr A-Z a-z)
machine_list="$state/zerofox.machine-ids"
machine_stage="$home/staging-machine"
machine_key=bots/router/routines/mac-check.md
machine_routine="$machine_stage/$(id_of zerofox router)/routines/mac-check.md"
function no_machine_id() {
    ! LC_ALL=C grep -rqiF -e "$machine_id" --exclude-dir .git "$repo" "$state/zerofox" &&
        ! git -C "$repo" log -p --all | LC_ALL=C grep -iF -e "$machine_id" >/dev/null
}
function record_lacks_machine_id() { ! LC_ALL=C grep -rqiF -e "$machine_id" "$state/zerofox"; }
function log_lacks_machine_id() { ! LC_ALL=C grep -qiF -e "$machine_id" "$1"; }
function snap_in_c_locale() { LC_ALL=C snap_answer "$@"; }
function hidden_in_utf8() {
    LC_ALL=en_US.UTF-8 snap zerofox --list "$machine_stage" >"$1" 2>&1 || true
    log_lacks_machine_id "$1"
}
function hides_every_form() { LC_ALL=C grep -qF -e 'on <machine-id> (machineId <machine-id>).' "$repo/base/bots/router/routines/mac-bytes.md"; }
function renders_placeholder() { shows zerofox "$machine_key" | grep -qF -e "$1 (machineId <machine-id>)"; }
function live_edit() { sed "s/Check [A-Za-z ]*(/Check $1 (/" "$machine_routine" >"$machine_routine.new" && mv "$machine_routine.new" "$machine_routine"; }
function real_id_in_record() {
    local file="$state/zerofox/$machine_key"
    sed "s/<machine-id>/$machine_id/" "$file" >"$file.new" && mv "$file.new" "$file"
}

stage_from_record zerofox "$machine_stage"
add_routine "$machine_stage/$(id_of zerofox router)" mac-check "Check the Mac (machineId $machine_id) for expiry."
check "snapshot stops on a machine ID its local list doesn't name" \
    snap_stops "$(id_of zerofox router)/routines/mac-check.md:6" "$log_dir/bots-machine-unlisted.txt" snap zerofox --list "$machine_stage"
check "that stop never prints the ID" log_lacks_machine_id "$log_dir/bots-machine-unlisted.txt"
mv "$machine_routine" "$home/mac-check.keep"
printf -- '---\nname: mac-check\nmachineId %s\nenabled: false\n---\nCheck.\n' "$machine_id" >"$machine_routine"
check "an unlisted ID in front matter stops before the field check prints it" \
    snap_stops 'Machine IDs; nothing was written' "$log_dir/bots-machine-front.txt" snap zerofox --list "$machine_stage"
check "the front matter stop never prints the ID" log_lacks_machine_id "$log_dir/bots-machine-front.txt"
mv "$home/mac-check.keep" "$machine_routine"
echo not-a-machine-id >"$machine_list"
check "snapshot stops on a malformed machine ID list" \
    snap_stops 'one machine ID per line' "$log_dir/bots-machine-malformed.txt" snap zerofox --list "$machine_stage"
echo "$machine_id" >"$machine_list"
check "a listed machine ID passes the scan" lists zerofox "$machine_stage" "$log_dir/bots-machine-list.txt" 'mac-check.md'
check "the change list never prints the ID" log_lacks_machine_id "$log_dir/bots-machine-list.txt"
check "that snapshot applies" snap_answer zerofox "$machine_stage" 'y\n' "$log_dir/bots-machine-apply.txt"
check "the record holds no real ID right after a snapshot" record_lacks_machine_id
commit_all machine-id
check "the repo renders the placeholder" renders_placeholder 'Check the Mac'
check "the staged routine keeps the real ID" grep -qF -e "$machine_id" "$machine_routine"
check "the local list outlives the snapshot that rewrites the record" test -f "$machine_list"
check "a fleet with the real ID has no changes against a placeholder in the repo" \
    lists_no_changes zerofox "$machine_stage" "$log_dir/bots-machine-stable.txt"

printf -- '---\nname: mac-bytes\ntrigger: every weekday at 09:00\nenabled: false\n---\ncaf\351 on %s (machineId %s).\n' \
    "$(tr a-z A-Z <<<"$machine_id")" "$(tr a-z A-Z <<<"$machine_id")" >"$machine_stage/$(id_of zerofox router)/routines/mac-bytes.md"
write_report "$machine_stage/$(id_of zerofox router)"
add_routine "$machine_stage/$(id_of zerofox router)" mac-neighbor "Mac $machine_id / bot $(id_of zerofox router)."
check "a listed ID beside a non-UTF-8 byte stays hidden in a UTF-8 locale" hidden_in_utf8 "$log_dir/bots-machine-utf8.txt"
check "a bot ID next to a placeholder isn't mistaken for a machine ID" \
    snap_in_c_locale zerofox "$machine_stage" 'y\ny\n' "$log_dir/bots-machine-forms.txt"
check "a listed ID is hidden in capitals too" hides_every_form
commit_all machine-id-forms

cp "$repo/base/$machine_key" "$repo/base/$machine_key.keep"
sed "s/<machine-id>/$machine_id/" "$repo/base/$machine_key.keep" >"$repo/base/$machine_key"
snap zerofox --seed >"$log_dir/bots-machine-seed.txt" 2>&1
mv "$repo/base/$machine_key.keep" "$repo/base/$machine_key"
check "--seed hides a listed ID from the record" record_lacks_machine_id
check "after --seed the fleet still has no changes" lists_no_changes zerofox "$machine_stage" "$log_dir/bots-machine-seeded.txt"

real_id_in_record
live_edit 'the session'
check "a record with the real ID doesn't turn a live edit into a conflict" \
    snap_answer zerofox "$machine_stage" 'y\n' "$log_dir/bots-machine-old-record.txt"
commit_all machine-id-live-edit
check "that live edit lands with the placeholder" renders_placeholder 'Check the session'

sed 's/Check the session/Check the repo/' "$repo/base/$machine_key" >"$repo/base/$machine_key.new"
mv "$repo/base/$machine_key.new" "$repo/base/$machine_key"
commit_all machine-id-repo-edit
live_edit 'the fleet'
check "edits to the same line stop the snapshot" \
    snap_stops 'changed the same lines' "$log_dir/bots-machine-conflict.txt" snap zerofox "$machine_stage"
check "the conflict file holds the placeholder" grep -qF -e '(machineId <machine-id>)' "$repo/.conflicts/$machine_key"
check "the conflict file has no real ID" log_lacks_machine_id "$repo/.conflicts/$machine_key"
sed "s/$machine_id/<machine-id>/" "$machine_routine" >"$repo/.conflicts/$machine_key"
in_repo ./copy.sh --resolve "$machine_key" >"$log_dir/bots-machine-resolve.txt" 2>&1
commit_all machine-id-resolved
check "copy.sh --resolve keeps the placeholder" renders_placeholder 'Check the fleet'
check "the resolved conflict doesn't come back" lists_no_changes zerofox "$machine_stage" "$log_dir/bots-machine-resolved.txt"

real_id_in_record
snap zerofox --sync-record >"$log_dir/bots-machine-sync.txt" 2>&1
check "no machine ID reaches the repo, a commit, or the record, even after --sync-record" no_machine_id
check "the machine ID snapshots leave the repo clean" repo_clean || show_status
rm -rf "${machine_stage:?}"
echo

# The manifest pins the bot skills. A stub stands in for gh and serves a fake
# upstream, and a stub for UpdateSkill writes what the plan says with its
# frontmatter reformatted, so the real scripts run from pin to live skill.
echo "== bot skills"
fresh zerofox
skills_key=bots/shared/skills.txt
function declared() { in_repo env DOTFILES_PROFILE="$1" ./install.sh --show "$skills_key"; }
function declares_every_skill() {
    local listed
    listed=$(declared "$1" | awk 'NF == 2 { print $1 }')
    grep -qx open-items <<<"$listed" && grep -qx grok-rewrite-it <<<"$listed" && grep -qx grok-slack-message <<<"$listed" &&
        grep -qx t3-tots-rules <<<"$listed" && grep -qx t3-install-tools <<<"$listed"
}
function pins_are_exact() {
    declared "$1" | awk '$1 == "source" && $5 !~ /^[0-9a-f]+$/ || $1 == "source" && length($5) != 40 || NF == 2 && length($2) != 64 { bad = 1 } END { exit bad }'
}
for profile in zerofox personal; do
    check "$profile declares the skills/bots skills and the t3 skills" declares_every_skill "$profile"
    check "$profile pins each source to a commit and each skill to a sha256" pins_are_exact "$profile"
done

mkdir -p "$home/bin"
cat >"$home/bin/gh" <<'STUB'
#!/bin/sh
up="$HOME/upstream"
repo=$(echo "$2" | cut -d/ -f2,3)
tail=$(echo "$2" | cut -d/ -f4-)
case "$tail" in
    contents/*)
        path=${tail#contents/}
        commit=${path##*\?ref=}
        cat "$up/$repo/$commit/${path%\?ref=*}"
        ;;
    commits/*) cat "$up/$repo/refs/${tail#commits/}" ;;
    git/trees/*)
        commit=${tail#git/trees/}
        cd "$up/$repo/${commit%\?*}" &&
            find . -type f | sed 's|^\./||' | sort | jq -R '{type: "blob", path: .}' | jq -s '{truncated: false, tree: .}'
        ;;
    *) exit 1 ;;
esac
STUB
chmod +x "$home/bin/gh"

# upstream_skill <repo> <commit> <folder> <id> <body>
function upstream_skill() {
    mkdir -p "$home/upstream/$1/$2/$3/$4"
    printf -- '---\nname: %s\ndescription: >-\n  Use for %s:\n  when asked.\n---\n\n%b\n' "$4" "$4" "$5" >"$home/upstream/$1/$2/$3/$4/SKILL.md"
}
function upstream_ref() {
    mkdir -p "$(dirname "$home/upstream/$1/refs/$2")"
    echo "$3" >"$home/upstream/$1/refs/$2"
}
function skills_cmd() { in_repo env PATH="$home/bin:$PATH" bots/skills.sh "$@"; }
function stage_bundle() {
    bundle=$(mktemp -d)
    skills_cmd --stage "$bundle" >"$log_dir/bot-skills-stage.txt" 2>&1
}
function skills_check() { env BOT_SKILLS_LIVE="$live" python3 "$bundle/check-skills.py" "$@"; }
function check_says() { skills_check "${@:2}" >"$log_dir/bot-skills-check.txt" 2>&1 || true; grep -q -- "$1" "$log_dir/bot-skills-check.txt"; }
function check_passes() { skills_check >"$log_dir/bot-skills-check.txt" 2>&1; }
function check_exits() {
    local status=0
    skills_check >"$log_dir/bot-skills-check.txt" 2>&1 || status=$?
    [[ "$status" -eq "$1" ]]
}
function update_skill() {
    local file=$1 id
    id=$(jq -r 'if .new then .name else .id end' "$file")
    mkdir -p "$live/$id"
    jq -r '"---\ndescription: \(.description | @json)\nname: \(.name)\n---\n\n\(.body)"' "$file" >"$live/$id/SKILL.md"
}
function apply_plan() {
    local step
    while IFS= read -r step; do update_skill "$bundle/plan/$step"; done < <(jq -r '.apply_in_order[].file' "$bundle/plan/PLAN.json")
}
function plan_order() { jq -r '[.apply_in_order[].id] | join(" ")' "$bundle/plan/PLAN.json"; }
function plan_new() { [[ $(jq -r --arg i "$1" '.apply_in_order[] | select(.id == $i) | .new' "$bundle/plan/PLAN.json") == "$2" ]]; }
function plan_order_is() { [[ "$(plan_order)" == "$1" ]]; }
function stage_stops() {
    local reason=$1 target=$2
    if skills_cmd --stage "$target" >"$log_dir/bot-skills-refused.txt" 2>&1; then return 1; fi
    grep -q -- "$reason" "$log_dir/bot-skills-refused.txt"
}
function bump_stops() {
    local reason=$1
    shift
    if skills_cmd --bump "$@" >"$log_dir/bot-skills-refused.txt" 2>&1; then return 1; fi
    grep -q -- "$reason" "$log_dir/bot-skills-refused.txt"
}

upstream_ref acme/bots main c1
upstream_ref acme/t3 v1 c2
upstream_skill acme/bots c1 skills/bots alpha 'Alpha steps.'
upstream_skill acme/bots c1 skills/bots beta 'Beta steps.'
upstream_skill acme/t3 c2 skills t3-install-tools 'PINNED = {\n "b": ["b", "2"],\n "a": ["a", "1"]\n}\nInstall steps.'
upstream_skill acme/t3 c2 skills t3-tots-rules 'Rules.'
upstream_skill acme/t3 c2 skills t3-zeta 'Zeta steps.'
printf 'source acme/bots skills/bots main 0\n\nsource acme/t3 skills v1 0\n' >"$repo/base/$skills_key"
skills_cmd --bump acme/bots >"$log_dir/bot-skills-bump.txt" 2>&1
skills_cmd --bump acme/t3 >>"$log_dir/bot-skills-bump.txt" 2>&1
commit_all pinned
check "--bump records the commit of a branch" grep -qx 'source acme/bots skills/bots main c1' "$repo/base/$skills_key"
check "--bump records every skill with its sha256" grep -qx "alpha $(shasum -a 256 "$home/upstream/acme/bots/c1/skills/bots/alpha/SKILL.md" | awk '{ print $1 }')" "$repo/base/$skills_key"

stage_bundle
check "--stage writes each skill, the manifest, and the check" \
    bash -c "test -f '$bundle/alpha/SKILL.md' && test -f '$bundle/t3-zeta/SKILL.md' && test -f '$bundle/skills.txt' && test -f '$bundle/check-skills.py'"
check "--stage keeps a skill's upstream bytes" cmp -s "$bundle/alpha/SKILL.md" "$home/upstream/acme/bots/c1/skills/bots/alpha/SKILL.md"
check "--stage refuses a folder that isn't empty" stage_stops "isn't empty" "$bundle"
check "--stage refuses a folder inside the repo" stage_stops 'Stage outside the repo' "$repo"

live=$(mktemp -d)
check "a box with no skills lists each as missing" check_says 'missing: alpha'
check "the check exits 1 when a skill is missing" check_exits 1
check "a check without --plan writes no plan" test ! -e "$bundle/plan"
skills_check --plan >"$log_dir/bot-skills-plan.txt" 2>&1 || true
check "the plan puts t3-tots-rules first and t3-install-tools last" plan_order_is 't3-tots-rules alpha beta t3-zeta t3-install-tools'
check "the plan marks a missing skill as new" plan_new alpha true
check "a plan entry holds the body without frontmatter" bash -c "[[ \$(jq -r .body '$bundle/plan/alpha.json') == 'Alpha steps.' ]]"
check "a plan entry folds the description" bash -c "[[ \$(jq -r .description '$bundle/plan/alpha.json') == 'Use for alpha: when asked.' ]]"
update_skill "$bundle/plan/t3-tots-rules.json"
skills_check --plan >/dev/null 2>&1 || true
check "after a partly applied plan, a new plan holds only what's left" plan_order_is 'alpha beta t3-zeta t3-install-tools'
apply_plan
check "after the plan, reformatted frontmatter counts as a match" check_passes
check "a clean check says so" grep -q 'OK: every listed skill matches' "$log_dir/bot-skills-check.txt"
skills_check --plan >/dev/null 2>&1
check "a clean box drops the old plan" test ! -e "$bundle/plan"

perl -0pi -e 's/ "b": \["b", "2"\],\n "a": \["a", "1"\]/ "a": ["a", "1"],\n "b": ["b", "2"]/' "$live/t3-install-tools/SKILL.md"
check "t3's reordered PINNED rows count as a match" check_passes
perl -pi -e 's/"1"/"9"/' "$live/t3-install-tools/SKILL.md"
check "a changed PINNED hash counts as a change" check_says 'changed: t3-install-tools'
skills_check --plan >/dev/null 2>&1 || true
apply_plan

mkdir -p "$live/unrelated"
printf -- '---\nname: unrelated\ndescription: Mine.\n---\nBody.\n' >"$live/unrelated/SKILL.md"
check "a skill the bundle doesn't list doesn't fail the check" check_passes
check "a skill the bundle doesn't list is reported" grep -q 'unlisted, left alone: unrelated' "$log_dir/bot-skills-check.txt"

printf 'Hand edit.\n' >>"$live/beta/SKILL.md"
check "an edited body is a change" check_says 'changed: beta (+0/-1 lines)'
check "the check exits 1 on a change" check_exits 1
skills_check --plan >/dev/null 2>&1 || true
check "a plan rewrites an existing skill with its id" plan_new beta false
check "a plan leaves an unlisted skill out" test ! -e "$bundle/plan/unrelated.json"
apply_plan
check "applying the change clears it" check_passes

sed '/^name:/s/alpha/renamed/' "$live/alpha/SKILL.md" >"$live/alpha/SKILL.md.new" && mv "$live/alpha/SKILL.md.new" "$live/alpha/SKILL.md"
check "a changed name is a change" check_says 'changed: alpha (+0/-0 lines, name)'
skills_check --plan >/dev/null 2>&1 || true
apply_plan

mv "$live/alpha" "$live/generated-id"
check "a live skill with the same name under another id is a collision" check_says 'collision: alpha has the name of live skill generated-id'
skills_check --plan >/dev/null 2>&1 || true
check "a collision stays out of the plan, so no duplicate gets made" test ! -e "$bundle/plan/alpha.json"
mv "$live/generated-id" "$live/alpha"

mv "$live/alpha" "$live/generated-id"
perl -pi -e 's/^description: .*/description: "bad \\q escape"/' "$live/generated-id/SKILL.md"
check "an unreadable live skill with the same name is a collision" check_says 'collision: alpha has the name of live skill generated-id'
skills_check --plan >/dev/null 2>&1 || true
check "that collision stays out of the plan too" test ! -e "$bundle/plan/alpha.json"
rm -rf "${live:?}/generated-id"
mkdir -p "$live/alpha"
cp "$bundle/alpha/SKILL.md" "$live/alpha/SKILL.md"

perl -0pi -e 's/\n/\r\n/g' "$live/alpha/SKILL.md"
check "CRLF line endings count as a match" check_passes
cp "$bundle/alpha/SKILL.md" "$live/alpha/SKILL.md"

{
    printf -- '---\nname: alpha\ntags:\n- one\n- two\ndescription: "Use for alpha:\\\n'
    printf -- '  \\ when asked."\n---\n\nAlpha steps.\n'
} >"$live/alpha/SKILL.md"
check "a wrapped double-quoted description and a list count as a match" check_passes
cp "$bundle/alpha/SKILL.md" "$live/alpha/SKILL.md"

printf -- '--dry-run\n' >>"$live/alpha/SKILL.md"
check "a removed line that starts with dashes is counted" check_says 'changed: alpha (+0/-1 lines)'
cp "$bundle/alpha/SKILL.md" "$live/alpha/SKILL.md"

printf 'no frontmatter\n' >"$live/beta/SKILL.md"
check "a live skill the check can't read is reported" check_says 'unreadable: beta'
check "an unreadable skill fails the check" check_exits 1
skills_check --plan >/dev/null 2>&1 || true
check "an unreadable skill stays out of the plan" test ! -e "$bundle/plan/beta.json"
cp "$bundle/beta/SKILL.md" "$live/beta/SKILL.md"

cp "$bundle/skills.txt" "$bundle/skills.txt.good"
head -n 2 "$bundle/skills.txt.good" >"$bundle/skills.txt"
check "a truncated manifest stops the check" check_exits 2
check "a truncated manifest is named" grep -q 'HASH_MISMATCH skills.txt' "$log_dir/bot-skills-check.txt"
: >"$bundle/skills.txt"
shasum -a 256 "$bundle/skills.txt" | awk '{ print $1 }' >"$bundle/skills.txt.sha256.empty"
cp "$bundle/skills.txt.sha256" "$bundle/skills.txt.sha256.good"
cp "$bundle/skills.txt.sha256.empty" "$bundle/skills.txt.sha256"
check "an empty manifest can't pass" check_exits 2
check "an empty manifest is named" grep -q EMPTY_MANIFEST "$log_dir/bot-skills-check.txt"
mv "$bundle/skills.txt.good" "$bundle/skills.txt"
mv "$bundle/skills.txt.sha256.good" "$bundle/skills.txt.sha256"
rm -f "$bundle/skills.txt.sha256.empty"
real_live=$live
live="$live/nothing-here"
check "a missing live folder stops the check" check_exits 2
live=$real_live
mv "$bundle/skills.txt" "$bundle/skills.txt.off"
check "a missing manifest stops the check without a traceback" check_exits 2
check "a missing manifest names the error" grep -q UNREADABLE "$log_dir/bot-skills-check.txt"
mv "$bundle/skills.txt.off" "$bundle/skills.txt"

printf 'tampered\n' >>"$bundle/alpha/SKILL.md"
check "a corrupted bundle stops the check" check_exits 2
check "a corrupted bundle names the skill" grep -q 'HASH_MISMATCH alpha' "$log_dir/bot-skills-check.txt"
rm -rf "${bundle:?}/plan"
skills_check --plan >/dev/null 2>&1 || true
check "a corrupted bundle writes no plan" test ! -e "$bundle/plan"

printf 'moved upstream\n' >>"$home/upstream/acme/bots/c1/skills/bots/alpha/SKILL.md"
empty=$(mktemp -d)
check "--stage stops when a file no longer matches its pin" stage_stops 'HASH_MISMATCH: alpha' "$empty"
check "a refused stage writes nothing" bash -c "[[ -z \$(ls -A '$empty') ]]"
rm -f "$home/upstream/acme/bots/c1/skills/bots/alpha/SKILL.md"
check "--stage stops when a pinned file is gone" stage_stops "Couldn't download" "$empty"
check "a failed download writes nothing" bash -c "[[ -z \$(ls -A '$empty') ]]"

upstream_ref acme/bots main c3
upstream_skill acme/bots c3 skills/bots beta 'Beta steps, revised.'
upstream_skill acme/bots c3 skills/bots gamma 'Gamma steps.'
t3_before=$(sed -n '/^source acme\/t3/,$p' "$repo/base/$skills_key")
skills_cmd --bump acme/bots >"$log_dir/bot-skills-bump2.txt" 2>&1
check "--bump moves a branch to its new commit" grep -qx 'source acme/bots skills/bots main c3' "$repo/base/$skills_key"
check "--bump adds a new skill" grep -q '^gamma ' "$repo/base/$skills_key"
check "--bump drops a removed skill" bash -c "! grep -q '^alpha ' '$repo/base/$skills_key'"
check "--bump leaves other sources alone" bash -c "[[ \$(sed -n '/^source acme\\/t3/,\$p' '$repo/base/$skills_key') == '$t3_before' ]]"
upstream_ref acme/t3 v2 c4
upstream_skill acme/t3 c4 skills t3-tots-rules 'Rules, revised.'
skills_cmd --bump acme/t3 v2 >>"$log_dir/bot-skills-bump2.txt" 2>&1
check "--bump with a ref records the new tag" grep -qx 'source acme/t3 skills v2 c4' "$repo/base/$skills_key"
check "--bump stops on a repo that isn't listed" bump_stops 'has no source' acme/unknown
upstream_ref acme/bots extra c5
upstream_skill acme/bots c5 skills/bots delta 'Delta steps.'
mkdir -p "$home/upstream/acme/bots/c5/skills/bots/delta/scripts"
echo run >"$home/upstream/acme/bots/c5/skills/bots/delta/scripts/run.sh"
before_refused=$(cat "$repo/base/$skills_key")
check "--bump stops on a file UpdateSkill can't write" bump_stops 'can write only' acme/bots extra
check "a refused bump leaves the manifest alone" bash -c "[[ \$(cat '$repo/base/$skills_key') == \"\$0\" ]]" "$before_refused"
upstream_ref acme/bots nested c6
upstream_skill acme/bots c6 skills/bots a-b 'Nested id.'
upstream_skill acme/bots c6 skills/bots 'Upper' 'Bad id.'
check "--bump stops on a skill id the manifest can't hold" bump_stops 'can write only' acme/bots nested

upstream_ref acme/bots licensed c8
upstream_skill acme/bots c8 skills/bots zeta 'Zeta steps.'
perl -pi -e 's/^name: zeta$/name: zeta\nlicense: MIT/' "$home/upstream/acme/bots/c8/skills/bots/zeta/SKILL.md"
check "--bump stops on frontmatter UpdateSkill can't write" bump_stops 'can write only name and description' acme/bots licensed
upstream_ref acme/bots misnamed c9
upstream_skill acme/bots c9 skills/bots zeta 'Zeta steps.'
perl -pi -e 's/^name: zeta$/name: other/' "$home/upstream/acme/bots/c9/skills/bots/zeta/SKILL.md"
check "--bump stops on a name that differs from the folder" bump_stops 'differs from its folder' acme/bots misnamed
upstream_ref acme/bots reserved c10
upstream_skill acme/bots c10 skills/bots plan 'Plan steps.'
check "--bump stops on a skill id the bundle uses" bump_stops "can't be a skill id" acme/bots reserved
cp "$repo/base/$skills_key" "$home/manifest.good"
printf '\nsource acme/bots other main c3\nzeta 00\n' >>"$repo/base/$skills_key"
check "--bump stops on a repo listed twice" bump_stops 'lists acme/bots twice' acme/bots
cp "$home/manifest.good" "$repo/base/$skills_key"

printf '%s' "$(cat "$repo/base/$skills_key")" >"$repo/base/$skills_key"
last_skill=$(awk 'NF == 2 { id = $1 } END { print id }' "$repo/base/$skills_key")
stage_bundle
check "a manifest with no final newline keeps its last skill" test -f "$bundle/$last_skill/SKILL.md"
cp "$home/manifest.good" "$repo/base/$skills_key"

commit_all bumped
mkdir -p "$repo/.conflicts/bots/shared"
declared zerofox | grep -v '^gamma ' >"$repo/.conflicts/$skills_key"
in_repo env DOTFILES_PROFILE=zerofox ./copy.sh --resolve "$skills_key" >"$log_dir/bot-skills-resolve.txt" 2>&1
commit_all profile-drops-a-skill
stage_bundle
check "a profile patch drops a skill from its bundle" test ! -e "$bundle/gamma"
check "a profile patch keeps the other skills in its bundle" test -f "$bundle/beta/SKILL.md"
bundle=$(mktemp -d)
(cd "$repo" && HOME="$home" XDG_STATE_HOME="$home/.local/state" env DOTFILES_PROFILE=personal PATH="$home/bin:$PATH" bots/skills.sh --stage "$bundle") >"$log_dir/bot-skills-personal.txt" 2>&1
check "the other profile's bundle keeps the skill" test -f "$bundle/gamma/SKILL.md"
upstream_ref acme/bots main c7
upstream_skill acme/bots c7 skills/bots beta 'Beta steps.'
upstream_skill acme/bots c7 skills/bots gamma 'Gamma steps, revised.'
skills_cmd --bump acme/bots >"$log_dir/bot-skills-bump3.txt" 2>&1
check "--bump warns when a profile patch no longer applies" grep -q 'zerofox no longer renders' "$log_dir/bot-skills-bump3.txt"
check "the snapshot script leaves the manifest out of a seed" bash -c "(cd '$repo' && HOME='$home' XDG_STATE_HOME='$home/.local/state' DOTFILES_PROFILE=personal bots/snapshot.sh --seed) >/dev/null 2>&1 && test ! -e '$home/.local/state/dotfiles/bots/personal/$skills_key'"
echo

echo "Failures: $failures"
echo "Log: $log"
((failures == 0))
