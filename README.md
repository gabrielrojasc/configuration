# configuration

Dotfiles and machine setup for two macOS profiles: `personal` and `zerofox`.
Shared configuration lives in `base/`. Each profile adds only what differs.

## Select a profile

Create a `.env` file in the repository root. Git ignores it.

```sh
echo 'DOTFILES_PROFILE=personal' > .env
```

The scripts stop if `DOTFILES_PROFILE` is missing or doesn't match a directory
in `profiles/`. An environment variable overrides `.env`:

```sh
DOTFILES_PROFILE=zerofox ./install.sh --show .zshrc
```

## Install

`install.sh` is a dry run unless you pass `--apply` (or `-a`). The dry run shows a diff
for each config file, missing Brewfile entries, macOS defaults that differ, and
the steps it would run.

```sh
./install.sh                # review
./install.sh --apply        # apply; replaced files go to ~/.config-backup/<timestamp>
./install.sh --only files   # config files only: no brew, pnpm, defaults, or hooks
./install.sh --show .zshrc  # print the file this profile renders
```

`~/.codex/config.toml` is written only when it's missing, because Codex keeps
machine state in it.

## Upgrade

`upgrade.sh` lists what's outdated, and upgrades it with `--apply` (or `-a`): Homebrew
formulae and casks (including casks that update themselves, followed by
`brew cleanup --prune=all`, which also deletes every cached download), Mac App Store
apps, the profile's toolchain (mise on `personal`, proto on `zerofox`), pnpm
globals, and global agent skills (`skills update -g`). The skills CLI can't
report which skills are outdated, so the dry run only counts them.

```sh
./upgrade.sh          # list what's outdated
./upgrade.sh --apply  # upgrade it
```

Toolchain upgrades stay within the versions the toolchain config asks for, such
as `node = "lts"`.

## Copy changes back

After you change configuration on a machine, run:

```sh
./copy.sh
```

`copy.sh` compares each file with what `install.sh` last wrote and carries only
your local edits into the repository. Changes that another machine pushed, and
that this machine hasn't installed yet, are kept. Files that `install.sh --apply`
has never written on this machine are skipped, so run it once before your first
copy.

For each new change, `copy.sh` asks where it belongs (this is `git add -p`):

- `y`: move it to `base/`, so every profile gets it.
- `n`: keep it in this profile's patch.
- `q`: keep the remaining changes in this profile's patch.

Other options:

- `--no-sort`: keep every new change in this profile's patch without asking.
- `--sort`: offer the hunks already in this profile's patches for promotion to
  `base/`.

Some merges need a hand fix:

- A local edit overlaps a change in the repository.
- A change in `base/` touches the same lines as this profile's patch.

In both cases the scripts leave that file alone and write the merged version,
with conflict markers, to `.conflicts/<key>`. For example, for `~/.zshrc`, fix
the markers in `.conflicts/home/.zshrc`, then run:

```sh
./copy.sh --resolve .zshrc
```

## Layout

```text
base/
├── home/                  # mirrors $HOME; shared by every profile
├── Brewfile
├── pnpm-globals.txt
└── Basic.terminal
profiles/<name>/
├── profile.sh             # install and copy hooks
├── home/                  # whole files only this profile has; override base/
└── patches/               # one patch per base/ file this profile changes
```

To see what a profile changes in a shared file, read its patch, for example
`profiles/zerofox/patches/home/.zshrc.patch`.

## Test

```sh
tests/e2e.sh
```

The test installs and copies each profile against a temporary copy of the
repository and a temporary `$HOME`. It writes a log to `~/tmp/dotfiles-e2e/`.
