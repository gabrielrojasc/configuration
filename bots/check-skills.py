#!/usr/bin/env python3
"""Compare a box's live Grok Bot skills with the bundle this script ships in.

Usage: python3 check-skills.py [--plan]

Reads the bundle next to this file, written by bots/skills.sh --stage, and
prints every difference. It changes no live skill. Skills the bundle doesn't
list are reported and left alone. --plan also writes plan/PLAN.json and one
plan/<id>.json per skill for the main agent to apply with UpdateSkill.

Exits 0 when every listed skill matches, 1 when any differs, and 2 when the
bundle or the live skills can't be read. BOT_SKILLS_LIVE overrides the live
skills folder.

Needs Python 3.8 or later and only its standard library.
"""
import difflib
import hashlib
import json
import os
import pathlib
import re
import shutil
import sys

BUNDLE = pathlib.Path(__file__).resolve().parent
LIVE = pathlib.Path(os.environ.get("BOT_SKILLS_LIVE", "/home/box/agent-data/workflows"))
FRONTMATTER = re.compile(r"---\n(.*?)\n---\n?(.*)", re.S)
BLOCK_SCALARS = (">", ">-", "|", "|-")
PINNED_RULES = re.compile(r"(PINNED = \{\n)(.*?)(\n\})", re.S)


def double_quoted(raw):
    joined = re.sub(r"\\\n\s*", "", raw).replace("\\ ", " ")
    return json.loads(" ".join(part.strip() for part in joined.split("\n")))


def scalar(raw):
    value = " ".join(part.strip() for part in raw.split("\n") if part.strip())
    if value.startswith('"'):
        return double_quoted(raw)
    if value.startswith("'"):
        if len(value) < 2 or not value.endswith("'"):
            raise ValueError("unterminated quote")
        return value[1:-1].replace("''", "'")
    return value


def parse(text):
    match = FRONTMATTER.match(text.replace("\r\n", "\n"))
    if not match:
        raise ValueError("no frontmatter")
    fields, key, parts = {}, None, []

    def finish():
        if key is None:
            return
        if parts[0] in BLOCK_SCALARS:
            value = " ".join(parts[1:])
        elif key in ("name", "description"):
            value = scalar("\n".join(parts))
        else:
            value = " ".join(parts)
        fields[key] = " ".join(value.split())

    for line in match.group(1).split("\n"):
        if line[:1] in (" ", "", "-") and key is not None:
            parts.append(line)
            continue
        finish()
        key, separator, value = line.partition(":")
        if not separator or not key:
            raise ValueError(f"unsupported frontmatter line: {line}")
        parts = [value.strip()]
    finish()
    if not fields.get("name") or not fields.get("description"):
        raise ValueError("frontmatter needs a name and a description")
    return fields, match.group(2).strip()


def comparable(skill_id, fields, body):
    # t3's skill sync rewrites this block in its manifest's order, so a synced
    # t3-install-tools can list the same rows in a different order.
    if skill_id == "t3-install-tools":
        body = PINNED_RULES.sub(lambda m: m.group(1) + ",\n".join(sorted(m.group(2).split(",\n"))) + m.group(3), body)
    return fields["name"], fields["description"], body


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(2)


def load_bundle():
    manifest = (BUNDLE / "skills.txt").read_bytes()
    if hashlib.sha256(manifest).hexdigest() != (BUNDLE / "skills.txt.sha256").read_text("utf-8").strip():
        fail("HASH_MISMATCH skills.txt: the bundle's manifest is damaged")
    pins = {}
    for line in manifest.decode("utf-8").splitlines():
        words = line.split()
        if len(words) == 2:
            pins[words[0]] = words[1]
    if not pins:
        fail("EMPTY_MANIFEST: skills.txt lists no skills")
    skills = {}
    for skill_id, pin in pins.items():
        path = BUNDLE / skill_id / "SKILL.md"
        if not path.is_file():
            fail(f"MISSING_IN_BUNDLE {skill_id}")
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != pin:
            fail(f"HASH_MISMATCH {skill_id}: the bundle doesn't match skills.txt")
        try:
            fields, body = parse(data.decode("utf-8"))
        except ValueError as error:
            fail(f"UNSUPPORTED_SKILL {skill_id}: {error}")
        extra = sorted(set(fields) - {"name", "description"})
        if extra:
            fail(f"UNSUPPORTED_SKILL {skill_id}: UpdateSkill can't write {', '.join(extra)}")
        skills[skill_id] = (fields, body)
    return skills


def load_live():
    if not LIVE.is_dir():
        fail(f"NO_LIVE_SKILLS {LIVE}")
    live, unreadable, raw = {}, {}, {}
    for folder in sorted(LIVE.iterdir()):
        path = folder / "SKILL.md"
        if not path.is_file():
            continue
        try:
            raw[folder.name] = path.read_bytes().decode("utf-8", "replace")
            live[folder.name] = parse(raw[folder.name])
        except (ValueError, OSError) as error:
            unreadable[folder.name] = str(error)
    return live, unreadable, raw


def holders_of(name, live, unreadable, raw):
    line = re.compile(rf"^name:\s*['\"]?{re.escape(name)}['\"]?\s*$", re.M)
    named = [other for other, found in live.items() if found[0]["name"] == name]
    return named + [other for other in unreadable if line.search(raw.get(other, ""))]


def describe_change(skill_id, wanted, found):
    want = comparable(skill_id, *wanted)
    have = comparable(skill_id, *found)
    lines = list(difflib.unified_diff(have[2].splitlines(), want[2].splitlines(), lineterm="", n=0))[2:]
    changed = [line[0] for line in lines if line[0] in "+-"]
    notes = [f"+{changed.count('+')}/-{changed.count('-')} lines"]
    notes += [field for field, a, b in zip(("name", "description"), have, want) if a != b]
    return ", ".join(notes)


def apply_order(skill_id):
    return skill_id != "t3-tots-rules", skill_id == "t3-install-tools", skill_id


def write_plan(skills, missing, changed):
    plan = BUNDLE / "plan"
    if plan.exists():
        shutil.rmtree(plan)
    if not missing and not changed:
        return
    plan.mkdir()
    steps = []
    for skill_id in sorted(list(missing) + list(changed), key=apply_order):
        fields, body = skills[skill_id]
        new = skill_id in missing
        entry = {"id": skill_id, "new": new, "name": fields["name"], "description": fields["description"], "body": body}
        (plan / f"{skill_id}.json").write_text(json.dumps(entry, indent=1), "utf-8")
        steps.append({"id": skill_id, "new": new, "file": f"{skill_id}.json"})
    (plan / "PLAN.json").write_text(json.dumps({"apply_in_order": steps}, indent=1), "utf-8")
    print(f"Plan: {plan}/PLAN.json. Apply {len(steps)} in order with UpdateSkill: pass id when new is false, omit it when new is true.")


def main():
    want_plan = "--plan" in sys.argv[1:]
    if set(sys.argv[1:]) - {"--plan"}:
        fail(__doc__)
    skills = load_bundle()
    live, unreadable, raw = load_live()

    matches, missing, changed, collisions = [], [], {}, {}
    for skill_id, wanted in skills.items():
        if skill_id in unreadable:
            continue
        if skill_id in live:
            if comparable(skill_id, *wanted) == comparable(skill_id, *live[skill_id]):
                matches.append(skill_id)
            else:
                changed[skill_id] = describe_change(skill_id, wanted, live[skill_id])
            continue
        holders = holders_of(wanted[0]["name"], live, unreadable, raw)
        if holders:
            collisions[skill_id] = holders
        else:
            missing.append(skill_id)

    claimed = {holder for holders in collisions.values() for holder in holders}
    unlisted = sorted((set(live) | set(unreadable)) - set(skills) - claimed)
    broken = sorted(set(skills) & set(unreadable))
    print(
        f"skills vs bundle: {len(skills)} listed, {len(matches)} match, {len(missing)} missing, "
        f"{len(changed)} changed, {len(broken)} unreadable, {len(collisions)} collisions, {len(unlisted)} unlisted"
    )
    for skill_id in sorted(missing):
        print(f"missing: {skill_id}")
    for skill_id, note in sorted(changed.items()):
        print(f"changed: {skill_id} ({note})")
    for skill_id in broken:
        print(f"unreadable: {skill_id} ({unreadable[skill_id]}); fix it by hand")
    for skill_id, holders in sorted(collisions.items()):
        print(f"collision: {skill_id} has the name of live skill {', '.join(holders)}; fix it by hand")
    for skill_id in unlisted:
        print(f"unlisted, left alone: {skill_id}")
    if want_plan:
        write_plan(skills, missing, changed)
    if missing or changed or broken or collisions:
        sys.exit(1)
    print("OK: every listed skill matches")


if __name__ == "__main__":
    try:
        main()
    except OSError as error:
        fail(f"UNREADABLE {error}")
