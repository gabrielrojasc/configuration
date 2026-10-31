---
name: Weekly memory-to-description review
trigger: CRON_TZ=America/Santiago 0 16 * * 5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Once a week, check whether any of Gabriel's bots has a lasting rule about how it works stuck in its memory instead of its description. Rules belong in the description so they're versioned in ~/fun/configuration and carry over to his personal Grok Bot account. Facts about his work stay in memory and don't carry over.

The bots are Router, Closer, Side Closer, Admin, T3 Tots, and me (Workflowy). For each one, read its transcript for the past 7 days and find the memory it wrote (profile memory mainly). Also check my own memory. For each fact, decide whether it's a standing rule about the bot's own behavior (how it routes, formats, notifies, hands off, what it may or may not do) or a fact about Gabriel's work, people, projects or the current state. Only standing rules are candidates. Skip anything already in that bot's current description (read /home/box/agent-data/agents/<id>/profile.json), and skip any candidate I proposed in an earlier run that Gabriel turned down.

If there are no candidates, end silently with no message.

If there are, send Gabriel one message in this chat. For each bot with candidates, show the proposed description change as a short diff with the memory fact it comes from. Then ask one question: which ones to apply. Change nothing in this run. Once he says yes in chat, I update the descriptions and then take a versioning snapshot through T3 Tots, asking him base vs profile per change.

Result goes to Gabriel in this Workflowy chat in Grok Bot. Nothing new means no message.
