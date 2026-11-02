# Install the Grok Bot setup

This guide sets up the bots recorded in this repository on a Grok Bot account.
The app can't import from git, so you create each bot from the files a profile
renders, record the new bot ids, and then take snapshots as described in
[README.md](README.md).

## Before you start

You need:

- A Grok Bot account where you can create bots and routines.
- This repository, with `jq` installed. `bots/snapshot.sh` uses it.

Read each bot's description and routines before you create it. They name the
connectors, tools, and file paths the bot relies on, such as a Linear team or
a file on the account's box. Set those up on the account, or change the text
for the profile as described in [Adapt the text](#adapt-the-text).

## Pick a profile

A profile holds one fleet: the bots on one account. Bot ids belong to that
account, so two accounts never share a profile's `bots.txt`.

- To install a profile's fleet on a new account that replaces its old one,
  use that profile.
- To add an account, add a profile for it: create `profiles/<profile>/`. The
  bot scripts need nothing else in it until you record the bot ids. The new
  folder is also a dotfiles profile, but the steps in this guide never run
  `install.sh --apply`.

Select the profile for every command below, either in `.env` or per command:

```sh
echo 'DOTFILES_PROFILE=<profile>' > .env
```

## Choose the bots

Each folder in `base/bots/` other than `shared/` is a bot, and a profile can
add its own bots in `profiles/<profile>/bots/`. The folder name is the bot's
slug. A profile leaves out a base bot or routine with a patch that deletes it.

To print the file a profile has, run:

```sh
./install.sh --show bots/<slug>/profile.json
```

If the profile deletes that file, the command says so instead.

## Adapt the text

The base files describe one person's bots without naming any account: they
say "his main line" and "his Mac" where a profile names its Linear teams,
inboxes, Slack workspace, machine, and T3 threads. Decide for each change
whether every profile should get it:

- A change for every profile goes in `base/bots/<path>`. Check that each
  profile with a fleet still renders the file with `--show`.
- A change for this profile only goes in its patch. Write the full file the
  profile should have to `.conflicts/bots/<path>`, then run
  `./copy.sh --resolve bots/<path>`, which writes the patch.
- A bot or routine only this profile has goes in
  `profiles/<profile>/bots/<path>`.

Name other bots by their `name` only, never by bot id. Bot ids live only in
`bots.txt`. Never put a credential in a description or routine: snapshots
copy both into git.

## Create the bots

Create each bot you chose, in any order. Bots refer to each other by name, so
give each bot exactly the `name` in its rendered `profile.json`.

1. Print the bot's profile and settings:

   ```sh
   ./install.sh --show bots/<slug>/profile.json
   ./install.sh --show bots/<slug>/settings.json
   ```

2. In the app, create the bot with the description, name, title, avatar, and
   harness from `profile.json`, and set each option in `settings.json`. Leave
   any field the profile leaves empty at the app's default.
3. Print each of the bot's routines, from `bots/<slug>/routines/`:

   ```sh
   ./install.sh --show bots/<slug>/routines/<routine>.md
   ```

4. Ask the bot to save each routine. Give it the front matter values (`name`,
   `trigger`, `timing`, `enabled`) and the body after the second `---` line as
   the prompt, word for word. A routine with `enabled: false` is saved paused.

The app gives each bot a `serverId`. It stays on the account: `fields.txt`
drops it from every snapshot.

Once one bot can edit others, as Workflowy does, you can instead give it the
rendered files and ask it to apply them through each bot. Check each bot
afterwards; the snapshot in the last step shows anything it missed.

### Shared files

`shared/setup-map.md` is a document the bots read on the account's box. Copy
the rendered file to the path the routines name for it. A profile without its
own map has none to copy: ask T3 Tots to build one, and the next snapshot adds
it to the profile.

`shared/unsettled-threads.shape.json` records only the format of the
unsettled-threads ledger, the live list of threads waiting on the owner. Don't
copy a ledger between accounts. A new account starts with an empty ledger.

## Record the bot ids

Write one line per bot to `profiles/<profile>/bots.txt`, with the slug and the
bot id the account gave it. If the file lists an old account's bots, replace
them:

```text
router <bot id>
closer <bot id>
```

The bot id is the bot's agent id: the folder name of the bot under the box's
`agent-data/agents/` folder. A bot missing from `bots.txt` is outside the
fleet, and `bots/snapshot.sh` ignores it.

## Start taking snapshots

When the account matches what the profile renders, record that as the fleet's
starting point:

```sh
bots/snapshot.sh --seed
```

The record lives on the machine you run it on, in
`~/.local/state/dotfiles/bots/<profile>/`. Seed again on any other machine
before its first snapshot from this fleet.

Then take a snapshot as described in [Take a snapshot](README.md#take-a-snapshot).
If every bot matches the repository, `--list` prints `No changes.` Any change
it lists is a difference between the account and the repository: fix the bot,
or sort the change into base or the profile.

Commit `profiles/<profile>/bots.txt` and any patches you made, together.
