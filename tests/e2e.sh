#!/usr/bin/env bash
# End-to-end check of install.sh and copy.sh for every profile, using a
# throwaway copy of this repo and a throwaway $HOME. Touches neither.
#
# Usage: tests/e2e.sh [log-dir]   (default: ~/tmp/dotfiles-e2e/<timestamp>)
# Only config files are exercised (--only files): brew, pnpm, and macOS
# defaults act on the real machine regardless of $HOME.

set -euo pipefail
# The scripts read these; values from the calling shell must not leak in.
unset DOTFILES_PROFILE XDG_STATE_HOME
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
    check "copy before install says why" grep -q 'never installed' "$log_dir/$profile-copy-before-install.txt"

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

echo "Failures: $failures"
echo "Log: $log"
((failures == 0))
