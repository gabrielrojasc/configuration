# Grok Bot setup

This repository records each Grok Bot fleet's setup: every bot's profile,
settings, and routines, plus the setup map and the format of the
unsettled-threads ledger. It uses the same base and patch model as the
dotfiles, and `DOTFILES_PROFILE` picks the profile in the same way.

Each fleet's box is the source of truth. Changes flow one way, from a fleet
into git. The app can't import from git, and `install.sh` never installs these
files. Skills are the exception: the repository declares them, as described in
[Bot skills](#bot-skills).

To install these bots on a new Grok Bot account, see [INSTALL.md](INSTALL.md).

## Layout

```text
base/bots/
├── <slug>/
│   ├── profile.json
│   ├── settings.json
│   └── routines/<routine>.md      # absent when the bot has none
└── shared/
    ├── skills.txt                   # the skills every box has, pinned
    └── unsettled-threads.shape.json # the ledger's format, decided here
profiles/<profile>/
├── bots.txt                         # this profile's fleet: "<slug> <bot id>" per line
├── bots/<path>                      # files only this profile has
├── bots/shared/setup-map.md         # copied from this fleet's box
├── bots/shared/workflow-map.md      # how work moves through the bots and T3 Code; placed by hand
└── patches/bots/<path>.patch        # this profile's changes to base/bots, including deletions
bots/
├── snapshot.sh                      # brings a staged snapshot into the repo
├── fields.txt                       # the fields a snapshot keeps
├── skills.sh                        # pins skills and builds the bundle for a box
├── check-skills.py                  # runs on a box; compares live skills with the bundle
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
   > `<id>/`. Ask each bot to report its own routines, paused ones included:
   > for each routine its name, folder id, trigger, whether it's enabled, and
   > its full saved prompt, or that it has no routines. Write each routine to
   > `<id>/routines/<slug>.md` in the routine format below, and the bot's
   > report to `<id>/routines.json` in the routine report format below. Copy
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

Of `bots/shared/`, a snapshot handles only `setup-map.md`. It never lists,
records, or deletes any other file there, such as a profile's
`workflow-map.md`.

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
    ├── routines.json    # the bot's own report of its routines
    └── routines/        # optional when the report lists none
        └── <slug>.md    # lowercase letters, digits, and hyphens
```

The script stops before showing or writing anything unless all of these hold:

- The staging folder is outside the repository.
- Every bot in `bots.txt` has `profile.json`, `settings.json`, and
  `routines.json`. A bot without a report has unverified routines, even with
  an empty `routines/`, so the snapshot never reads its missing routines as
  deleted.
- Each report is valid, and lists exactly the routine files staged for its
  bot.
- The folder holds nothing else, such as a bot's memory.
- Every field is listed in `fields.txt`.
- The ledger matches its format, as [Ledger format](#ledger-format) describes.
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

## Routine report

Each bot reports its own routines in `routines.json`. The report states who
reported and when, and lists each routine's file:

```json
{
  "reportedBy": "Router",
  "reportedOn": "2026-11-07",
  "confirmedBy": "Gabriel",
  "routines": [
    {"file": "daily-sweep.md", "folderId": "daily-sweep"}
  ]
}
```

- `reportedBy` is the bot's `name` from its `profile.json`.
- `reportedOn` is the date of the report, as `YYYY-MM-DD`.
- `confirmedBy` is optional. It names who confirmed the report, and how.
- `routines` lists each routine's file in `routines/` and its `folderId`, the
  slug of the routine's folder on the bot, such as `weekday-morning-bot-sweep`.
  The folder slug identifies the routine, so take it from the bot's report and
  never guess one. `routines` is `[]` when the bot reports no routines.

The routine files hold each routine's name, trigger, state, and prompt. The
report never reaches git: `--list` prints a line for each bot, such as
`router: 1 routine, reported by Router on 2026-11-07, confirmed by Gabriel`.

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

### Ledger format

The ledger never reaches git. The script only checks it against
`shared/unsettled-threads.shape.json`, which the repository decides, like the
skills manifest. The file lists each top-level field and each thread entry's
field, under `"<thread id>"`, with its type:

- `"string"`: a non-empty string.
- `"boolean"`.
- `"string[]"`: a list of non-empty strings, `[]` when there are none.
- A list of strings: one of those values, as for `status`.
- `|null` after a type: null is allowed too.

Every entry has every field. The script stops on a missing field, an unknown
field, or a value of the wrong type, and lists each one by thread id, never
with its value.

T3 Tots runs the same check before it writes the ledger, with the
`ledger-check.py` script that its `t3-questions-to-chat` routine pins by
sha256. The script also gives each entry's fingerprint, a hash of its status
and decision, which T3 Tots stores in `notifiedFingerprint` when it hands an
entry to the closer, and hands it over again only when the fingerprint
changes. To change the format, edit this file and the routine's script
together, then update the routine's sha256; `tests/e2e.sh` fails when they
differ.

### Machine IDs

A routine can name a Mac by its machine ID. This repository is public, so the
ID stays on your machine. List it in
`~/.local/state/dotfiles/bots/<profile>.machine-ids`, one ID per line. The
file is on each machine that takes snapshots, and it's never in git.

The script replaces each listed ID with `<machine-id>` in its own copies of the
staging folder and the last snapshot, before it merges them. The repository
and the last snapshot hold only the placeholder. The staging folder and the
live bot keep the real ID. A last snapshot that still has a listed ID is
cleaned by the next snapshot or by `--sync-record`.

A snapshot stops when it finds a machine ID the file doesn't list, next to a
label such as `machineId`. It prints the file and line number, never the ID.
It can't recognize an ID with no label beside it, so list every ID your
routines use.

Before you save a rendered routine to a live bot, replace `<machine-id>` with
the real ID from that file.

## Bot skills

`bots/shared/skills.txt` lists the skills a box has. Each section names a source
and its pin, followed by one `<skill id> <sha256>` line per skill:

```text
source gabrielrojasc/skills skills/bots main a03cc655a71fa7ab81a64ab0c5f3c982c15c738c
open-items 5366c335b554c97748f3ef731dc2ba8251198b3e66536f2eed4e7a999d19dacb
```

The source line is `source <repo> <folder> <ref> <commit>`. A skill's file is
`<folder>/<skill id>/SKILL.md` at `<commit>`. The ref records what `--bump`
follows, and the commit and sha256 decide what gets installed. Each skill is
one `SKILL.md`, with `name` and `description` as its only frontmatter, because
that's all `UpdateSkill` can write. The `name` must match the skill's folder.

A profile that needs a different set changes it with a patch, like any other
key. To print a profile's set, run:

```sh
./install.sh --show bots/shared/skills.txt
```

`install.sh` can't reach a box, and a bot's main agent is the only writer of its
skills, so you apply the set through Workflowy. All the bots on a box share its
skills, so apply it once per box.

### Apply the skills to a box

1. Build the bundle on the Mac. This downloads each skill at its pin and writes
   nothing unless every sha256 matches:

   ```sh
   staging=$(mktemp -d)
   bots/skills.sh --stage "$staging"
   ```

2. Ask Workflowy's main agent to check the box. A subagent can't call
   `UpdateSkill`:

   > Delete `/workspace/uploads/bot-skills` if it exists. CopyToBox
   > `<staging-folder>` with `box_path` `/workspace/uploads/bot-skills`. Run
   > `python3 /workspace/uploads/bot-skills/check-skills.py --plan` and show me
   > its output. Change nothing yet.

3. Read the output. Each line names a skill:

   - `missing` and `changed`: the plan writes them.
   - `unreadable` and `collision`: the plan leaves them out. Fix them by hand,
     because the check can't tell which copy you want.
   - `unlisted, left alone`: the box has a skill the set doesn't list. The check
     never removes one.

   A `changed` t3-\* skill can mean the box moved past the pin. Compare
   `/workspace/t3-tots-tools/VERSION` with the manifest's tag. If the box is
   ahead, [bump the pin](#bump-a-pin) instead of applying the plan.

4. Ask Workflowy to apply the plan:

   > Apply `plan/PLAN.json` in order. For each entry, call `UpdateSkill` with
   > action `write` and the `name`, `description`, and `body` from its file.
   > Pass `id` when `new` is false, and omit it when `new` is true. Then run
   > `check-skills.py` again and show me its output.

   The last line must read `OK: every listed skill matches`. A partly applied
   plan is safe to finish: rerun step 2, and the new plan holds only what's left.

5. If the plan wrote `t3-install-tools`, or the box has no
   `/workspace/t3-tots-tools/`, ask T3 Tots to follow that skill's "Box copy"
   section. That installs the helper scripts from the same release. A computer
   that hasn't set up T3 Tots needs `t3-getting-started` as well.

A skill you drop from the manifest stays on the box as `unlisted` until you
remove it by hand.

### Check a box for drift

Run step 2 without `--plan`. The script changes nothing, so a bot can run it at
any time. It exits with `0` when every listed skill matches, `1` when any
differs, and `2` when it can't read the bundle or the live skills.

The check compares each skill's `name`, `description`, and body, because
`UpdateSkill` can rewrite the frontmatter and a raw sha256 of a live file would
report that as drift. It reads the common YAML forms of those two fields and
lists any other form as `unreadable`. The sha256 pins cover the files the Mac
downloads and the copy that reaches the box.

### Bump a pin

A bump moves a source to the commit its ref points at, and records every skill
there, so a skill added to `skills/bots` joins the set:

```sh
bots/skills.sh --bump gabrielrojasc/skills
bots/skills.sh --bump Deepusleepy/t3-tots v1.4.31
```

A tag doesn't move, so a t3-tots bump needs the new tag. List the latest one
with `gh release view -R Deepusleepy/t3-tots --json tagName`.

The script edits `base/bots/shared/skills.txt` and warns when a profile no longer
renders it. Review `git diff`, commit, then apply the skills to each box. A
`t3-install-tools` skill pins its own tag, so a bump also moves that pin once
step 5 runs. Neither fleet's last snapshot has a T3 Tots weekly update routine.
Turning one on, or asking T3 Tots to update, moves a box past the pin.

## Roll back

To restore a fleet to a commit, check that commit out in a separate worktree
and print each file the profile has there with
`DOTFILES_PROFILE=<profile> ./install.sh --show bots/<path>`. Give those files
to Workflowy and ask it to re-apply them through each bot. This changes live
bots, so confirm the commit and the bots first. Fields the snapshot drops,
such as `serverId`, aren't in git and stay as they are on the box. Replace any
`<machine-id>` first, as [Machine IDs](#machine-ids) describes.

Then take a new snapshot. Its list shows no changes for the bots that were
restored completely.
