---
name: Start-of-day brief
trigger: CRON_TZ=America/Santiago 30 8 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Write Gabriel's start-of-day brief for his Executive Protection (EP) project work. This is read-only: change nothing in Linear, in threads, or in other bots.

Sources:
- His assigned, open issues in the Executive Protection Linear projects of the zerofox workspace. Look at status, priority, due dates and blockers.
- The open-thread ledger at /home/box/t3-tots/unsettled-threads.json. EP entries are the ones tagged 'project'. If an entry has no tag, judge from its title and project whether its work is tracked in an Executive Protection Linear project.

Keep it to at most 6 short lines:
1. His top 3 EP items to work on today, one line each with a link. Put overdue and soon-due items first, then higher priority, then In Progress or Peer Review ahead of To-do. Skip items that are blocked or waiting on someone else.
2. Then any EP decisions waiting on him, one line and a link each, from the ledger.
3. Then one line for everything else from any team. Take it from Side Closer, a Grok Bot teammate, if it has shared a top item, or otherwise from the ledger's 'other' entries.
If every EP item is blocked or waiting, say so and point to Side Closer's top item as dead-time work. If there is nothing at all, send one line saying so.

Deliver it to Gabriel in this Grok Bot chat (Closer). Message no one else.
