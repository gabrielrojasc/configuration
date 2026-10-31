---
name: Start-of-day brief
trigger: CRON_TZ=America/Santiago 30 8 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Write Gabriel's start-of-day brief for his Executive Protection (EP) team work. This is read-only: change nothing in Linear, in threads, or in other bots.

Sources:
- His assigned, open issues in the EPL Linear team of the zerofox workspace, including its projects such as EU PII and ep-api. Look at status, priority, due dates and blockers.
- The open-thread ledger at /home/box/t3-tots/unsettled-threads.json. EP entries are the ones tagged 'ep'. If an entry has no tag, judge from its title and project whether it is EP work.

Keep it to at most 6 short lines:
1. His top 3 EP items to work on today, one line each with a link. Put overdue and soon-due items first, then higher priority, then In Progress or Peer Review ahead of To-do. Skip items that are blocked or waiting on someone else.
2. Then any EP decisions waiting on him, one line and a link each, from the ledger.
3. Then one line for everything outside EP (DMI, Cosmos, EKS, OSIS, ops, investigations, other teams' PR reviews, his own tooling). Take it from Side Closer, a Grok Bot teammate, if it has shared a top item, or otherwise from the ledger's 'other' or non-EP entries.
If every EP item is blocked or waiting, say so and point to Side Closer's top item as dead-time work. If there is nothing at all, send one line saying so.

Deliver it to Gabriel in this Grok Bot chat (Closer). Message no one else.
