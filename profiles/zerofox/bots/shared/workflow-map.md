# How I work with Grok Bot and T3 Code

This document is the source of truth for how I work with my Grok Bots and T3
Code, and it is kept current with every bot or workflow change.

How I work with my Grok Bots and T3 Code, as of Nov 2: who takes each ask, how
work moves into T3 Code threads, which skills and habits I use there, where each
actor waits for my yes, and what is decided.

## Contents

- The whole flow
- Gates: what needs my yes
- T3 Code: skills and how I use them
  - How I talk to threads
  - full stop, step by step
  - pr-review and re-review
  - Thread patterns I actually ran
  - Thread types
  - My own skills
  - External skills I use
  - How skills install
- Routines and schedules
- Doors
- AGENTS.md and CLAUDE.md rules
- Listener, tokens and ledger
- Configuration and skills repos
- Decided

## The whole flow

Pick a flow to see the actors it passes through and every step: who does it,
how, where it waits for me, what comes back, and in which chat.

### The map

#### Me

- **Gabriel**: Brings the asks and makes every call: presses send on every
  draft, says yes before any one-way door, decides when a T3 thread is settled,
  answers y, n or q per configuration change. Also works in T3 Code directly,
  with no bot in between.

↓ Asks in Router's chat or a lane bot's chat, or opens a T3 thread himself

↑ Every decision and draft comes back to him, marked ↑ on each card

#### Where work comes from

- **Slack**: DMs, mentions, threads
- **Email**: Mail people send him
- **Linear**: Issues and projects
- **GitHub**: PRs and review requests
- **Calendar**: Meetings

↓ He drops what came in on Router. Bots read tickets, PRs and messages through
connectors.

#### Intake

- **Router**: Sorts each ask by project first and files it in one lane, then
  stays quiet. Never answers him; it only routes. Runs the weekday health check.
  ↑ One-line confirmation naming where it went. Asks only when it can't tell if
  something is Executive Protection project work.

↓ One-off questions to Spark; replies people are waiting on to the bot that owns
that work; everything else to the bot that owns its lane

#### Lanes

- **Closer**: Work tracked in an Executive Protection Linear project. ↑ What's
  next, decisions, settle questions, and the weekday brief: one line per active
  Executive Protection project, its decisions, then one line of other work
- **Side Closer**: Everything else from any team, except Workflowy's and
  Kaizen's areas. ↑ Answers, decisions, settle questions
- **Spark**: His one-off questions, answered and done. Most email and calendar
  work will likely land here. ↑ The answer; one line naming the bot that took
  any resulting work
- **Workflowy**: The bot setup and his workflow tooling. ↑ y, n or q per change,
  commit yes, settle questions, Friday friction points
- **Kaizen**: Career growth, learning and research, personal projects and
  decisions, second brain. ↑ The smallest next step, drafts, settle questions

↓ Code, repo and review work, his answers for a thread, and settle calls go to
T3 Tots. Bots stay read-only; the work happens in T3 Code.

↑ Results, decisions and done signals reach the bot that owns the thread, which
checks them before relaying

#### T3 Code operator

- **T3 Tots**: A proxy: picks or starts the right T3 Code thread, relays answers
  with t3ctl, keeps the setup map. ↑ Messages him only when he writes in its
  chat or it's urgent and no owning bot can reach him
- **T3 listener**: Watches T3 Code on his Mac and reports each question or
  finished thread to T3 Tots
- **Unsettled-threads ledger**: One entry per unsettled thread, with its owning
  bot

↓ `$pr-review <PR url>` in a new thread, `re-review` in the earlier one,
`<ticket> full stop` to build or fix, his answers, and settles

↑ Questions, verdicts and finished work, through the listener

#### T3 Code

- **Claude and Codex threads**: Do the real work under `~/.codex/AGENTS.md`:
  code, repos, reviews, docs. Full stop runs its own proof, cross-review and
  babysitting. Gabriel also opens and drives threads here himself.
- **Version Grok Bots in configuration**: The thread that snapshots bot changes
  into the configuration repo. ↑ His y, n or q per change, and a separate yes to
  commit and push

↓ Alone: two-way doors, such as their own branches, pushes, PRs and COMMENT
reviews. Wait for his yes: one-way doors, such as deploys, shared environments,
APPROVE or REQUEST_CHANGES and messages in his name.

#### Where work lands

- **GitHub**: Branches, PRs, reviews, commits
- **Linear**: Issues reach Done, the done signal
- **Deploys**: Prod and every shared environment
- **Configuration repo**: `~/fun/configuration`, bot snapshots included
- **Skills repo**: `~/fun/skills`, bot skills included
- **Google Docs**: Docs a thread writes or edits for him

### An ask

Actors: Gabriel, Slack, Email, Linear, GitHub, Calendar, Router, Closer, Side
Closer, Spark, Workflowy, Kaizen, Linear (where work lands).

1. **He drops an ask on Router**
   - Who: Gabriel
   - How: Typed or pasted into Router's chat, often something that came in on
     Slack, email, Linear, GitHub or the calendar.
   - Chat: Router's chat
2. **Router sorts it by project first**
   - Who: Router
   - How: One-off question: Spark, never a ticket. A reply someone is waiting
     on: the bot that owns that work. Executive Protection Linear project work:
     Closer. His workflow tooling, or how he, his bots or coding agents work:
     Workflowy. Career growth, learning and research, personal projects and
     decisions, second brain: Kaizen. Everything else from any team: Side
     Closer.
   - Gate: When it can't tell if something belongs to an Executive Protection
     project, one-line question to him.
3. **Real Executive Protection work gets a ticket**
   - Who: Owning T3 thread
   - How: Work over about 15 minutes, that makes a PR or doc, or that others
     track: the owning T3 thread files or attaches an issue in that Linear
     project. Decisions a T3 thread waits on get linked to its existing Linear
     issue. Grok Bots stay read-only on Linear.
4. **Router hands it over and confirms**
   - Who: Router
   - How: SendToAgent to the owning bot. Fuzzy or multi-bot asks go to the right
     teammate. Router never answers him itself; Spark answers one-off questions.
   - Back to him: One line naming where it went, with links.
   - Chat: Router's chat, then Router stays quiet
5. **The owning bot works it**
   - Who: Owning bot
   - How: Reads tickets, PRs and messages through connectors. Anything in code
     or repos, even reading or searching code, goes to T3 Tots.
   - Chat: The owning bot's chat
6. **Nudges stay rare**
   - Who: Closer, Side Closer, Workflowy, Kaizen
   - How: Only when something is newly blocking, newly answered, or newly
     waiting on his decision. At most three lines, one ping per wait, silent
     otherwise. Router never nudges.
   - Back to him: What, the one decision or next action, and a link.

### One-off question

Actors: Gabriel, Router, Spark, T3 Tots, Claude and Codex threads, Closer, Side
Closer, Workflowy, Kaizen.

1. **The question reaches Spark**
   - Who: Router or Gabriel
   - How: Router sends one-off questions to Spark with SendToAgent, or he asks
     Spark directly.
2. **Spark researches**
   - Who: Spark
   - How: Connectors for tickets, PRs and messages, the web for sources.
     Anything in code or repos goes to T3 Tots for the thread that owns it.
3. **Spark answers and stops**
   - Who: Spark
   - Back to him: A short answer with sources.
   - Chat: Spark's chat
4. **If the answer turns into work**
   - Who: Spark
   - How: SendToAgent to the bot whose lane owns it. Setup changes go to
     Workflowy. No backlog and no chasing afterwards.
   - Back to him: One line naming which bot has it.
5. **Anything outgoing waits**
   - Who: Spark
   - Gate: Never sends, posts, buys or submits without his yes; he presses send.

### PR review

Actors: Gabriel, GitHub (where work comes from), Router, Closer, Side Closer, T3
Tots, T3 listener, Unsettled-threads ledger, Claude and Codex threads, GitHub
(where work lands).

1. **A review request arrives**
   - Who: Gabriel
   - How: He drops the PR link on Router.
   - Chat: Router's chat
2. **Router picks the lane**
   - Who: Router
   - How: Checks which Linear project the PR belongs to: an Executive Protection
     project goes to Closer, anything else to Side Closer.
   - Back to him: One line naming the bot.
3. **The owning bot hands it to T3 Tots**
   - Who: Closer or Side Closer
   - How: SendToAgent. For someone else's PR it just runs the review, with no
     questions about linking or filing Linear issues.
4. **T3 Tots finds or starts the thread**
   - Who: T3 Tots
   - How: Looks in the ledger, the setup map and thread titles of the form `RV
     <repo>#<number>`. Found: sends `re-review` in that thread. None: starts a
     new thread with `$pr-review <PR url>`.
5. **The thread reviews**
   - Who: Claude or Codex thread
   - How: The pr-review skill: a reviewer subagent plus a fresh verifier, raises
     only judgment calls, one review per PR, Conventional Comments labels.
   - Gate: Per `~/.codex/AGENTS.md`, a COMMENT review is a two-way door; APPROVE
     or REQUEST_CHANGES waits for him.
6. **The verdict comes back**
   - Who: T3 listener, T3 Tots, owning bot
   - How: The listener sees the thread finish; T3 Tots' routine sends the
     verdict to the owning bot and ends silently. The owning bot checks the
     thread's claims before relaying them.
   - Back to him: Verdict, risk, findings and a post-or-skip question.
   - Chat: The owning bot's chat
7. **He says whether to post**
   - Who: Gabriel
   - How: Usually 'post it'. The owning bot relays his answer through T3 Tots;
     the thread posts once and reads it back.
   - Gate: His yes for APPROVE or REQUEST_CHANGES.
8. **Checked on GitHub**
   - Who: Owning bot
   - How: Verifies the posted review through the GitHub connector.
   - Back to him: Link to the posted review.
9. **He decides on settling**
   - Who: Owning bot, then T3 Tots
   - How: Asks settle or keep open; T3 Tots settles with t3ctl and confirms the
     ledger entry is gone.
   - Gate: Only his answer settles the thread.

### Build or fix

Actors: Gabriel, Closer, Side Closer, Workflowy, Kaizen, T3 Tots, Claude and
Codex threads, GitHub, Linear, Deploys.

1. **The ticket goes to a thread**
   - Who: Owning bot through T3 Tots, or Gabriel
   - How: `<ticket> full stop` in the thread that owns the item. Full stop means
     he won't watch it. See 'full stop, step by step' below.
2. **Linear issue confirmed**
   - Who: Thread
   - How: Needs the issue for the `ref:` footer.
   - Gate: If there is none, asks now and waits.
3. **Change finished and committed**
   - Who: Thread
   - How: In a task worktree under `~/git/<repo>/`, on a Conventional Branch,
     with signed Conventional Commits.
4. **Proved end to end**
   - Who: Thread
   - How: The strongest end-to-end check, with an inspectable artifact and a
     reproduce command.
   - Gate: No one-way doors for the proof; asks if nothing runnable proves it.
5. **Cross-reviewed**
   - Who: Thread and the other provider
   - How: Claude and Codex review each other's work for 3 rounds, 5 for auth,
     secrets, data deletion or concurrency. Open findings end the run as
     Blocked.
6. **Pushed and PR opened**
   - Who: Thread
   - How: Pushes its own branch and files a ready-for-review PR with the pr
     skill: problem in his words, how it was proved, the cross-review verdict.
   - Gate: Alone, two-way doors.
7. **Babysat**
   - Who: Thread
   - How: babysit-pr in rounds: answers review comments, fixes CI it caused,
     rebases when behind, pushes once per round. Ends Merge-ready, Waiting on
     people or Blocked. Never merges.
8. **Handed off**
   - Who: Thread, T3 Tots, owning bot
   - Back to him: End state, PR link, head and base commits, proof and artifact,
     verdict line, follow-ups, every decision made for him.
   - Chat: The owning bot's chat
9. **Merge and deploy**
   - Who: Claude or Codex in T3 Code, with him
   - How: Full stop stops at merge-ready. After that, the thread handles merging
     under AGENTS.md and comes back to T3 Tots with questions.
   - Gate: Deploys are one-way doors. In the Executive Protection API repo,
     queuing a merge also deploys.
10. **Done signal**
    - Who: T3 Tots, owning bot
    - How: The linked Linear issue reaches Done, Canceled or Duplicate, or the
      PR deploys; the Settling flow takes over.

### A T3 decision

Actors: Gabriel, Claude and Codex threads, T3 listener, T3 Tots,
Unsettled-threads ledger, Closer, Side Closer, Workflowy, Kaizen.

1. **A thread asks or finishes**
   - Who: Any T3 Code thread
   - How: Bot-started or his own.
2. **The listener tells T3 Tots**
   - Who: T3 listener
   - How: Runs at login on his Mac, reads the local T3 Code API with a read-only
     token, and posts a short summary of the question or result to T3 Tots.
3. **T3 Tots records it**
   - Who: T3 Tots
   - How: Its 'T3 questions to chat' routine adds or updates the thread's ledger
     entry: owning bot, the decision waiting.
4. **Handed to the owning bot**
   - Who: T3 Tots
   - How: One priority message to the entry's owning bot.
   - Back to him: Nothing in T3 Tots' chat; the turn ends silently.
5. **The owning bot checks and nudges him**
   - Who: Owning bot
   - How: T3 Tots is only a proxy, so the owning bot checks the thread's claims
     before relaying them.
   - Back to him: At most three lines: what, the one decision, a link. One ping
     per wait.
   - Chat: The owning bot's chat
6. **He answers**
   - Who: Gabriel
   - Chat: The owning bot's chat, or in the thread himself
7. **Answer relayed**
   - Who: Owning bot, then T3 Tots
   - How: T3 Tots answers the thread with t3ctl under its operate token.
8. **Entry cleared**
   - Who: T3 Tots
   - How: Removed when the question is resolved, the thread is archived or
     deleted, or he replies in the thread. Kept-open entries are never removed
     automatically.

### Settling

Actors: Gabriel, Linear, Deploys, T3 Tots, Unsettled-threads ledger, Closer,
Side Closer, Workflowy, Kaizen, Claude and Codex threads.

1. **A done signal**
   - Who: Linear, a deploy, or a bot
   - How: The thread's linked issue reaches Done, Canceled or Duplicate, its PR
     deploys, or a bot finishes an item with no ticket. Executive Protection
     Linear goes Peer Review to Done with no Deployed state.
2. **Passed to the owning bot**
   - Who: T3 Tots
   - How: By the ledger entry's owner.
3. **One-line question**
   - Who: Owning bot
   - Back to him: Settle, keep open, or file follow-ups first.
   - Chat: The owning bot's chat
4. **Settled through T3 Tots**
   - Who: T3 Tots
   - How: t3ctl settles the thread and T3 Tots confirms the ledger entry is
     gone. T3 Code itself never settles on its own.
   - Gate: No bot settles a thread without his answer.

### Versioning loop

Actors: Gabriel, Workflowy, Router, T3 Tots, Version Grok Bots in configuration,
Configuration repo, GitHub.

1. **A bot change is applied**
   - Who: Workflowy
   - How: A description, routine or skill change goes in and is checked word for
     word. A new, renamed or re-scoped bot is reported to Router for its bot
     map.
   - Gate: His yes before changing another bot.
2. **Snapshot started**
   - Who: Workflowy, then T3 Tots
   - How: Right after the change, without asking whether to. T3 Tots hands it to
     the thread 'Version Grok Bots in configuration' and never runs git or repo
     scripts there itself.
3. **Changes listed**
   - Who: Configuration thread
   - How: `bots/snapshot.sh --list` exports the bots, keeps only the versioned
     fields, scans for secrets, merges fleet changes since the last snapshot,
     and lists one question per change with a fingerprint.
4. **He answers each change**
   - Who: Gabriel
   - How: y, n or q per change, shown on the 'Bot versioning snapshots' Page.
   - Gate: His y or n per change.
   - Chat: Workflowy's chat
5. **Applied without commit**
   - Who: Configuration thread
   - How: `--expect` with the fingerprint applies his answers; an answer to a
     stale list is rejected. The applied diff is saved.
6. **Applied diff verified**
   - Who: Workflowy
   - How: Compares the applied diff with the listed changes.
7. **Commit and push**
   - Who: Configuration thread
   - How: Signed commit, pushed to the configuration repo.
   - Gate: A separate yes.
8. **Verified on GitHub**
   - Who: Workflowy
   - How: Checks the commit on GitHub and that the local branch matches the
     remote.
   - Back to him: The commit link.
9. **Staging cleaned up**
   - Who: Configuration thread
   - How: snapshot.sh removes its own staging files after a run and keeps them
     only when it warned. Leftover staging files may be deleted without asking.

### Skill change

Actors: Gabriel, Workflowy, T3 Tots, Claude and Codex threads, Skills repo,
GitHub.

1. **He asks for a skill change**
   - Who: Gabriel, to Workflowy
   - Chat: Workflowy's chat
2. **A skills thread makes it**
   - Who: T3 Tots, then the thread that owns `~/fun/skills`
   - How: Bot skills live in `skills/bots/` for any account and
     `skills/zerofox/bots/` for ZeroFox only.
3. **Commit and push**
   - Who: Skills thread
   - How: Skills and configuration changes usually go straight to main.
   - Gate: His yes.
4. **Installed**
   - Who: Workflowy
   - How: Skills install from GitHub, not the local folder, so a change lands
     only after a push and a reinstall. Bot skills then go onto the bots that
     use them.
5. **Versioned**
   - Who: Workflowy
   - How: The bot change starts the Versioning loop.

### Message out

Actors: Gabriel, Router, Closer, Side Closer, Spark, Workflowy, Kaizen, Claude
and Codex threads, Slack, Email.

1. **A draft is written**
   - Who: The bot working the item
   - How: A Grok Bot writes a Slack or email draft card. A T3 thread drafts with
     the slack-message skill and only drafts unless he tells it to send.
2. **He reviews it**
   - Who: Gabriel
   - Chat: The chat of the bot that drafted it
3. **He presses send**
   - Who: Gabriel
   - Gate: Grok Bots only draft; nothing they write goes out in his name
     otherwise. The bot continues from what was actually sent.
4. **Or the T3 thread sends on his word**
   - Who: T3 thread
   - How: He gives the ask up front, such as 'send X to Y via DMs' or 'reply X
     in this thread <link>', or they agree on the text first (the thread asks
     whether 'xxxxx' is right, or he passes a link and they talk) and then he
     says 'send the msg to the thread'.
   - Gate: Only when he tells it to in the thread; without that instruction the
     thread only drafts.

### Me in T3 Code

Actors: Gabriel, Claude and Codex threads, T3 listener, T3 Tots,
Unsettled-threads ledger, GitHub, Deploys.

1. **He opens or continues a thread**
   - Who: Gabriel
   - How: Plain questions, Slack or Linear links, `$pr-review <PR url>`,
     iterating then `full stop`. Skills typed as `$name`.
2. **He steps in**
   - Who: Gabriel
   - How: Short approvals such as 'push it' or 'post it', inline comments on
     quoted replies, evidence checks, redirects.
3. **He merges and deploys through the agent**
   - Who: Gabriel
   - Gate: An explicit yes each time.
4. **Bots still see it**
   - Who: T3 listener, T3 Tots
   - How: The listener reports his threads too, so a question there reaches the
     owning bot. Replying in the thread clears its ledger entry.
5. **Only he settles**
   - Who: Gabriel

## Gates: what needs my yes

| Action | Grok Bots | T3 threads |
| --- | --- | --- |
| Read tickets, PRs and messages through connectors | Alone | Alone |
| Read or search code, or any repo work | Never (through T3 Tots only) | Alone |
| Code edits, own branches and worktrees, commits | Never | Alone |
| Push to their own branches, open ready-for-review PRs | Never | Alone |
| Temp files, caches, `~/tmp/specs/`, local services they started | Not theirs | Alone |
| COMMENT review on a PR he asked to review | Not theirs (Decided: follow AGENTS.md. T3 Tots' description still says no review posts without his yes, a change still to make) | Alone |
| APPROVE or REQUEST_CHANGES review | His yes (relayed to the thread) | His yes |
| Merge, auto-merge, merge queue | Never | His yes (left to Claude and Codex under AGENTS.md, which doesn't name merging; full stop stops at merge-ready) |
| Deploys, prod, any shared environment or data store, QA and staging included | Never | His yes |
| Messages that speak for him | Draft only (he presses send) | His yes (sends only when he tells it to in the thread; otherwise drafts only) |
| Commitments, disrupting others, discarding others' work | Not theirs | His yes |
| Auth changes, changes outside the task's repo or worktree | Not theirs | His yes |
| File or attach a Linear issue in an Executive Protection project | Never (read-only on Linear; the owning T3 thread does it) | His yes (asks now when the `ref:` footer has none) |
| Change a Linear issue | Never (read-only on Linear; the owning T3 thread does it) | Follows AGENTS.md guidelines |
| Settle a T3 thread | His yes (asked in one line, done by T3 Tots) | Never |
| Change another bot's description, routine or skills | His yes (through Workflowy) | Not theirs |
| Start a snapshot after a bot change | Alone (Workflowy, through T3 Tots) | Not theirs |
| Keep or drop each snapshot change | His yes (y, n or q per change) | Not theirs |
| Commit and push the configuration or skills repo | Never | His yes (a separate yes) |
| Delete snapshot staging files | Not theirs | Alone |
| Send, post, buy or submit anything | Draft only | His yes |
| Rubber-stamp questions | Not theirs | Skipped (skipped, not asked) |

Grok Bots means Router, Closer, Side Closer, Spark, Workflowy, Kaizen and T3
Tots. They should be read-only: they mainly talk with me, and the real work
happens in T3 Code. T3 threads means Claude and Codex threads under
`~/.codex/AGENTS.md`, whoever started them. Once I open a one-way door, it stays
open for that piece of work, and the approval carries to subagents.

## T3 Code: skills and how I use them

T3 Code runs Claude and Codex threads on my Mac. This is what a bot needs to
know to follow what I mean when I name a skill, a phrase like 'full stop', or a
thread pattern. The source is T3 Tots' setup map, which summarizes my skills
repo, my configuration repo and a read-only study of my threads.

### How I talk to threads

- **`$name`, not `/name`**: I type skills Codex style: 257 `$` uses against 53
  `/`, and 32 of the `/` uses are `/compact`. Read `$pr-review` and `/pr-review`
  as the same skill. Skills marked manual run only when named this way.
  CLAUDE.md adds that a `/skill-name` not in Claude's list means read
  `~/.claude/skills/<name>/SKILL.md` and follow it.
- **Short approvals** (157 threads): 'go ahead', 'push it', 'post it', 'lgtm,
  merge it' move a thread to its next step.
- **Inline comments on quoted text** (84 threads, 532 comments): My main way to
  answer long replies: I quote a piece of the reply and comment under it.
- **Second opinions** (56 threads): 'ask codex' or 'make codex review' inside a
  Claude thread, well beyond cross-review.
- **Evidence checks and redirects** (25 and 8 threads): 'did you check', 'did
  you test', 'double check'; 'we lost direction', 'stop that', 'let's just build
  it'.
- **Slack replies** (38 threads): The thread sends when I tell it to in the
  thread. Either I give the ask up front, such as 'send X to Y via DMs' or
  'reply X in this thread <link>', or we agree on the text first (it asks
  whether 'xxxxx' is right, or I pass a link and we talk) and then I say 'send
  the msg to the thread'. Without that instruction it only drafts.
- **Merges and deploys through the agent** (19 and 24 threads): After a PR, with
  an explicit yes each time, to QA, staging or prod.
- **Long threads**: `/compact` in 32 threads; 'continue where you left off' in
  8.
- **Scoped full stop**: 'full stop 5581', 'AIC team, full stop', 'ok, next PR
  full stop'. Asking what the phrase means doesn't trigger it.

### full stop, step by step

- **Trigger**: I say 'full stop', meaning I won't watch the thread. Usually
  after iterating on the approach, or as `<ticket> full stop`.
- **0. Confirm the Linear issue**: Needed for the `ref:` footer. If there is
  none, it asks now, before going unattended.
- **1. Finish and commit**: The agreed change, committed with signed
  Conventional Commits in the task worktree.
- **2. Prove it**: The end-to-end check from the Testing rules, keeping the
  artifact. No one-way doors for the proof; it asks if nothing runnable proves
  it.
- **3. Its own review and the cross-review**: Runs `cross-review`: the other
  provider (Claude against Codex) is the sole reviewer, 3 rounds, 5 for auth,
  secrets, data deletion or concurrency, ending in a `Cross-reviewed: ...
  Verdict: ...` line. Open findings end the run as Blocked with the report.
- **4. Push and open the PR**: Pushes its branch. If `gh pr list --head
  <branch>` shows no PR, files one with the `pr` skill: the Summary opens with
  one sentence on the problem in my words, plus how it was proved and the
  verdict line.
- **5. Babysit**: `babysit-pr` until an end state: Merge-ready, Waiting on
  people or Blocked. It answers review comments, fixes CI it caused, rebases
  when behind, and never merges.
- **6. Re-prove if babysitting changed behavior**: If a cross-review round is
  left: prove again, check the merge queue, one scoped cross-review round,
  update the verdict, push, back to step 5. Budget spent: verdict `incomplete`,
  hand off.
- **Stops at merge-ready**: Hands off the end state, PR link, head and base
  commits, proof and artifact, verdict line, follow-ups and each decision it
  made for me. Merging, auto-merge and the merge queue are not part of full
  stop.

It asks only when it can't prove the change, the goal is ambiguous in a way that
changes the result, or the next step is a one-way door.

### pr-review and re-review

1. **Start**: `$pr-review <PR url>`, or a Slack link to the PR, in a new thread.
   T3 Code titles it `RV <repo>#<number>`.
2. **Review**: A reviewer subagent plus a fresh verifier. It raises only
   judgment calls, labels findings with Conventional Comments, and reports the
   verdict in the thread.
3. **'post it'**: I read the findings and say 'post it'. The thread submits one
   review per PR. Sometimes I say 'don't post yet'.
4. **`re-review`**: After new pushes I send `re-review` in the same thread,
   never a new one. That's why T3 Tots looks for the earlier `RV` thread first.

Installed on the zerofox profile only. 105 threads started this way and 77
reviews were posted after I said so. Codex ran 85 of 90 reviews from Sep 23 to
Oct 25; Claude ran all 15 in the week of Oct 26.

### Thread patterns I actually ran

384 of my own threads, Sep 23 to Oct 30, classified by keyword, so small counts
are approximate.

| Pattern | Threads |
| --- | --- |
| No code: investigation, answer, draft or ops | 171 |
| PR review, then 'post it' | 105 |
| Iterate, then 'commit and push' to main | 35 |
| Iterate, then cross-review and babysit-pr by hand | 33 |
| Iterate, then 'open a PR' | 23 |
| Iterate or ticket, then 'full stop' | 9 |
| grill-with-docs, to-spec, to-tickets | 2 |

52 threads ran past 20 of my turns, and 29 of those produced PRs. 'commit and
push' is the skills and configuration pattern, often a one-message thread.
Hand-typed cross-review and babysit-pr peaked in the weeks before I committed
the full-stop skill on Oct 26; in the week of Oct 26, 5 threads ended in full
stop. Matt Pocock skills fell from 10 threads in the week of Sep 23 to none in
the week of Oct 26.

> Keeping bigger work in one long thread was an experiment to test whether I
> need Matt Pocock's interview, spec and tickets skills, not a rule. Both flows
> still stand, and neither is the default. The counts describe what happened,
> not what to do.

### Thread types

- **Review a PR**: `$pr-review <PR url>` in a new thread; `re-review` in that
  same thread later.
- **Small change**: Talk it through and iterate in T3 Code, then 'full stop';
  the agent takes it to a merge-ready PR.
- **Bigger work**: Either one long thread with an ad hoc spec and Claude and
  Codex poking holes, or `/grill-with-docs`, then `/to-spec` (an unpublished
  spec under `~/tmp/specs/`, never Linear), then `/to-tickets` (publishes
  approved tickets to the Linear project I choose), then full stop per ticket.
- **Configuration and skills**: Iterate, then 'commit and push' straight to main
  in the thread that owns the repo. No PR and no full stop.
- **No-code threads**: Slack questions, incidents, research and drafts: almost
  half of my threads.
- **Who starts threads**: T3 Tots for the bots, or me directly. A thread usually
  owns one item; T3 Tots sends follow-ups to the thread that already owns it.
- **Settling**: Only I decide. T3 Code never settles on its own; T3 Tots settles
  with t3ctl after the owning bot relays my answer.

### My own skills

From gabrielrojasc/skills; thread counts are from the practice study.

- **full-stop**: Triggered by 'full stop'. Unattended run from the current state
  to a merge-ready PR, step by step above.
- **pr-review** (113 threads): Triggered by `$pr-review <url>`. Reviewer
  subagent plus a fresh verifier, judgment calls only, one review per PR.
  Zerofox profile only.
- **cross-review** (33 threads): Review and revise with the other provider as
  sole reviewer through T3 `delegate_task`. A finding about another path, a rare
  case or a small cost is a nitpick unless its harm is severe.
- **babysit-pr** (25 threads): Watches a PR in rounds with a fresh subagent each
  round: review feedback, CI it caused, rebases, one push per round. Never
  merges.
- **gh-review-comments** (19 threads): Addresses PR review feedback: fixes what
  holds up, replies to every thread, raises only judgment calls.
- **review-revise** (24 threads): Adversarial loop where independent reviewers
  attack code, prose or a plan until no material objection is left. 'poke holes'
  triggers it too.
- **rewrite-it** (26 threads): Rewrites the target or the last reply after
  rereading the Writing rules in AGENTS.md. 'my writing style' triggers it too.
- **slack-message** (5 threads): Formats text I will paste into Slack.
- **chief-of-staff** (3 threads): Reads my other unsettled threads, ranks what
  needs me, and tables the `RV` review threads. Acts on a thread only when
  asked.
- **test-plan**: Plans end-to-end checks before shipping to prod, in chat only.
- **git-workspace**: Bare-container repo layout with one worktree per task under
  `~/git/<repo>/`.
- **computer-use**: For signed-in sites and Mac apps; T3's preview tools cover
  public sites.
- **developer-documentation-style**: Applies the Google Developer Documentation
  Style Guide after repo conventions.
- **python-environments**: `uv venv`, then the repo's own tooling; no global
  installs.
- **linear-gh-linking and linear-work-breakdown**: Linear IDs for branches and
  PRs, and placing work in the right Linear layer. The zerofox profile removes
  both, so neither is installed on this Mac, while AGENTS.md still says to
  create issues through linear-work-breakdown.

### External skills I use

Installed for Claude Code and Codex; manual means it runs only when named.

- Matt Pocock: **pr**: Writes PR bodies; full stop files every PR through it.
- Matt Pocock: **code-review** (5 threads): Review since a fixed point against
  standards and the spec; I ask Codex to run it.
- Matt Pocock: **improve-codebase-architecture (manual)** (4 threads): Finds
  deepening opportunities as an HTML report, then grills one.
- Matt Pocock: **retro (manual)** (4 threads): Retrospective on a coding
  session.
- Matt Pocock: **grill-me and grill-with-docs (manual)** (3 and 2 threads):
  Interview to sharpen a plan; the second also writes ADRs and a glossary.
- Matt Pocock: **to-spec and to-tickets (manual)** (3 threads each): Spec from
  the conversation, kept under `~/tmp/specs/` per AGENTS.md, then tracer-bullet
  tickets published to Linear.
- Matt Pocock: **wayfinder, handoff, ask-matt (manual)** (1 thread each): Huge
  work as decision tickets; a handoff doc; which Matt skill fits.
- Matt Pocock: **diagnosing-bugs** (8 threads): Diagnosis loop, triggered by
  'diagnose' or a broken, failing or slow report.
- Matt Pocock: **wait-what (manual)** (8 threads): Re-pitches a last message
  that didn't land.
- Matt Pocock: **writing-for-agents**: Rules for writing skills, AGENTS.md and
  CLAUDE.md.
- pstack: **unslop (manual)**: Cuts AI tells. CLAUDE.md imports it and AGENTS.md
  requires it for all prose, so I never type it.
- pstack: **ketchup (manual)** (23 threads): Catches me up on what changed in
  the thread and what waits on me.
- humanlayer: **show-me (manual)** (9 threads): Explains a topic visually with
  diagrams and HTML; 'teach me visually' too.
- UI: **frontend-design, impeccable, emil-design-eng**: AGENTS.md picks these
  for UI work.
- ZeroFox: **unblocked-context-research**: Why code is the way it is; AGENTS.md
  says to use it before searching PRs, Slack, Linear and docs one by one.
- ZeroFox: **catalog-guided-db-access**: The zf-databases CLI first for database
  discovery and read-only SQL.
- **Installed, never seen used**: implement, implement-spec, tdd, grilling,
  triage, prototype, research, bro.

### How skills install

1. **`install.sh`**: Dry run by default, `--apply` to apply. Renders
   `base/agent-skills.txt` plus the profile's patch: `<source> <skill>` lines
   under an `agents claude-code codex` header.
2. **Diff**: Compares with `skills ls -g` and the last install: adds missing
   skills, removes dropped ones, reinstalls skills whose agents changed.
3. **The skills CLI**: `pnpx skills@latest add <source> -g -s <name>... -a
   claude-code -a codex -y`, which copies each skill into
   `~/.agents/skills/<name>` and links it from `~/.claude/skills/`.
4. **From GitHub, not my folder**: Skills install from GitHub, not
   `~/fun/skills`, so an edit lands only after a push and a reinstall or `skills
   update -g`, which `upgrade.sh --apply` runs.
5. **`copy.sh`**: Writes skills I added locally back into `agent-skills.txt`.

## Routines and schedules

- **Weekday morning bot sweep** (Router; weekdays around 8:30 AM Chile time
  (UTC-3), may run up to 30 minutes early): Read-only health check of every bot
  on its bot map: failed or erroring routine runs, connectors that need auth,
  whether the T3 listener still delivers events, and whether either T3 token
  expires within 10 days. Says nothing when all is healthy; one line per problem
  otherwise. Never reports priorities or work status.
- **Start-of-day brief** (Closer; weekdays around 8:30 AM Chile time (UTC-3)):
  One line per active Executive Protection project, up to 4, most urgent first,
  each with its status, what's next, and its target date if that's within two
  weeks. Then the Executive Protection decisions waiting on me, grouped by
  project. Then one line of other work, from Side Closer's top item or the
  ledger entries Side Closer owns. When every project item is blocked or
  waiting, says so and points to Side Closer's top item as dead-time work.
- **Friday harness friction review** (Workflowy; Fridays around 9:00 AM Chile
  time (UTC-3), flexible): Reads the past week of bot transcripts, the bot
  descriptions, this Page and the ledger. Asks T3 Tots for a T3 Code friction
  review over threads, AGENTS.md, CLAUDE.md, skills and configuration. Changes
  nothing. Sends me the top 3 to 5 friction points with fixes in Workflowy's
  chat.
- **Weekly memory-to-description review** (Workflowy; Fridays around 4:00 PM
  Chile time (UTC-3)): Proposes moving bot rules out of memory into
  descriptions. Applies nothing without my yes.
- **T3 questions to chat** (T3 Tots; each T3 listener event): Updates the ledger
  and hands the question, result or done signal to the owning bot, then ends
  silently.
- **Setup map refresh** (T3 Tots; when the skills or configuration repo has a
  new commit): Rebuilds the setup map of my skills, workflows and Mac
  configuration, showing one commit line per repo.

No routines were found for Side Closer, Spark or Kaizen.

## Doors

### Two-way doors: proceed, report after

1. Code edits
2. Their own branches and worktrees
3. Commits
4. Pushes to their own branches
5. Opening PRs
6. COMMENT reviews on PRs I asked them to review
7. Temp files and caches
8. Specs under `~/tmp/specs/`
9. Local services they started

### One-way doors: wait for my yes

1. Deploys
2. Prod, or any shared environment or data store, QA and staging included
3. Messages that speak for me
4. APPROVE and REQUEST_CHANGES reviews
5. Commitments
6. Disrupting others
7. Discarding others' work
8. Auth changes
9. Changes outside the task's repo or worktree

Rubber-stamp questions are skipped. A door I open stays open for that work. A
gate set by me, a repo, a skill or the workflow counts as one-way. Merging isn't
named in either list; Claude and Codex handle it under these rules.

## AGENTS.md and CLAUDE.md rules

### Core and coding

1. Read AGENTS.md and CLAUDE.md root-down first
2. Simplest correct solution, one source of truth, root causes
3. Stay in scope; no secrets in files
4. Verify with the strongest check before reporting
5. Standard library first; no code comments except for a public API or an
   external constraint
6. End-to-end tests by default, with an inspectable artifact and a reproduce
   command
7. Other provider through T3 `delegate_task`; every brief has a done check

### Writing

1. Readable cold, concise, with unslop applied
2. Lead with the bottom line
3. Ask in chat at the end; unattended skills use the question tool
4. Judgment calls carry a `Second opinion: <provider> picks X because Y` line
5. Link every item mentioned
6. Conventional Comments labels on findings
7. No emojis in Markdown or docs; developer-documentation-style for docs

### Environment and tools

1. `fd -L` and `rg -L`, because skills are symlinks
2. Repo tooling, not globals; narrow searches
3. Assume auth; `gh` for GitHub, connectors for Slack and Google
4. ZeroFox: GitHub searches scoped to `org:riskive`, Grafana MCP for
   observability, Linear defaults to the EP team
5. `~/work/brain` only for personal requests, read-only, searching file names
   only
6. Repos under `~/git/<repo>/`, one git-workspace worktree per task

### Git and tracker

1. `git pull --ff-only` before anything else
2. Signed Conventional Commits and Conventional Branch names
3. A `ref:` footer with the Linear issue on mergeable branches; if there is
   none, ask and wait
4. PRs ready for review unless asked for a draft
5. Rebase, and push with `--force-with-lease`
6. Linear issues assigned to me, only requested labels; to-spec never touches
   Linear

`~/.codex/AGENTS.md` holds the shared rules. `~/.claude/CLAUDE.md` imports it
and unslop's SKILL.md, plus the hidden-skills rule for `/name`.

## Listener, tokens and ledger

- **T3 listener**: t3listen starts at login on my Mac as a LaunchAgent. It opens
  no port, reads the local T3 Code API with its own read-only token, and posts a
  short summary to T3 Tots whenever a thread asks a question or finishes.
- **Listener token** (expires Nov 28, 2026): Scoped, revocable, read-only, about
  90 days.
- **t3ctl operate token** (expires Oct 30, 2027): Label t3-tots-operate, read
  and operate. Lets T3 Tots answer, stop, settle and snooze threads. Kept in a
  separate folder so the listener doesn't see its actions.
- **Expiry watch**: Router's weekday sweep reports either token when it is
  within 10 days of expiring.
- **Ledger**: A JSON file T3 Tots keeps on the box, one entry per unsettled
  thread: title, machine, project, owner, reason, decision waiting, since,
  notified, source, notes, follow-up and result files.
- **Owner**: Each entry carries its owning bot, the routing field. There is no
  kind field. See 'Decided'.
- **Who reads it**: T3 Tots writes it. Each bot reads the entries it owns:
  Closer reads Closer's entries for the brief, Side Closer reads Side Closer's,
  and so on. T3 Tots checks it for earlier review threads. Its shape is
  versioned with the bot snapshots.
- **Clearing**: An entry goes when its question is resolved, the thread is
  archived or deleted, or I reply in the thread. Kept-open entries stay until
  settled.
- **Open now** (as of Nov 2, 9:38 PM Chile time (UTC-3)): 8 entries. By owner:
  Side Closer 3, Closer 2, Workflowy
  2, Kaizen 1. By reason: 4 kept open, 3 finished with a decision, 1 tracking.

## Configuration and skills repos

- **Configuration repo**: `~/fun/configuration` holds my machine setup and the
  bot fleet: each bot's profile, settings and routines, the ledger's shape,
  per-profile patches and rosters for the zerofox and personal profiles.
- **How it changes**: Only through the 'Version Grok Bots in configuration'
  thread, by the Versioning loop: my y, n or q per change, then a separate yes
  to commit and push.
- **Skills repo**: `~/fun/skills` holds my coding-agent skills. Bot skills go in
  `skills/bots/` for any account and `skills/zerofox/bots/` for ZeroFox only.
- **How skills land**: Skills install from GitHub, so a change counts only after
  a push and a reinstall; bot skills then get installed on the bots that use
  them. Details under 'How skills install'.
- **Setup map**: T3 Tots' summary of both repos and my T3 practice. Bots read it
  before acting on my setup and open the source before quoting a rule.

## Decided

- **Which bot answers in which chat** (Change pending): Settled. Spark exists
  now, so Router never sends me answers; it only routes and confirms in one line
  where each ask went. Still to change: Router's description says it handles
  fuzzy or multi-bot asks itself 'only when no bot fits'.
- **T3 Tots messaging me** (Decided): The rule stands: it messages me only when
  I write in its chat or it's urgent and no owning bot can reach me.
- **Who checks a thread's claims before relaying** (Decided): The bot that owns
  the T3 thread. T3 Tots is only a proxy.
- **COMMENT and APPROVE wording** (Change pending): Follow `~/.codex/AGENTS.md`:
  COMMENT reviews on PRs I asked to review are two-way doors; APPROVE and
  REQUEST_CHANGES wait for me. Still to change: T3 Tots' description says 'Never
  have a thread post a review to GitHub without Gabriel's yes.'
- **Where Grok Bot ends and T3 Code begins** (Decided): Grok Bots should be
  read-only, with no real work done in them. They mainly communicate with me;
  the work happens in T3 Code. The Linear writes decision applies this to
Linear.
- **Merging** (Decided): Let Claude and Codex in T3 Code handle it under
  AGENTS.md; they come back to T3 Tots with questions if needed. AGENTS.md
  doesn't name merging, and full stop stops at merge-ready.
- **Who owns email and calendar** (Decided): It depends on the work, but most
  will probably land on Spark. No description names it yet.
- **Anything that still names Admin** (Done, 2026-11-03): No bot description
  or Router's saved health-check prompt names Admin. The configuration repo
  renamed the admin slug, folders and roster lines to spark in commit 7b8ec9a.
  Older facts in Router's memory sit outside the repo.
- **Where this map lives** (Decided, 2026-11-03):
  `profiles/zerofox/bots/shared/workflow-map.md` in the configuration repo.
- **SDLC review** (Decided, 2026-11-03): Done. Deploy and maintain are parked
  into two future Cosmos infra agents: a deploy-review agent and a Slack bug
  triage agent. Planning specs live in Google Docs and Linear, and tickets link
  them. Full stop is enough for testing proof. Tools have no gap: Unblocked
  works through the unblocked CLI skill, and Codex has Linear and Slack.
- **Linear writes** (Decided, 2026-11-03): Only T3 Code threads create or edit
  Linear tickets, and Grok Bots stay read-only on Linear.
- **One thread per item** (Decided, 2026-11-03): Not a written rule, just how I
  usually work.
- **Ledger kind field** (Decided, 2026-11-03): Drop `kind` and keep `owner`
  only.
