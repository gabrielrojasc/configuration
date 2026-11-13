---
name: Start-of-day brief
trigger: CRON_TZ=America/Santiago 30 8 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Write Gabriel's start-of-day brief: one overview of what every bot on this account holds for him. This is read-only: change nothing in Linear, in T3 threads, in the ledger or in other bots, and message no bot.

Sources, and stop there:
- The ledger at /home/box/t3-tots/unsettled-threads.json, every entry whatever its owner. Use each entry's owner, status, decision, followUp, updatedNote and links. For an entry with owner none, judge its lane from its title and project.
- Gabriel's assigned, open issues in every active RunMyDay Linear team of the runmyday workspace: runmyday, CSByte, XS Market, Agentic Software Factory and Case Tracker. Skip the retired FamilyFlow and AccountingFlow teams. Look at status, priority, due dates and blockers. These are Closer's items.
- What each bot has asked him lately: read the newest 40 messages of each of these chats with ReadTranscript: Closer (6b22314a-5e17-4266-8e78-9afed6a5c9b2), Side Closer (3f7e54b1-66d5-4622-9d08-78e600b287e4), Spark (5756883a-a86c-4b4d-b973-0d286690fc48), Kaizen (a832f69a-a989-4199-9be3-5b825b9f8777), Workflowy (c4bb9bbd-c08d-4679-944d-0c03730abc5e) and T3 Tots (76f0192a-0324-4ab4-9f19-4ec925dc57f2). Keep only decisions or replies a bot asked him for that he hasn't given, and work a bot said is blocked or overdue.
- You may open a linked ticket, PR or thread to judge its state, with at most two read-only calls per item. Don't search past that. If an item stays unclear, list it and say which bot to ask.

Write one flat list, ranked by what needs Gabriel first: decisions and replies only he can give, then blocked or overdue work, then what moves next. Among equals, put first what unblocks the most work, then what matters most for RunMyDay customers or his job search, then the nearest deadline, and quick ones first when the rest is equal. No bot, project or team headings, and no grouping. At most 6 items in total.
- Each item is one or two plain, complete sentences: what it is, why it matters today, and the next step. Write so he understands it cold, without shorthand or internal jargon.
- Start each item by tagging the bot that owns it with @ and its exact name, such as @Closer.
- Link each item by the real name of what the link opens (the ticket's title, the PR's title, the thread's title), never by a bare ID, team or project name.
- List an item once, even if the ledger and a bot's chat both show it.
After the list, one line naming the bots with nothing for him today, such as "Nothing from @Spark or @Kaizen today." If nothing can move without him, say so and point to the best dead-time work.
Only if you saw it while reading the sources above: one last line per broken thing, such as a bot's chat showing a failed routine run or a connector that needs sign-in, or a ledger whose updatedAt is more than a day old (T3 Tots may have stopped updating it). Tag the bot and say what's broken. Don't run any other check for this.
From Nov 22 through Dec 1, 2026, add one last line: "@Workflowy: the T3 Tots session expires Dec 2 at 12:01 AM Chile time and needs renewing."
Whenever the run can't read the bots' chats, end the brief with this last line: "Couldn't read bot chats today, so chat-only items may be missing."
If there is nothing at all, send one line saying so.

Deliver it to Gabriel in this chat (Chief of Staff). Message no one else.
