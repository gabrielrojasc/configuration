# AGENTS.md

Dotfiles for two macOS profiles, `personal` and `zerofox`, on one branch. Read `README.md` for the layout and the user-facing workflow before changing anything.

## Model

- A **key** is a path relative to a layer: `home/<path>` (a file at `$HOME/<path>`), `Brewfile`, `pnpm-globals.txt`, or `agent-skills.txt`.
- A profile **renders** a key from `profiles/<p>/<key>` if that whole file exists, else from `base/<key>` plus `profiles/<p>/patches/<key>.patch`.
- Shared behaviour belongs in `base/`; anything only one machine wants belongs in that profile. When unsure which side a change belongs to, ask.
- Print a rendered file with `DOTFILES_PROFILE=<p> ./install.sh --show <path>`.

## Changing configuration

- Shared change: edit `base/<key>`, then confirm every profile still renders it (`--show` for each profile; a patch that no longer applies prints a conflict).
- Profile-only change: patches are generated, so write the full file the profile should have to `.conflicts/<key>` and run `DOTFILES_PROFILE=<p> ./copy.sh --resolve <key>`. That regenerates the patch, or the profile's whole file when it owns one.
- Commit `base/` and the patches made against it together: render's 3-way fallback finds a patch's original base by the blob id on its `index` line, so that blob must be in git history.

## Approval gates

`./install.sh --apply` and `./upgrade.sh --apply` change the user's machine; run them only when the user asks in this conversation. Their dry runs (no flags) are read-only. `./copy.sh` writes the machine's state into the repo and may prompt; run it only when asked.

## Secrets

Credentials stay on the machine. `read_machine` in `utils.sh` strips them on the way into the repo (npm auth lines, Docker inline auths), and `add_machine_secrets` puts them back on install. Any new key that can hold a credential gets the same pair of filters, plus an `e2e` check that the credential reaches neither the repo nor the snapshot.

## Script conventions

- Scripts run on a fresh Mac: `/bin/bash` 3.2 with BSD tools, under `set -euo pipefail`. Expand possibly-empty arrays as `${a[@]+"${a[@]}"}`, and write portable `sed` (no bare `sed -i`).
- End loops and functions with `if ...; then ...; fi` rather than `test && action`: a false final test fails the pipeline or caller under `set -e`.
- Install replaces symlinks instead of writing through them. Keep it that way: an old `~/.claude/CLAUDE.md` pointed at `~/.codex/AGENTS.md`.

## Verify

Done means `tests/e2e.sh` reports `Failures: 0` under both shells:

```sh
tests/e2e.sh
env -i HOME="$HOME" PATH=/usr/bin:/bin /bin/bash tests/e2e.sh
```

It uses a throwaway repo copy and `$HOME`, and leaves its log under `~/tmp/dotfiles-e2e/`. Add a check there for each new behaviour of `install.sh` or `copy.sh`.
