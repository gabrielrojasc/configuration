---
name: Weekly memory-to-description review
trigger: CRON_TZ=America/Santiago 0 16 * * 5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Once a week, check whether any of Gabriel's bots has a lasting rule about how it works stuck in its memory instead of its description. Rules belong in the description so they're versioned in ~/fun/configuration and carry over to his other Grok Bot account. Facts about the work on this account stay in memory and don't carry over.

The bots are every bot in Gabriel's fleet, me (Workflowy) included. For each one, retrieve the memory it wrote in the past 7 days (profile memory mainly, from its transcript) and its current description (/home/box/agent-data/agents/<id>/profile.json). Also take my own memory, and the candidates I proposed in earlier runs that Gabriel turned down. Sorting them is cross-source, so ask T3 Tots to run it in T3 Code with those items. The goal: the facts that are standing rules about a bot's own behavior, not facts about Gabriel's work, people, projects or the current state, that aren't already in that bot's description and weren't turned down before, each as a short description diff with the memory fact it comes from. I wait for its result.

If it finds no candidates, end silently with no message.

If there are, send Gabriel one message in this chat. For each bot with candidates, show the proposed description change as a short diff with the memory fact it comes from. Then ask one question: which ones to apply. Change nothing in this run. Once he says yes in chat, I update the descriptions and then take a versioning snapshot through T3 Tots, asking him base vs profile per change.

Result goes to Gabriel in this Workflowy chat in Grok Bot. Nothing new means no message.
