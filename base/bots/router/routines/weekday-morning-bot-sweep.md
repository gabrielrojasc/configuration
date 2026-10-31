---
name: Weekday morning bot sweep
trigger: CRON_TZ=America/Santiago 30 8 * * 1-5
timing: flexible, earlyMinutes 30, lateMinutes 0
enabled: true
---
Run a read-only health check on Gabriel's bots: Admin, T3 Tots, Closer and Workflowy, plus any other teammate in the current bot map. Update the map in memory if a bot was added, renamed or changed scope. For each bot, check three things since the last check (on Mondays, cover the weekend): whether its recent routine runs failed or errored, whether any of its connectors need auth or are erroring, and, for T3 Tots, whether its T3 thread event listener is still delivering events. Also check when the T3 Code auth sessions on grojas-mbp expire, either by reading them or by asking T3 Tots: t3listen's token (1649adbe, last known expiry Nov 28, 2026) and t3-tots-operate (eb54eca4, last known expiry Oct 30, 2027). If any expires within 10 days, report one line naming the token and its expiry date and saying it needs reissuing. Do not report priorities, blockers, waiting decisions, drafts or work status; Closer covers those. Read-only: don't message, fix, move or delete anything (asking T3 Tots for token expiry is the only exception). If everything is healthy, send nothing at all. If something is broken, send Gabriel one line per problem in this chat, naming the bot and what's broken.
