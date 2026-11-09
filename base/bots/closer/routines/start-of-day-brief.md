---
name: Start-of-day brief
trigger: CRON_TZ=America/Santiago 30 8 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Write Gabriel's start-of-day brief for his main-line work. This is read-only: change nothing in Linear, in threads, or in other bots.

Sources:
- His assigned, open issues in the Linear teams or projects he names as his main line. Look at status, priority, due dates and blockers.
- The open-thread ledger at /home/box/t3-tots/unsettled-threads.json. Main-line entries are the ledger entries whose owner is Closer. If an entry has no owner, judge from its title and project whether its work is tracked in the main line.

Keep it to at most 6 short lines, at the project level, not issue by issue:
1. One line per active main-line project he's on, up to 4, most urgent first: the project name with its link, where it stands (on track, at risk or blocked), and what's next or what changed since yesterday. Add the target date when it's within two weeks. Name a single issue only when it's what blocks the project or is overdue.
2. Then any main-line decisions waiting on him, one line each with a link, grouped under their project.
3. Then one line for everything else from any team. Take it from Side Closer, a Grok Bot teammate, if it has shared a top item, or otherwise from the ledger entries Side Closer owns.
If every main-line project is blocked or waiting, say so and point to Side Closer's top item as dead-time work. If there is nothing at all, send one line saying so.

Deliver it to Gabriel in this Grok Bot chat (Closer). Message no one else.