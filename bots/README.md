# Grok Bot setup

This repository records each Grok Bot fleet's setup: every bot's profile,
settings, and routines, plus the setup map and the shape of the
unsettled-threads ledger. It uses the same base and patch model as the
dotfiles, and `DOTFILES_PROFILE` picks the profile in the same way.

Each fleet's box is the source of truth. Changes flow one way, from a fleet
into git. The app can't import from git, and `install.sh` never installs these
files.

To install these bots on a new Grok Bot account, see [INSTALL.md](INSTALL.md).

## Layout

```text
base/bots/
├── <slug>/
│   ├── profile.json
│   ├── settings.json
│   └── routines/<routine>.md      # absent when the bot has none
└── shared/
    └── unsettled-threads.shape.json # the ledger's fields and types, no values
profiles/<profile>/
├── bots.txt                         # this profile's fleet: "<slug> <bot id>" per line
├── bots/<path>                      # files only this profile has
├── bots/shared/setup-map.md         # copied from this fleet's box
├── bots/shared/workflow-map.md      # how work moves through the bots and T3 Code; placed by hand
└── patches/bots/<path>.patch        # this profile's changes to base/bots, including deletions
bots/
├── snapshot.sh                      # brings a staged snapshot into the repo
├── fields.txt                       # the fields a snapshot keeps
└── README.md
```

`shared/setup-map.md` describes what each bot does and how the bots connect.
Each fleet's T3 Tots builds its own from that account's Mac, so it lives in
the profile, not in base.
To print the file a profile has, run:

```sh
DOTFILES_PROFILE=zerofox ./install.sh --show bots/router/profile.json
```

## Take a snapshot

1. Ask T3 Tots for a staging folder:

   > Make a private folder on my Mac with `mktemp -d` and tell me its path.
   > Copy `/home/box/t3-tots/setup-map.md` and
   > `/home/box/t3-tots/unsettled-threads.json` into it. For each bot in
   > `profiles/<profile>/bots.txt`, copy
   > `/home/box/agent-data/agents/<id>/profile.json` and `settings.json` into
   > `<id>/`. Ask each bot to print every saved routine, paused ones included,
   > and write each one to `<id>/routines/<slug>.md` in the routine format
   > below. Create `<id>/routines/` even for a bot with no routines. Copy
   > nothing else.

2. List the changes. This writes nothing:

   ```sh
   bots/snapshot.sh --list <staging-folder>
   ```

   The list numbers each change and ends with a fingerprint.

3. Answer each numbered change:

   - `y`: every profile. The change goes to `base/bots/`.
   - `n`: only this profile. The change goes to this profile's patch, or to
     `profiles/<profile>/bots/` for a new file.
   - `q`: only this profile, for this change and every one after it.

   A change without an answer stays in this profile only. Answer `n` to a
   change that names this account's Linear teams, inboxes, Slack workspace,
   machine, or T3 threads: `base/bots/` names no account.

4. Apply the answers, one per line in list order, with the list's
   fingerprint:

   ```sh
   printf 'y\nn\n' | bots/snapshot.sh --expect <fingerprint> <staging-folder>
   ```

   If the staging folder, the repository, or the last snapshot changed since
   the list, the script writes nothing and asks for a new list. At a terminal,
   `bots/snapshot.sh <staging-folder>` asks about each change directly.

   After it applies every change without a warning, the script deletes the
   staging folder and every file beside it named `<staging-folder>.*`, such
   as a tarball. Name a copy you want to keep differently. The script deletes
   only a staging folder directly inside `/tmp`, `$TMPDIR`, or the user's
   temp folder, where `mktemp -d` makes one. Delete any other staging folder
   yourself: it holds the live ledger and each bot's `serverId`. When the
   script stops on an error, it keeps them so you can fix the staging folder
   and rerun. When it ends with a warning, such as answers running out, it
   keeps them too: deal with the warning, then run `--discard` below.

5. Review `git status` and `git diff`, then commit `base/` and the patches
   together.

To drop a snapshot without applying it, delete its staging folder and the
copies named after it:

```sh
bots/snapshot.sh --discard <staging-folder>
```

## How a snapshot sorts changes

A change is what the fleet changed since its last snapshot. The script keeps
each fleet's last snapshot in `~/.local/state/dotfiles/bots/<profile>/` and
merges the fleet's changes onto the files the profile has in the repository.
So a change that another profile moved to base, and that this fleet hasn't
applied yet, isn't offered as a change to undo.

- An edited file is offered one hunk at a time.
- A new file is offered whole: `y` adds it to `base/bots/`, `n` to
  `profiles/<profile>/bots/`.
- A deleted file is offered whole: `y` deletes it from `base/bots/` and drops
  other profiles' patches that delete it too. If another profile's patch
  edits it, base keeps it and the file is deleted only for this profile. `n`
  writes a patch that deletes it for this profile.
- A file only this profile has is updated or deleted without asking.

Of `bots/shared/`, a snapshot handles only `setup-map.md` and
`unsettled-threads.shape.json`. It never lists, records, or deletes any other
file there, such as a profile's `workflow-map.md`.

If the fleet and the repository changed the same lines since the last
snapshot, the script writes the merged file with conflict markers to
`.conflicts/<key>` and stops. Fix the markers, run
`./copy.sh --resolve <key>`, then take the snapshot again.

`./copy.sh --sort` offers bot patches for promotion to base, the same way it
does for other patches. It skips patches that delete a file.

### Start tracking a fleet

The script needs the fleet's last snapshot. When the repository already
matches the fleet, record that as the starting point:

```sh
bots/snapshot.sh --seed
```

For a new fleet with nothing in the repository yet, seed first, and the next
snapshot offers every file as new. A fleet's `bots.txt` is never shared:
bot ids belong to one fleet.

### Rename or remove a bot

The last snapshot matches `bots.txt` by bot id. To rename a bot's slug,
rename its folder in `base/bots/` and in each profile's `bots/` and
`patches/bots/`, change the paths on each moved patch's `diff --git`, `---`,
and `+++` lines, and change the slug in every `bots.txt` that lists it. To
remove a bot from a fleet, delete its line from that fleet's `bots.txt`. The
next snapshot follows the change. To update the last snapshot right away,
run:

```sh
bots/snapshot.sh --sync-record
```

## Staging layout

```text
<staging-folder>/
├── setup-map.md
├── unsettled-threads.json
└── <bot id>/            # one per line of bots.txt
    ├── profile.json
    ├── settings.json
    └── routines/
        └── <slug>.md    # lowercase letters, digits, and hyphens
```

The script stops before showing or writing anything unless all of these hold:

- The staging folder is outside the repository.
- Every bot in `bots.txt` has `profile.json`, `settings.json`, and `routines/`.
  A missing routines folder means the export failed, not that the bot has no
  routines.
- The folder holds nothing else, such as a bot's memory.
- Every field is listed in `fields.txt`.
- No file it would write looks like it holds a secret.

## Routine format

Each routine is a Markdown file. Front matter holds its settings, and the body
is the saved prompt, exactly as the bot prints it:

```markdown
---
name: Daily sweep
trigger: every weekday at 09:00
timing: America/Santiago
enabled: false
---
List the unsettled threads and ...
```

`name`, `trigger`, and `enabled` (`true` or `false`) are required. `timing` is
optional. `fields.txt` lists the fields a routine may have.

## What a snapshot keeps

Each line of `fields.txt` is `<file> <keep|drop> <path>`:

- `<file>` is `profile.json`, `settings.json`, or `routine` (front matter).
- `<path>` is a JSON field path joined with `.`, with `[]` for any array
  index. A `drop` also covers every field under its path.

The script stops on any field that `fields.txt` neither keeps nor drops, and
names the field. Add it as `keep` if it can never hold a credential,
otherwise as `drop`, then rerun.

Before showing any change, the script scans every file it would write for
tokens, private keys, credential assignments, and the word `serverId`. On a
match it stops and prints the file and line number, never the matched text.

The ledger never reaches git. The script reads it only to write
`shared/unsettled-threads.shape.json`. In that file, each value is replaced by
its type, such as `"string"`. Each array collapses to a single element. An
object whose keys aren't plain words, such as thread ids, collapses to a single
`"<key>"` entry. A diff in this file means the ledger's format changed.

## Roll back

To restore a fleet to a commit, check that commit out in a separate worktree
and print each file the profile has there with
`DOTFILES_PROFILE=<profile> ./install.sh --show bots/<path>`. Give those files
to Workflowy and ask it to re-apply them through each bot. This changes live
bots, so confirm the commit and the bots first. Fields the snapshot drops,
such as `serverId`, aren't in git and stay as they are on the box.

Then take a new snapshot. Its list shows no changes for the bots that were
restored completely.
