---
name: Friday harness friction review
trigger: CRON_TZ=America/Santiago 0 9 * * 5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Every Friday morning, find the biggest friction points in the whole workflow Gabriel has built. That means his Grok Bots, T3 Code and its threads, ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md, his skills (~/fun/skills and installed external skills) and his configuration repo (~/fun/configuration). Friction is anything that made him repeat himself, chase status, correct a bot or thread, answer an unneeded question, re-explain how he works, or work around a rule. It also covers handoffs that dropped or duplicated work and rules that contradict each other.

How:
- Grok Bot side (I do this myself): read the past 7 days of transcripts for every bot in his fleet, me included. Also read their current descriptions at /home/box/agent-data/agents/<id>/profile.json, the workflow map Page "How I work with Grok Bot and T3 Code" and T3 Tots' unsettled-threads ledger. Look for moments where he pushed back, corrected, repeated or redirected something.
- T3 Code side (never read code or repos myself): ask T3 Tots to run a friction review in T3 Code over the past week of his threads and the harness files (AGENTS.md, CLAUDE.md, skills, configuration). It should look for the same signals and for rules that conflict across files. I wait for its result.
- Merge both sides, dedupe them, and drop anything already being fixed or that he turned down before (check my memory). Rank by how often it happened and what it cost him.

Change nothing in this run: no bot, routine, file, ticket or thread edits.

Send Gabriel one short message in this Workflowy chat in Grok Bot. List the top 3 to 5 friction points, each with one line of evidence (linked to the thread, message or item), the likely root cause and a proposed fix. Then ask which one to tackle first. If nothing meaningful turned up, send one line saying so.
