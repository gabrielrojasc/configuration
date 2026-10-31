# Gabriel's agent setup map

What this is: a short map of Gabriel's agent skills, work flows, and machine
configuration, so bots can work the way he does without re-reading both repos.
Built read-only from GitHub (cursor-github connector) and his ZeroFox Mac.

Last refreshed: 2026-10-30 18:07 Chile time (UTC-3)

skills: 21d17dd8c6ab31a3ee352649e3f1685f8c5d08fe 2026-10-29T18:42:28-03:00
configuration: 33ab1bdb46f6fb0d20ada8e1ace7f67c38ac9329 2026-10-27T10:05:00-03:00

- skills (gabrielrojasc/skills, main): "refactor(pr-review): shorten the missing-test, question, and suggestion rules"
- configuration (gabrielrojasc/configuration, master): "chore(t3): search with unduck, enable the redesign, disable math rendering"

## 1. His skills (gabrielrojasc/skills)

Each lives in skills/<name>/ with SKILL.md and agents/openai.yaml. Triggers
are the quoted `description` lines.

- babysit-pr: "Use when asked to babysit a GitHub PR." Runs unattended in rounds (fresh subagent each round): review feedback via gh-review-comments, fixes CI failures the PR causes, rebases when behind, pushes once per round. Ends Merge-ready, Waiting on people, or Blocked. Never merges.
- chief-of-staff: "Use when asked for chief-of-staff updates in T3." Reads his other unsettled T3 threads, ranks what needs him (work by prod impact, Linear project, deadline, effort; personal separately), renders a glance page, tables `RV <repo>#<n>` review threads. On request: tidy threads, Slack follow-ups. Acts on a thread only when asked.
- computer-use: "Use when a task needs a signed-in site or a Mac app." T3 preview tools cover public sites; this covers his signed-in browser and native apps.
- cross-review: "Use when asked to cross-review and fix a change." Runs review-revise with the other provider (Claude vs Codex) as sole reviewer via T3 `delegate_task`; 3 rounds (5 for auth, secrets, data deletion, concurrency). Findings use Conventional Comments labels and IDs; ends with a `Cross-reviewed: ... Verdict: ...` line.
- developer-documentation-style: "Use when working on developer docs." Applies the live Google Developer Documentation Style Guide after repo conventions.
- full-stop: "Use when told 'full stop'." Unattended run from current state to a mergeable PR (see section 3).
- gh-review-comments: "Use when addressing PR review feedback." Classifies feedback, fixes what holds up, replies to every thread, raises only judgment calls. Has fetch scripts.
- git-workspace: "Use when Git repos need cloning, sync, task setup, or cleanup." Bare-container repo layout with one worktree per task (scripts: add-repo, create/remove-task-worktree, sync, list).
- linear-gh-linking: "Use when starting Linear work or linking its PRs." Picks Linear issue IDs and relationship semantics for branches and PRs.
- linear-work-breakdown: "Use when planning Linear levels or tickets." Places work in the right Linear layer (initiative to sub-issue) and creates it the team's way.
- python-environments: "Use when running Python tests or installs." `uv venv`, then the repo's own tooling; no global installs.
- review-revise: "Use when adversarial review loops are requested." Independent reviewers attack work (code, prose, plan); revise until no material objection or the loop stalls.
- rewrite-it: "Use when asked to rewrite text." Rewrites the target (or the last reply) after rereading the Writing rules in ~/.codex/AGENTS.md.
- slack-message: "Use when drafting a Slack message." Formats text he will paste into Slack with Slack markup.
- test-plan: "Use when asked to plan pre-production feature checks." Plans end-to-end checks for shipping to prod, in chat only, and asks for missing access.
- zerofox/pr-review: "Use when reviewing a GitHub PR." Reviewer subagent plus a fresh verifier, raises only judgment calls, submits one review per PR. Installed on the zerofox profile only.

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
5. Run `babysit-pr` until it reports an end state.
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

Repo layout: `base/` (home/ mirrors $HOME; Brewfile, pnpm-globals.txt, agent-skills.txt, apps.txt), `profiles/<name>/` (profile.sh hooks, whole-file home/ overrides, patches/ per base file). Scripts: install.sh, upgrade.sh, copy.sh (pulls machine edits back, asks base vs profile per hunk; conflicts go to `.conflicts/<key>`), utils.sh, set_defaults.sh, tests/e2e.sh. Apply backs up replaced files to `~/.config-backup/<timestamp>`; `~/.codex/config.toml` is written only when missing.

Profiles: `personal` and `zerofox`. Selected by `DOTFILES_PROFILE` in the repo's git-ignored `.env`, overridable by the environment; scripts stop if it's missing or unknown. This Mac: `.env` says `DOTFILES_PROFILE=zerofox`. Zerofox uses Workbrew (/opt/workbrew) and proto (node, pnpm), a KeyboardRemap login app, and 1Password `op` for shell secrets; personal uses mise.

~/.codex/AGENTS.md (shared rules; CLAUDE.md imports it)
- Doors: two-way doors (edits, own branches, pushes, PRs, COMMENT reviews, ~/tmp/specs/) proceed and report after. One-way doors (deploys, shared envs incl. QA/staging, messages as him, APPROVE/REQUEST_CHANGES, auth changes, discarding others' work) need him. Skip rubber stamps. Approval carries to subagents.
- Core rules: read AGENTS.md/CLAUDE.md root-down first; simplest correct solution; one source of truth; root causes; stay in scope; no secrets in files; verify with the strongest check before reporting.
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

Zerofox patch: "I work across ZeroFox repos."; GitHub searches scoped to `org:riskive`; Grafana MCP for observability; unblocked-context-research before searching PRs, Slack, Linear, docs one by one; Linear defaults to the EP team.
Personal patch: AWS via `--profile runmyday-agent`, ask before using `runmyday` (admin).

~/.claude/CLAUDE.md: imports ~/.codex/AGENTS.md and unslop's SKILL.md, plus "Hidden skills": a `/skill-name` not in the list means read `~/.claude/skills/<name>/SKILL.md` and follow it.

T3 settings (base/home/.t3/userdata)
- settings.json: favorites Claude Opus 5.5 and Codex gpt-6.1-sol; default model claudeAgent claude-opus-5-5, effort high, 1m context; defaultRuntimeMode auto (personal patch removes it); compactIdleThreads with idleCompaction beforeCacheExpires; autoResumeLimitedThreads; no auto-settle; text generation on claude-haiku-5-5; empty branchNamePrefix; reviewGuidesEnabled.
- client-settings.json: notifications off; stacked diffs ignoring whitespace; browser search via unduck.link; skills shown in slash menu; followUpBehavior steer; send on Enter; plan mode off; sidebar grouped by repository; snapshot (meta pair) on; mathRenderingEnabled false; redesignEnabled true.

## 7. Known oddities

- `~/.claude/skills/llm-council` is a dangling absolute link to ~/.agents/skills/llm-council (not in the lock or any list).
- `~/.claude/skills/pr-review` is an absolute link (/Users/grojas/.agents/skills/pr-review), unlike the relative links for the rest; it resolves.
- `~/fun/configuration/.conflicts/home/.codex` is a leftover from copy.sh conflict handling (an empty directory as of today; git ignores it, the working tree is clean).
- The zerofox profile removes linear-work-breakdown and linear-gh-linking, but its AGENTS.md still says "Create Linear issues through `linear-work-breakdown`". Neither skill is installed on this Mac.
- to-spec's own description says it publishes to the tracker; AGENTS.md says it never touches Linear. AGENTS.md wins.

## 8. How bots should use this map

T3 Tots keeps this file current. It compares the `skills:` and `configuration:` header lines with each repo's latest commit and rebuilds the map when either changes. Read it before acting on Gabriel's setup, treat it as a summary, and open the source file before quoting a rule. Do not edit it by hand.

## 9. Observed practice

Read-only study of his T3 Code threads on his Mac, 2026-10-30 18:35 to 18:50 Chile time (UTC-3). Tools: `t3 thread list --json` per project, `t3ctl threads`, `t3ctl read --thread <id> --last 2000`. No thread was changed.

Read this section with care (Gabriel, 2026-10-30 18:32 Chile time). Keeping big work in one long thread was a deliberate experiment, run to test whether he needs Matt Pocock's skills (grill-with-docs, to-spec, to-tickets), not a settled preference. Both flows in section 4 are still valid, and bots shouldn't treat either one as the default. The counts below describe what happened, not rules to follow.

Sample and method
- Window: non-archived threads created since 2026-08-01. The oldest listed thread is from 2026-09-23; `t3 thread list` shows no archived threads, so the study covers 2026-09-23 to 2026-10-30 (ISO weeks W39 to W44, W44 partial).
- Listed: 412 threads (git 274, No project 73, skills 35, configuration 27, brain 3).
- Dropped as not his: 24 bot threads marked `createdBy: agent`, `creationSource: mcp` (DLQ root-causes, perf relays, PR review dispatcher `RV` threads; git 22, No project 2). 4 more had a generated first message (hard-wrapped brag-doc prompts, for example "Threat-Actor Ranking Metrics" (40b9fc1f)).
- Subagent threads: `t3ctl threads` lists 1,928 threads, including 840 `thread:delegated-task:` threads (cross-review, verifiers, delegate_task) and 670 `thread:provider:` threads. `t3 thread list` leaves all of them out, and no listed thread has a `parentThreadId`. The earlier 50-thread pass used the same list, so it had no subagent threads; every thread it cited is one of his.
- His threads: 384 (git 250, No project 70, skills 34, configuration 27, brain 3). `createdBy: system` up to Oct 15 (225) and `user` from Oct 16 (159) are both his; the field changed with a T3 update.
- Turns relayed by T3 Tots or his Chief of Staff thread, and routine prompts, were removed from his turns (13 threads had them, for example 9f83da82, c57eacaa, 0b68bb22).
- A script read every one of his turns in all 384 threads. 200 of them, stratified by project and week (git 140, No project 30, skills 16, configuration 12, brain 2), have per-thread notes in results/practice-study/deep-read-notes.md. Counts are for all 384 unless marked (200). Classification is by keyword, so treat small counts as approximate.

Start types
- Plain question or instruction: 139 (200: 70), for example "Where logic goes in Python standards" (2e03e37a).
- `$pr-review <PR or Slack url>`: 105 (200: 63), for example "RV API#5644" (cd841ccd).
- Slack link: 49 (200: 24), for example "Diagnose Slack-Reported Issue Status" (ef545d2f).
- Other URL (repo, doc, article, dashboard): 28, for example "Selective tstack Skill Adoption" (dbd32087).
- Pasted text or output: 13, for example "Investigate Duplicate UPS Alerts" (c05c1ab4).
- Another T3 thread id: 13, for example "P0 Grafana alert for ef545d2f" (1af74885).
- GitHub CI run, commit or PR URL without a skill: 10, for example "Fix or Waive PR 419 DevSecOps Failure" (c697a775).
- Linear issue or project link: 8, for example "European PII removal feasibility study" (4528abbb).
- Another skill command: 8, all W39 to W41: `$improve-codebase-architecture` 4 (for example c57eacaa), `$wayfinder` (8ce97c5b), `$retro` (049db1d1), `$ask-matt` (7bcc802b), `/claude-api` (77af77d0).
- Attached handoff file or report: 5, for example "Internal developer platform on EKS" (d7f07ea7). Test or empty ("a", "asd"): 6.
- None start with grill-with-docs, to-spec or to-tickets.

Flows
- Investigation, answer, draft or ops only, no code: 171 (200: 86), for example "Cosmo-infra slug problem investigation" (f98e0e2a).
- PR review, `$pr-review` then "post it": 105 (200: 63), for example "RV ep-api#421 go-ep#245 grafana-terra#2804" (75245ba3).
- Iterate, then "commit and push" to main (skills, configuration): 35 (200: 19). 16 configuration threads are only "commit and push", for example 056c87a9.
- Iterate, then `$cross-review` and `$babysit-pr` typed by hand: 33 (200: 14), for example "Speed Up Protected Locations Endpoint" (4d1512d0).
- Iterate, then "open a PR" without full stop or cross-review: 23 (200: 14), for example "Add Mypy Type Checking to ep-api" (dc1a80ae).
- Small flow ending in "full stop": 9 (200: 1), for example "Rebuild OSIS dashboard around metrics" (63828ec4).
- Big flow, grill-with-docs then to-spec then to-tickets: 2. "Private Jet Mention Monitoring Rule" (d872f7b8, Sep 30) ran `$grill-with-docs`, `$to-spec` twice, then `$to-tickets`. "Cosmos infra IaC repo structure" (94a90d2b, Oct 13) asked "should we $grill-with-docs", then ran `$to-spec`. Both ended in merged PRs.
- Long threads: 52 have more than 20 of his turns, and 29 of those produced PRs. The longest are "update skills" (77af77d0, 251 turns), "Improve ep-api Architecture" (c57eacaa, 144) and "Chief of Staff" (aff36d85, 143).

Skills and triggers (threads using each, all 384 / 200)
- `$pr-review`: 113 / 68 (`/pr-review` in 7).
- Codex second opinion, "ask codex", "make codex review" inside a Claude thread: 56 / 27.
- `$cross-review`: 33 / 15. `$babysit-pr`: 25 / 10. Usually typed together.
- `/compact`: 32 / 11. "Continue where you left off": 8.
- rewrite-it or "my writing style": 26 / 13.
- `$review-revise` or "poke holes": 24 / 10.
- `$ketchup`: 23 / 10. `$gh-review-comments`: 19 / 10.
- "full stop": 9 / 1, sometimes scoped ("full stop 5581", "AIC team, full stop", "ok, next PR full stop").
- `$show-me` or "teach me visually": 9. "diagnose": 8. `$wait-what`: 8. `$slack-message`: 5.
- Matt Pocock skills: `$code-review` asked of Codex 5, `$improve-codebase-architecture` 4, `$retro` 4, `$grill-me` 3 (4e77250f, 038e154b, 6efbb632), `$to-spec` and `$to-tickets` 3 each (2 uses plus questions about them in ff219626 and 7bcc802b), `$grill-with-docs` 2, `$wayfinder`, `$handoff` and `$ask-matt` 1 each.
- Once or twice: test-plan, git-workspace, chief-of-staff (3).
- He types skills as `$name` (Codex style) far more than `/name`: 257 `$` uses against 53 `/`, and 32 of the `/` uses are `/compact`.
- Never seen: implement, implement-spec, tdd ("red-green-refactor"), grilling by name, triage, prototype, research, bro, unslop by name.

Where he steps in
- Short approvals for the next step ("go ahead", "push it", "post it", "lgtm, merge it"): 157 threads.
- Inline comments on quoted assistant text (T3 quote citations): 84 threads, 532 quoted comments in all; his main way to answer long replies.
- Slack: 38 threads ask for a reply or draft he sends himself ("sent it"); the agent does not send.
- Evidence checks ("did you check", "did you test", "double check"): 25 threads, for example "BM25 ranking in ClickHouse search" (7516e751).
- Deploys through the agent to QA, stag or prod: 24 threads, for example "Tag merged PR and deploy commands" (f498a57d). Merges through the agent: 19, for example "lgtm, merge it" in 2e03e37a and 6ebbcbfa.
- Redirects: 8, for example "Estimate Executive Protection Cost" (50f91255, "we lost direction"), "Pending Query Window Check" (e2d00335, "stop that"), "Cosmos-infra PR review automation" (8ea5f977, "let's just build it").
- Relays: 13 threads got his decisions relayed from the Chief of Staff thread or T3 Tots, for example "Add pyfox and ty to cosmos-infra" (fa0cc562, "ask the chat to merge it").

Endings
- PR merged: 51. PR open: 4 (for example b767475c). PR closed: 2.
- Review posted after he said so: 77. Review with no post request from him: 28 (for example "don't post yet" in 0710b76b).
- Pushed straight to main: 41.
- No code (answer, research, draft, ops): 175. Test or empty: 6.
- Settled 362, unsettled 22.

Provider and model
- Claude Opus 5.5 in 295, Codex in 89 (gpt-6.1-sol 71, gpt-6-sol 18).
- 85 of the 89 Codex threads are `$pr-review` threads; only 4 Codex threads did other work (for example 1f107b98). Codex ran 85 of 105 PR reviews.

Trends by week (threads by creation week; long threads span weeks, and turns carry no timestamps)

| Week | His threads | Claude / Codex | PR reviews on Codex | Matt skill threads | Interview, spec or tickets | full stop | cross-review or babysit-pr by hand |
|---|---|---|---|---|---|---|---|
| W39 (Sep 23-27) | 42 | 26 / 16 | 14 of 15 | 10 | 2 | 1 | 3 |
| W40 (Sep 28-Oct 4) | 47 | 35 / 12 | 12 of 15 | 6 | 3 | 0 | 1 |
| W41 (Oct 5-11) | 87 | 58 / 29 | 28 of 29 | 7 | 1 | 0 | 11 |
| W42 (Oct 12-18) | 70 | 58 / 12 | 12 of 12 | 1 | 1 | 2 | 8 |
| W43 (Oct 19-25) | 86 | 67 / 19 | 19 of 19 | 1 | 0 | 1 | 11 |
| W44 (Oct 26-30) | 52 | 51 / 1 | 0 of 15 | 0 | 0 | 5 | 1 |

- Matt Pocock's skills fell from 10 threads in W39 to 0 in W44. The interview, spec and tickets skills (grill-me, grill-with-docs, to-spec, to-tickets) appear in 7 threads, all created by Oct 13.
- "full stop" took over in W44. The phrase appears from Oct 13 (b767475c, 9f83da82) and late in c57eacaa. He committed the full-stop skill on Oct 26, 12:57 Chile time (gabrielrojasc/skills 19f7b0fa). In W44, 5 threads ended in full stop and 1 used hand-typed cross-review or babysit-pr, against 11, 8 and 11 in W41 to W43.
- PR reviews moved from Codex to Claude: Codex ran 85 of 90 reviews in W39 to W43 and none of the 15 in W44. Claude's overall share went from 62% in W39 to 98% in W44.
- Single long threads stayed the norm for bigger work. Each week had 2 to 7 threads with more than 20 of his turns that produced PRs, while the big flow ran twice (W40, W42).
- `/compact` peaked in W43 (16 threads) and Codex second opinions in W42 and W43 (14 and 16 threads).

Differs from section 4 (observed only; the section 4 flows still stand)
- The big flow ran in full once (d872f7b8) and in part once (94a90d2b), both before mid-October. After that, larger work stayed in one long thread with an ad hoc spec, Claude and Codex agents poking holes (review-revise) and tickets filed during or after the work. This matches the experiment he describes above and doesn't retire the big flow.
- "full stop" ends 9 threads; 33 more used `$cross-review` or `$babysit-pr` typed by hand, mostly W41 to W43, before the full-stop skill existed.
- skills and configuration changes skip PRs and full stop: "commit and push" to main, often in a one-message thread.
- After a PR he often has the agent merge (19 threads) and deploy to QA, stag or prod (24), with explicit approval each time.
- Almost half of his threads (171) change no code: Slack questions, incidents, research and drafts. Another 105 are `$pr-review` reviews.
- Codex second opinions run all through the work (56 threads), well beyond cross-review.
