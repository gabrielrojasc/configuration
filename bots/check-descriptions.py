#!/usr/bin/env python3
"""Compare a box's live Grok Bot descriptions with the bundle this script ships in.

Usage: python3 check-descriptions.py [--diff]

Reads the bundle next to this file, written by bots/descriptions.sh --stage,
and prints one line per bot. It changes no bot. --diff also prints, for each
bot that differs, the sentences to take out (-) and to put in (+). A heading
prints as a line of its own, and a list item's first sentence keeps its mark.

Exits 0 when every description matches, 1 when any differs, and 2 when the
bundle or a bot's profile can't be read. BOT_AGENTS_LIVE overrides the live
agents folder.

Needs Python 3.8 or later and only its standard library.
"""
import difflib
import hashlib
import json
import os
import pathlib
import re
import sys

BUNDLE = pathlib.Path(__file__).resolve().parent
LIVE = pathlib.Path(os.environ.get("BOT_AGENTS_LIVE", "/home/box/agent-data/agents"))
SENTENCE_END = re.compile(r"(?<=[.?!]) (?=[A-Z`(\"'$])")
LIST_NUMBER = re.compile(r"[0-9]+\. ")


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(2)


def stored(text):
    return text[:-1] if text.endswith("\n") else text


def load_bundle():
    wanted = {}
    for line in (BUNDLE / "descriptions.txt").read_text("utf-8").splitlines():
        words = line.split()
        if len(words) != 3:
            fail(f"BAD_MANIFEST descriptions.txt: {line}")
        slug, bot_id, pin = words
        path = BUNDLE / f"{slug}.txt"
        if not path.is_file():
            fail(f"MISSING_IN_BUNDLE {slug}")
        text = stored(path.read_text("utf-8"))
        if hashlib.sha256(text.encode("utf-8")).hexdigest() != pin:
            fail(f"HASH_MISMATCH {slug}: the bundle doesn't match descriptions.txt")
        wanted[slug] = (bot_id, text)
    if not wanted:
        fail("EMPTY_MANIFEST: descriptions.txt lists no bots")
    return wanted


def sentences(text):
    lines = []
    for paragraph in text.strip().split("\n\n"):
        for line in paragraph.split("\n"):
            number = LIST_NUMBER.match(line)
            mark = number.group(0) if number else ""
            parts = SENTENCE_END.split(line[len(mark):])
            parts[0] = mark + parts[0]
            lines += [part.strip() for part in parts]
        lines.append("")
    return lines[:-1]


def changes(live, wanted):
    diff = list(difflib.unified_diff(sentences(live), sentences(wanted), lineterm="", n=0))
    return [line for line in diff[2:] if line[:1] in ("+", "-")]


def main():
    show = "--diff" in sys.argv[1:]
    if set(sys.argv[1:]) - {"--diff"}:
        fail(__doc__)
    wanted = load_bundle()
    matches, differs, missing = [], {}, []
    for slug, (bot_id, text) in wanted.items():
        profile = LIVE / bot_id / "profile.json"
        if not profile.is_file():
            missing.append(slug)
            continue
        try:
            data = json.loads(profile.read_text("utf-8"))
        except ValueError:
            fail(f"UNREADABLE {slug}: its profile.json isn't valid JSON")
        if not isinstance(data, dict):
            fail(f"UNREADABLE {slug}: its profile.json isn't a JSON object")
        live = data.get("description")
        live = live if isinstance(live, str) else ""
        if live == text:
            matches.append(slug)
        else:
            differs[slug] = changes(live, text)
    print(f"descriptions vs bundle: {len(wanted)} listed, {len(matches)} match, {len(differs)} differ, {len(missing)} missing")
    for slug, lines in differs.items():
        took_out = sum(line.startswith("-") and len(line) > 1 for line in lines)
        put_in = sum(line.startswith("+") and len(line) > 1 for line in lines)
        note = f"-{took_out}/+{put_in} sentences" if took_out or put_in else "spacing or line breaks only"
        print(f"differs: {slug} ({note}); set it to {slug}.txt")
        if show:
            for line in lines:
                print(f"  {line}")
    for slug in missing:
        print(f"missing: {slug}, no bot with the id descriptions.txt gives it")
    if differs or missing:
        sys.exit(1)
    print("OK: every description matches")


if __name__ == "__main__":
    try:
        main()
    except OSError as error:
        fail(f"UNREADABLE {error}")
