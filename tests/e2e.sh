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
check "a skill for only some listed agents names them" grep -qx 'gabrielrojasc/skills google-docs claude-code' "$log_dir/skills-machine.txt"

# The list wants frontend-design for Claude Code only, so it's reinstalled.
# install_agent_skills runs alone: the rest of install.sh acts on the real machine.
printf '%s\n' 'agents claude-code codex' 'anthropics/skills frontend-design claude-code' \
    'cursor/plugins/pstack bro' 'gabrielrojasc/skills google-docs claude-code' 'gabrielrojasc/skills slack-message claude-code' \
    'openclaw/openclaw summarize' 'zarazhangrui/frontend-slides frontend-slides' >"$repo/base/agent-skills.txt"
: >"$home/skills-calls.txt"
in_repo env PATH="$home/bin:$PATH" bash -c '
    source ./utils.sh && load_profile >/dev/null
    apply=1 work=$(mktemp -d)
    eval "$(sed -n "/^function count_lines/,/^}/p; /^function install_agent_skills/,/^}/p" install.sh)"
    install_agent_skills' >"$log_dir/skills-install.txt"
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

echo "Failures: $failures"
echo "Log: $log"
((failures == 0))
