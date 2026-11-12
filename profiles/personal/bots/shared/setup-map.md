# Gabriel's agent setup map

What this is: a short map of Gabriel's agent skills, work flows, and machine
configuration, so bots can work the way he does without re-reading both repos.
Built read-only from GitHub (cursor-github connector) and his ZeroFox Mac.

Last refreshed: 2026-11-11 18:57 Chile time (UTC-3)

skills: 051a88154ba1b14531c9cb56da27947aefd3e057 2026-11-11T00:09:55-03:00
configuration: 069bf3926191465475fd833119ec5ad9d8753c3d 2026-11-10T11:40:26-03:00 (master)

## 1. His skills (gabrielrojasc/skills)

Each lives in skills/<name>/ with SKILL.md and agents/openai.yaml (bot skills
under skills/bots/ have no agents/openai.yaml). Triggers are the quoted
`description` lines.

- babysit-pr: "Use when asked to babysit a GitHub PR." Runs unattended in rounds (fresh subagent each round): one round right away, then another on each PR-watch wake, without waiting for running checks. Each round handles review feedback via gh-review-comments, fixes every failed check on the PR's head, including checks that also fail on the base (a CI repair counts as part of the PR's purpose), reruns a transient failure once, rebases when behind, and pushes once per round. Ends Merge-ready (`mergeStateStatus` CLEAN, no unresolved thread except ones he kept open), Waiting on people (every check that isn't gated finished without a failure; only approvals, gated runs, requested reviewers or draft state remain), or Blocked (a failed check needs him, a round repeats an earlier fix, or something else it can't fix). Never merges.
- chief-of-staff: "Use when asked for chief-of-staff updates in T3." Reads his other unsettled T3 threads, ranks what needs him (work by prod impact, Linear project, deadline, effort; personal separately), renders a glance page, tables `RV <repo>#<n>` review threads. On request: tidy threads, Slack follow-ups. Acts on a thread only when asked. (A T3 skill; not the personal fleet's Chief of Staff Grok Bot in section 6.)
- computer-use: "Use when a task needs a signed-in site or a Mac app." T3 preview tools cover public sites; this covers his signed-in browser and native apps.
- cross-review: "Use when asked to cross-review and fix a change." Runs review-revise with the other provider (Claude vs Codex) as sole reviewer via T3 `delegate_task`; 3 rounds (5 for auth, secrets, data deletion, concurrency). Findings use Conventional Comments labels and IDs; ends with a `Cross-reviewed: ... Verdict: ...` line. Fix rule: a finding about another path, a rare case, or a small cost is a nitpick whatever its label, unless its harm is severe.
- developer-documentation-style: "Use when working on developer docs." Applies the live Google Developer Documentation Style Guide after repo conventions.
- full-stop: "Use when told 'full stop'." Unattended run from current state to a mergeable PR (see section 3).
- gh-review-comments: "Use when addressing PR review feedback." Classifies feedback, fixes what holds up, replies to every thread, raises only judgment calls. Has fetch scripts.
- git-workspace: "Use when Git repos need cloning, sync, task setup, or cleanup." Bare-container repo layout with one worktree per task (scripts: add-repo, create/remove-task-worktree, sync, list).
- hill-climb: "Use when asked to hill climb work against an eval." Improves work in rounds until it meets an agreed target or stalls. First it agrees with him on the eval (a command that prints a number, or a written rubric), the target, the guardrails and their regression check, the stall count (default 2), the round cap per pass (default 6), and where the log and files go (default `~/tmp/hill-climb/<task>/`; in a repo, each round is a commit on the task branch). When the request already sets every term, it logs them and starts. Then it freezes the rubric, reviewer brief, reviewer models, regression check, other inputs and commands by sha256 and confirms them before each round. Only added regression cases or a requirement he adds may change them; any other change stops the run. Round 0 scores the work unchanged. Each round is scored by a measured command (the median of three runs) or by fresh Claude and Codex reviewers given only the frozen brief, file and rubric. A round is kept only when it passes the regression check, adds no new blocker, and gains, fixes a proved error, or clears a blocker. After pass one it proposes pass two, which trims the delivered version (for example, cutting its word count) while holding the score. Each pass ends with a fresh final score and reports whether the target was met, the file and sha256, the scores with reasons, the regression output, the log path, and every open blocker. Its trigger evals (two that should fire, one one-time-scoring near miss) haven't been run yet.
- linear-gh-linking: "Use when starting Linear work or linking its PRs." Picks Linear issue IDs and relationship semantics for branches and PRs.
- linear-work-breakdown: "Use when planning Linear levels or tickets." Places work in the right Linear layer (initiative to sub-issue) and creates it the team's way.
- python-environments: "Use when running Python tests or installs." `uv venv`, then the repo's own tooling; no global installs.
- review-revise: "Use when adversarial review loops are requested." Independent reviewers attack work (code, prose, plan); revise until no material objection or the loop stalls.
- rewrite-it: "Use when asked to rewrite text." Rewrites the target (or the last reply) after rereading the Writing rules in ~/.codex/AGENTS.md.
- slack-message: "Use when drafting a Slack message." Formats text he will paste into Slack with Slack markup.
- test-plan: "Use when asked to plan pre-production feature checks." Plans end-to-end checks for shipping to prod, in chat only, and asks for missing access.
- zerofox/pr-review: "Use when reviewing a GitHub PR." Reviewer subagent plus a fresh verifier, raises only judgment calls, submits one review per PR. Installed on the zerofox profile only.

Bot skills (skills/bots/), for his Grok Bots, which run without his Mac files. The `grok-` copies carry the rules their originals read from local files; the originals stay the versions for his own sessions. None is in agent-skills.txt, and no committed file in the configuration repo installs them on a bot yet.
- grok-slack-message: "Use when drafting a Slack message as Grok Bot." slack-message for bots: Slack markup, no headings or tables, replies with the draft for him to send (never posts). Voice: match his length in the thread, don't restate, at most three questions in plain sentences.
- grok-rewrite-it: "Use when asked to rewrite text as Grok Bot." rewrite-it with his Writing rules and unslop inlined; returns only the rewrite of the named text or the last reply.
- open-items: "Use when asked broadly what's open, pending, or on your plate." Read-only list of the bot's own items from /home/box/t3-tots/unsettled-threads.json (owner is the bot) plus his Linear issues in its lane, merged by links, grouped Waiting on you (needs-you), Moving (working and waiting-on-others), Parked (done-to-settle, plus Linear issues with no thread; parked collapsed to one line with a "show parked" offer); one line per item with Linear and PR links, no bare IDs. A specific topic ask gets only that item; "what's next?" gets only the next step.
- anything-open-or-settle: "Use when `anything-open-or-settle` is explicitly written." Fires only on that exact name; its trigger evals skip "should we settle this thread?", a direct "settle the ... thread", and a bare done signal. It checks the thread before any settle question, because a done signal (merged PR, closed issue) means one piece finished, not that nothing is left. T3 Tots reads the thread with `t3 thread show <thread id> --json --messages 40` plus the ledger entry's `followUp`; any other bot asks T3 Tots for the open items and waits. Open means anything the thread leaves without an answer or a ticket: a request, question or decision from Gabriel or a reviewer; a follow-up or promise; an error, failed check, or unexplained flake; work called unproven, paused, or not live; an open linked PR or a leftover branch, worktree, or temporary resource; anything it asks him to consider. It raises those first, one line each with its link, even past a bot's nudge limit, then asks settle, keep open, or file follow-ups first, with a pick (keep open when an open item is work the thread was asked to finish). With nothing open it says it checked, then asks. T3 Tots hands the items and the question to the owning bot and messages Gabriel about nothing; if it can't read the thread, it says so and holds the question.

## 2. External skills (base/agent-skills.txt plus zerofox patch)

All install for agents claude-code and codex. "manual" = `disable-model-invocation: true`, so only a /name invocation runs it.

anthropics/skills
- frontend-design: distinctive visual direction for new or reshaped UI.

cursor/plugins/pstack
- bro (manual): restate the last message in plain language.
- ketchup (manual): catch him up on what changed in the chat, listing what waits on him. "/ketchup".
- unslop (manual): cut AI tells from writing; imported into CLAUDE.md and required for all prose.

emilkowalski/skills
- apple-design: base only; the zerofox patch removes it.
- emil-design-eng: UI polish, component design, animation decisions.

github/gh-stack
- gh-stack: stacked PRs and splitting work into reviewable branches.

humanlayer/skills/plugins/show-me
- show-me (manual): explain a topic visually with diagrams and HTML artifacts.

mattpocock/skills
- ask-matt (manual): router for which Matt Pocock skill or flow fits.
- code-review: review since a fixed point on Standards and Spec, in parallel subagents.
- codebase-design: deep-module vocabulary for interfaces and seams.
- diagnosing-bugs: diagnosis loop; triggers on "diagnose" / "debug this" or broken, failing, slow reports.
- domain-modeling: domain model, GLOSSARY.md, ADRs.
- grill-me (manual): relentless interview to sharpen a plan.
- grill-with-docs (manual): same interview, also writing ADRs and glossary as it goes.
- grilling: grill a plan or idea; triggers on any "grill" phrase.
- handoff (manual): compact the conversation into a handoff doc.
- implement (manual): implement from a spec or tickets.
- implement-spec (manual): implement the result of /to-spec and /to-tickets.
- improve-codebase-architecture (manual): find deepening opportunities as an HTML report, then grill one.
- pr: "Use when writing a PR body." full-stop files PRs through it.
- prototype: throwaway prototype to answer a design question.
- research: primary-source research captured as Markdown in the repo.
- retro (manual): retrospective on a coding session.
- setup-matt-pocock-skills (manual): one-time repo setup for tracker and docs (his AGENTS.md Tracker section replaces docs/agents/issue-tracker.md).
- tdd: test-first; "red-green-refactor".
- teach (manual): teach a concept in the workspace.
- to-questionnaire (manual): turn an open decision into a questionnaire for someone else.
- to-spec (manual): synthesize the conversation into a spec. Its description says it publishes to the tracker; his AGENTS.md overrides that (section 4).
- to-tickets (manual): split a plan or spec into tracer-bullet tickets with blocking edges, published to the tracker.
- triage (manual): move issues and external PRs through triage roles.
- wait-what (manual): re-pitch a last message that did not land.
- wayfinder (manual): plan huge work as decision tickets on the tracker.
- wizard: generate a bash wizard for steps only a human can do.
- writing-for-agents: rules for writing skills, AGENTS.md, CLAUDE.md.

openclaw/openclaw
- summarize: summarize or transcribe URLs, videos, podcasts, PDFs, files.

pbakaus/impeccable/.agents
- impeccable: design, critique, polish, or harden a frontend interface.

zarazhangrui/frontend-slides
- frontend-slides: animated HTML presentations, or PPTX to web.

Zerofox patch additions
- riskive/ai-tooling catalog-guided-db-access: zf-databases CLI first for DB discovery, schema, read-only SQL; never `vt database login` directly.
- unblocked/skills unblocked-context-research: why code is the way it is, prior work, incident history across PRs, docs, chat, issues.
- unblocked/skills unblocked-tools-guide: when an Unblocked tool is missing, failing, or unclear.

Zerofox patch removals: apple-design, linear-gh-linking, linear-work-breakdown. Zerofox addition from his repo: pr-review.

## 3. full-stop, end to end

Trigger: he says "full stop", meaning he won't watch the thread. Only mentioning the phrase (asking what it means) does not trigger it.

0. Confirm the Linear issue for the required `ref:` footer; ask now if there is none.
1. Finish the agreed change and commit it.
2. Prove it with the end-to-end check from the Testing rules; keep the artifact. No one-way doors for the proof; ask if nothing runnable proves it.
3. Review with `cross-review`, leaving its push to step 4. If findings stay open, hand off as Blocked with its report.
4. Push. If `gh pr list --head <branch>` shows no PR, file one with the `pr` skill: Summary opens with one sentence on the problem in his words, plus how it was proved and the cross-review verdict line.
5. Run `babysit-pr` until it reports an end state. It fixes every failed check on the PR, including ones that also fail on the base, so Merge-ready means CI passes.
6. If babysitting changed behavior after the last proof or review and cross-review has a round left: prove again, run babysit-pr's merge-queue check, one scoped cross-review round, update the verdict, push, back to step 5. Budget spent: verdict `incomplete`, hand off.

Asks only when it can't prove the change, the goal is ambiguous in a way that changes the result, or the next step is a one-way door.
Stays with Gabriel: merging, enabling auto-merge, adding to a merge queue.
Handoff: babysit-pr end state (or Blocked before step 5), PR link, head and base SHAs, proof and artifact, verdict line, follow-ups, each decision made for him.

## 4. His two work flows

Small change
1. Talk it through and iterate on the approach in T3 Code.
2. Say "full stop"; the agent takes it to a merge-ready PR.

Bigger work
1. `/grill-with-docs`: interview to sharpen the plan, writing ADRs and glossary.
2. `/to-spec`: per AGENTS.md, writes an unpublished Markdown spec under `~/tmp/specs/` and never touches Linear.
3. `/to-tickets`: uses the approved spec and publishes approved tickets to the Linear project he chooses.
4. "full stop" per ticket.

AGENTS.md details that apply: Linear issues are created through linear-work-breakdown, assigned to him, and he leads new projects; only requested labels; zerofox defaults to the EP team. Implementation runs in a git-workspace task worktree under `~/git/<repo>/` unless he says to use the current checkout. Branches get a `ref:` footer with the Linear issue.

## 5. How install works

1. `install.sh` (dry run by default; `--apply` / `-a` to apply) renders base/agent-skills.txt plus the profile's patch.
2. The list has `agents ...` section headers and `<source> <skill>` lines; currently one section: `agents claude-code codex`.
3. It diffs against `skills ls -g` and the snapshot from the previous install: adds missing skills, removes ones the list dropped, reinstalls skills whose agents changed. Skills installed here but never in the repo are only reported.
4. Adds run once per source and agent set: `pnpx skills@latest add <source> -g -s <name>... -a claude-code -a codex -y`, from `~` with telemetry off.
5. The skills CLI copies each skill into `~/.agents/skills/<name>` (tracked in `~/.agents/.skill-lock.json`, 54 entries today) and links `~/.claude/skills/<name> -> ../../.agents/skills/<name>`.
6. Codex appears to read `~/.agents/skills` directly (inference). `~/.codex/skills` holds only Codex's own skills (.system, chronicle, gh-fix-ci, playwright, and others), none from his repos.
7. Skills install from GitHub, not ~/fun/skills, so an edit lands only after a push and a reinstall or `skills update -g` (`upgrade.sh --apply` runs it).
8. `copy.sh` writes locally added skills back into agent-skills.txt, using the lock file's skill path for subdirectory sources such as cursor/plugins/pstack.

## 6. Key configuration

Repo layout: `base/` (home/ mirrors $HOME; Brewfile, pnpm-globals.txt, agent-skills.txt, apps.txt), `profiles/<name>/` (profile.sh hooks, whole-file home/ overrides, patches/ per base file). Scripts: install.sh, upgrade.sh (Homebrew, MAS, toolchain, pnpm/uv globals, agent skills, and when present Unblocked `unblocked update --yes` and Boat `boat self-update`; dry run prints Unblocked/Boat versions only), copy.sh (pulls machine edits back, asks base vs profile per hunk; conflicts go to `.conflicts/<key>`), utils.sh, set_defaults.sh, tests/e2e.sh. Since 2026-11-07 Boat is on the upgrade path when `boat` is on PATH, and the personal profile versions the Boat shell integration (`profiles/personal/home/.zshenv` adds ~/.ascii/bin to PATH, and `profiles/personal/patches/home/.zshrc.patch` adds the boat() wrapper). Since 2026-11-08 the base Brewfile installs `steipete/tap/remindctl` (a CLI for Apple Reminders) on both profiles, and the personal apps.txt adds Grok Bot.

Grok Bot fleet (versioned since 2026-10-31): snapshots in `base/bots/<bot>/` (profile.json, settings.json, routines/*.md) plus `base/bots/shared/` (unsettled-threads.shape.json; the setup map lives in `profiles/zerofox/bots/shared/setup-map.md` since 2026-11-02); per-profile differences as patches under `profiles/<p>/patches/bots/`, and a bot only one profile has as whole files under `profiles/<p>/bots/<bot>/`; roster in `profiles/<p>/bots.txt`, each with its own IDs. The zerofox roster lists 7 bots: Router, Closer, Side Closer, Spark, T3 Tots, Workflowy, Kaizen. The personal roster lists those 7 plus Chief of Staff (`profiles/personal/bots/chief-of-staff/`, profile.json and settings.json, no routines). `bots/snapshot.sh` filters a staged export through `bots/fields.txt`, scans it for secrets, merges fleet changes since the last snapshot and asks per change base vs profile; `--list` and `--expect` let a bot relay those questions and answers (a fingerprint rejects answers to a stale list). The per-change sorter lives in utils.sh, and patches can delete files. Docs in `bots/README.md` and `bots/INSTALL.md` (installing the fleet on a new Grok Bot account). After a clean apply, snapshot.sh deletes the staging folder and its `<staging>.*` siblings, but only when the folder sits directly in /tmp, $TMPDIR or the user temp folder; on an error or warning it keeps them. `bots/snapshot.sh --discard <staging>` drops a snapshot without applying it. `bots/README.md` also documents renaming or removing a bot and `bots/snapshot.sh --sync-record`.

Fleet behavior history. Since 2026-11-01 no bot settles a T3 thread on its own; the owning bot asks Gabriel whether to settle, keep open, or file follow-ups first. Since 2026-11-02 (landed directly on master; PR #1 https://github.com/gabrielrojasc/configuration/pull/1 closed unmerged) base bot text is account-neutral (Closer's lane is "the Linear teams or projects he names as his main line"), and the zerofox profile patches the Executive Protection wording back in. Since 2026-11-03 (snapshots 16 to 19): Admin is renamed Spark with slug `spark` everywhere, the ledger routes T3 decisions by owner lane (Closer main line, Side Closer everything else, Workflowy tooling, Kaizen personal), Workflowy has a `friday-harness-friction-review.md` routine, zerofox has a per-fleet `profiles/zerofox/bots/shared/workflow-map.md`, every bot counts Gabriel's yes relayed by Workflowy in his quoted words as his yes for exactly that change, and T3 Tots starts a new T3 thread in ~/fun/configuration for each bot snapshot. Since 2026-11-08 Closer, Side Closer, Workflowy and Kaizen carry "Before asking Gabriel whether to settle a thread, show him the open items T3 Tots found." on both profiles; Closer also has an avatar (red blob) and Side Closer a brown one, and Kaizen's blue avatar color is cleared. Since 2026-11-10 every bot's description carries a lookup rule: "Lookup, not investigation: a Grok Bot may retrieve items it knows and summarize them within its lane." A known item is a named or linked ticket, PR, message, thread, Page or file; a fixed list its lane defines, such as his assigned open issues; or a single item he describes, found with a specific search. Open-ended searching (web searches included), diagnosis or recommendations that draw on several sources, and all code and repo work go to T3 Tots for the owning T3 thread; a specific search with no clear match is handed off, not widened. The rule holds in chat and in routines and never widens a bot's lane or its sending and approval rules. It replaces "Connectors are fine for reading tickets, PRs and messages." in Closer, Side Closer, Spark, Workflowy and Kaizen; Spark and Kaizen now do drafts but no longer research; Side Closer now "looks up what it names" instead of "digging in"; and T3 Tots loses "Read-only checks such as git status, git diff or git log are fine to run yourself." On the personal profile, Closer's start-of-day brief is now one flat list of at most 6 items ranked by what needs Gabriel first (decisions and replies only he can give, then blocked or overdue work, then what moves next), with no project or team headings. Each item is one or two plain sentences (what it is, why it matters today, the next step), linked by the title of what the link opens, and the brief ends with one line for the top item outside RunMyDay from Side Closer. The zerofox brief keeps the project-level format.

Also since 2026-11-10 the personal fleet has a Chief of Staff bot that works on coordination only. Its account covers his personal life and RunMyDay work, with no ZeroFox access. It reads the ledger and asks Closer, Side Closer, Workflowy and Kaizen for their open items with SendToAgent, opening a linked item only to judge its state. When he asks what's going on, it leads with the one to three things only he can move. It ranks them by how much work each unblocks, then by effect on RunMyDay customers or his job search, then by deadline, with quick ones first on ties. Each gets what it is, why it matters now, the decision, a recommendation and a link, followed by one line per bot and one line on what it moved. It may change who owns an item and nothing else: ledger owners through T3 Tots, and other items by asking the bot that holds them to hand them off. When lanes don't decide ownership, it asks him in one line. When the same kind of item keeps landing in the wrong lane, it sends Workflowy the examples. An item is stalled when it isn't waiting on him and neither its ledger entry nor its ticket has changed in three working days. It asks the owning bot once per stall and brings the item to him only when only he can move it. It passes his answers in his own words to the owning bot. It runs a weekday morning bot health check that stays silent unless something is broken, and otherwise messages him only when he writes. It tags each item's owning bot as `@<name>`, and never settles, merges, deploys, approves, writes to Linear, or sends in his name. Its description carries the same "How Gabriel works" terms and lookup rule as the other bots.

Apply backs up replaced files to `~/.config-backup/<timestamp>`; `~/.codex/config.toml` is written only when missing (both profiles own the whole file; the personal one gained `migratedFollowUpQueueToSteer = false` on 2026-11-08).

Profiles: `personal` and `zerofox`. Selected by `DOTFILES_PROFILE` in the repo's git-ignored `.env`, overridable by the environment; scripts stop if it's missing or unknown. ZeroFox Mac: `.env` says `DOTFILES_PROFILE=zerofox`. Personal Mac: `.env` says `DOTFILES_PROFILE=personal`. Zerofox uses Workbrew (/opt/workbrew) and proto (node, pnpm), a KeyboardRemap login app, and 1Password `op` for shell secrets; personal uses mise.

~/.codex/AGENTS.md (shared rules; CLAUDE.md imports it)
- Doors: two-way doors (edits, own branches, pushes, PRs, COMMENT reviews, ~/tmp/specs/) proceed and report after. One-way doors (deploys, shared envs incl. QA/staging, messages as him, APPROVE/REQUEST_CHANGES, auth changes, discarding others' work) need him. Skip rubber stamps. Approval carries to subagents.
- Core rules: be thorough in analysis and bold in recommendations; read AGENTS.md/CLAUDE.md root-down first; simplest correct solution; one source of truth; root causes; stay in scope; no secrets in files; verify with the strongest check before reporting.
- Writing: readable cold, concise, apply unslop; lead with the bottom line; ask in chat at the end (unattended skills use the question tool); judgment calls need a `Second opinion: <provider> picks X because Y` line; link items; Conventional Comments labels.
- Documentation: no emojis in Markdown or docs; developer-documentation-style.
- Environment: `fd -L` / `rg -L` (skills are symlinks); repo tooling, not globals; narrow searches.
- External services: assume auth; `gh` for GitHub; connectors for Slack and Google.
- Personal knowledge: `~/work/brain`, personal requests only, read-only, search file names only.
- Git: `git pull --ff-only` before analyzing; signed Conventional Commits; `ref:` Linear footer; ready-for-review PRs; Conventional Branch names; rebase and `--force-with-lease`.
- Coding: impeccable / frontend-design / emil-design-eng for UI; stdlib first; no code comments except public API or external constraints.
- Testing: end-to-end tests by default, with an inspectable artifact and reproduce command.
- Tracker: Linear; to-spec and to-tickets rules (section 4); repos under `~/git/<repo>/`; git-workspace worktrees.
- Multi-agent: rung agents `proven`, `unproven`, `unruly`, `consequential` (~/.claude/agents/*.md, ~/.codex/agents/*.toml); other provider via T3 `delegate_task`; every brief has a done check.
- Waiting: before ending a turn that promises to wait, watch, or report back, confirm something will wake the agent (a PR watch, a background command or subagent it started, or a scheduled task for a later date or a long wait) and say what it is, or say nothing will and name who picks it up. Stop waiting once the next step no longer depends on it (end state reached, handing back or asking him, or only a person can move it): unwatch the PR, stop its commands, name who holds the item, unless he asked to keep watching. Keep waiting through no-change wakes while checks or a bot review still run on the current head.

Zerofox patch: "I work across ZeroFox repos."; GitHub searches scoped to `org:riskive`; Grafana MCP for observability; unblocked-context-research before searching PRs, Slack, Linear, docs one by one; Linear defaults to the EP team.
Personal patch: AWS via `--profile runmyday-agent`, ask before using `runmyday` (admin).

~/.claude/CLAUDE.md: imports ~/.codex/AGENTS.md and unslop's SKILL.md, plus "Hidden skills": a `/skill-name` not in the list means read `~/.claude/skills/<name>/SKILL.md` and follow it.

T3 settings (base/home/.t3/userdata)
- settings.json: favorites Claude Opus 5.5 and Codex gpt-6.1-sol; default model claudeAgent claude-opus-5-5, effort high, 1m context; defaultRuntimeMode auto (personal patch removes it); compactIdleThreads with idleCompaction beforeCacheExpires; autoResumeLimitedThreads; no auto-settle; text generation on claude-haiku-5-5; empty branchNamePrefix; reviewGuidesEnabled.
- client-settings.json: notifications off; stacked diffs ignoring whitespace; browser search via unduck.link; skills shown in slash menu; followUpBehavior steer; send on Enter; plan mode off; sidebar grouped by repository; snapshot (meta pair) on; mathRenderingEnabled false; effort shown as a label; boring sidebar and thread-details usage off. Since 2026-11-08 it no longer sets redesignEnabled, composerCollapseOnScroll, or sidebarThreadPreviewCount.

## 7. Known oddities

- hill-climb is in the skills repo but not in `base/agent-skills.txt` or either profile's patch, so `install.sh` won't install it. On the personal Mac, `~/.agents/skills/hill-climb` and `~/.claude/skills/hill-climb` don't exist.
- Chief of Staff's fleet list names an Admin bot ("non-routed: Gabriel opens it himself for general Slack and email questions"), but no committed roster or bot folder has one. Admin files exist only as uncommitted work in the local checkout.
- Chief of Staff's description includes a weekday morning bot health check, but the bot has no routine to run it, and Router already runs the same check through its `weekday-morning-bot-sweep.md` routine.
- No other bot's description names Chief of Staff, even though it asks Closer, Side Closer, Workflowy and Kaizen for open items and asks T3 Tots to change ledger owners. Workflowy's "Current bots" list on the personal profile still stops at Kaizen.
- On the personal profile, Closer's description still says its weekday brief "gives a project-level overview, one line per main-line project rather than individual issues", but its start-of-day brief routine now asks for one flat list with no project or team headings. The routine and the description disagree.
- The four lane bots (Closer, Side Closer, Workflowy, Kaizen) say "show him the open items T3 Tots found", but on configuration master neither T3 Tots's profile nor its routines mention finding open items or running `anything-open-or-settle`, and no committed file installs that skill on any bot. Until that lands, the lane bots expect input T3 Tots isn't told to produce.
- Seen on the ZeroFox Mac on 2026-11-08, not rechecked this refresh: `~/.claude/skills/llm-council` is a dangling absolute link to ~/.agents/skills/llm-council (not in the lock or any list).
- Seen on the ZeroFox Mac on 2026-11-08, not rechecked this refresh: `~/.claude/skills/pr-review` is an absolute link (/Users/grojas/.agents/skills/pr-review), unlike the relative links for the rest; it resolves.
- Seen on the ZeroFox Mac on 2026-11-08, not rechecked this refresh: `~/fun/configuration/.conflicts/home/.codex` is a leftover from copy.sh conflict handling (an empty directory; git ignores it).
- The zerofox profile removes linear-work-breakdown and linear-gh-linking, but its AGENTS.md still says "Create Linear issues through `linear-work-breakdown`".
- to-spec's own description says it publishes to the tracker; AGENTS.md says it never touches Linear. AGENTS.md wins.
