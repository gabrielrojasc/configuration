---
name: Friday harness friction review
trigger: CRON_TZ=America/Santiago 0 9 * * 5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Every Friday morning, find the biggest friction points in the whole workflow Gabriel has built. That means his Grok Bots, T3 Code and its threads, ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md, his skills (~/fun/skills and installed external skills) and his configuration repo (~/fun/configuration). Friction is anything that made him repeat himself, chase status, correct a bot or thread, answer an unneeded question, re-explain how he works, or work around a rule. It also covers handoffs that dropped or duplicated work and rules that contradict each other.

How:
- Grok Bot side (I do this myself, one bot at a time): for each bot in his fleet, me included, read its transcript for the past 7 days and list the moments where he pushed back, corrected, repeated or redirected something, one line each with its link. Also take each bot's current description from /home/box/agent-data/agents/<id>/profile.json, the text of the workflow map Page "How I work with Grok Bot and T3 Code", and, from my memory, what is already being fixed and what he turned down before.
- T3 Code side (never read code or repos myself): ask T3 Tots to run a friction review in T3 Code over the past week of his threads, T3 Tots' unsettled-threads ledger and the harness files (AGENTS.md, CLAUDE.md, skills, configuration). Give it my per-bot lists, the current bot descriptions, the Page text, and what is already being fixed or was turned down. The goal: the same signals and rules that conflict across files and descriptions, merged with my lists and deduped, without what is already being fixed or was turned down, ranked by how often it happened and what it cost him. I wait for its result.

Change nothing in this run: no bot, routine, file, ticket or thread edits.

Send Gabriel one short message in this Workflowy chat in Grok Bot. List the top 3 to 5 friction points, each with one line of evidence (linked to the thread, message or item), the likely root cause and a proposed fix. Then ask which one to tackle first. If nothing meaningful turned up, send one line saying so.
- Messaging check: count T3 Tots' chat messages per bot-started turn, messages to Gabriel per T3 hand-off, and characters per settle request.
List any decision that reached him without the thread's recommendation, and any thread that went past a limit it was sent.
Put these counts in the message too.
