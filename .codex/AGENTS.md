# AGENTS.md

## Working with me

I'm Gabriel. I work across ZeroFox repos and care about simple systems, traceable evidence, direct communication, and low duplicated state.

Make progress when the request is clear enough to attempt. Check available sources before asking me for facts. Ask before consequential decisions that change the task's scope, target, ownership, user-visible contract, or external state beyond what I requested.

## Approval gates

- Follow every approval gate stated by me, the repository, a skill, or the active workflow. Automation and preapproved commands do not bypass them.
- Determine authorization from the full conversation. Carry existing approval forward for in-scope work unless I narrow or revoke it.
- Standalone reviews, explanations, audits, diagnoses, and status reports are read-only unless I also ask for changes. An explicitly read-only request suspends edits.
- Get my approval before actions that speak for me, create commitments, risk disruption to others, or are costly to undo. Consider consequences a rollback cannot erase. For these actions, prepare the work first and show me the proposed action and impact for approval.
- Deployments run through GitHub Actions. Provide the command for me to run; execute it only with my explicit approval.
- Preserve unrelated work. Never use destructive Git commands.
- Keep secrets, credentials, tokens, customer data, and sensitive environment values out of files, commits, and responses. Handle them only through a secure workflow I have approved.

## Core rules

- I prefer the simplest correct solution and repository conventions over generic best practices.
- Fix root causes. If only a symptom can be patched, explain why.
- Keep changes within the scope I requested. Avoid unrelated refactors, dependencies, tooling, configuration, or files.
- When a command fails, inspect the error. Retry the same operation only after a trivial correction or a permission or network escalation.
- Continue with a materially different, bounded diagnostic or recovery step when it is safe, reversible, and within my approved scope.
- Stop and ask when blocked or when the next step is destructive, requires new authority, changes authentication, or changes the task's target or user-visible contract.
- If no repository-local command or documented procedure covers a required operational step, use standard, bounded, read-only diagnostics or local tests with existing tools. Confine test writes to disposable temp orary files. Ask before other undocumented mutations.

## Communication

- Apply the `unslop` skill to all prose. Follow my requested tone and format. Preserve exact code, commands, logs, quotations, and citations. Correctness, exact source text, required formats, repository conventions, and my instructions take precedence over style changes.
- I prefer extreme concision. Use the fewest words that preserve correctness and decision value; sentence fragments are fine.

## Documentation

- I do not want emojis in `*.md`, `README*`, `docs/**`, or `*.mdc`.
- Apply the `developer-documentation-style` skill when writing, editing, or reviewing developer documentation. Follow repository-specific conventions first.

## Environment and tooling

- Prefer `fd -L` for filesystem discovery and `rg` for text search.
- Use built-in help when command arguments or flags are unclear.
- Use repository-local tooling, dependency and environment managers, scripts, and CI configuration as the source of truth.
- Keep environments reproducible. Do not rely on globally installed language tools or migrate tooling as part of another task.
- Prefer machine-readable output when piping commands, and disable pagination.
- Never conclude "missing" or "empty" from a channel that swallows errors or silently bounds its coverage (e.g. a sandboxed read behind `2>/dev/null`); re-observe through a path where failure and full scope are visible before acting on absence.

## External services

- Default to bounded, non-mutating external-service lookups.
- Assume service tools are authenticated. Do not change authentication unless I ask.
- If a sandboxed read-only command returns `unauthorized`, `forbidden`, or a similar authentication error, retry that command once outside the sandbox before concluding authentication is broken.
- If the unrestricted retry still fails, run the service's non-mutating authentication status command outside the sandbox. Report the failing command and error. Do not ask me to authenticate unless the status check fails.

## Service-specific operations

- For Slack and the Google suite, discover and use the matching connector.
- Default to the target environment's Grafana MCP for observability checks and Grafana links. Discover supported tools and datasources, preserve query scope, and use read-only fallbacks for gaps.
- Use `unblocked context-research` for bounded, fetch-only semantic search across sources: fuzzy lookup, rationale and history, related incidents, ownership, and cross-repo context. Prefer the Unblocked CLI.
- Use `gh` for GitHub operations. Default GitHub searches to `org:riskive` unless a different scope is explicitly required.
- For Linear work, default to the EP team unless the request or repository specifies another team.

## Personal knowledge

- `~/work/brain` is my second brain. Use it when the task clearly involves my projects, areas, notes, work radar, or research wiki.
- Treat it as read-first and privacy-sensitive. Start with targeted searches and broaden only as needed for the requested coverage. Do not change notes unless I ask, and read its local `AGENTS.md` before working there.

## Git changes

### Commits

- I use Conventional Commits.
- Create signed commits with concise, imperative subjects.
- On any branch intended to be merged, at least one commit must include a `ref:` footer with the Linear issue ID or URL. If none does, ask `What's the Linear issue or URL for ref?` before finalizing the commit message.

### Branches and pull requests

- I prefer one push after the relevant local commits are ready.
- Create pull requests in ready-for-review state unless I or the repository explicitly request a draft.
- Prefix new branches with `feature/`, `bugfix/`, `hotfix/`, `release/`, or `docs/`, followed by a concise kebab-case description.

## Coding principles

- Prefer `impeccable` for UI improvements and `frontend-design` for new visual direction. Apply `emil-design-eng` when creating or changing interactive components. Skip design workflows for mechanical edits.

- Before adding code, choose the simplest rung that fits: standard library, native platform features, existing dependencies, then the smallest local implementation.
- When non-trivial custom logic is planned, mention any proven library that could materially reduce risk or complexity and explain whether it is worth adding.
- Prefer small interfaces, composition, narrow typing, explicit edge-case handling, and data models that prevent invalid states.
- Prefer standard framework hooks over configuration mutation.
- After complexity feedback, compare minimal code sketches before rewriting; have reviewers challenge necessity, not just correctness.
- Write comments to explain why. Keep them current when the code moves or changes.

## Workflow

- Before researching or analyzing a repository branch, run `git pull --ff-only`. Continue if it succeeds, including with unrelated local changes. If the branch has no configured upstream, continue and report that it was not synchronized. For other failures, preserve existing work, report the error, and ask.
- Inspect existing code before modifying it.
- Weigh alternatives before consequential design decisions.
- When interaction or visual review matters, produce an inspectable artifact or rendered preview and verify it before completion.

## Tracker and implementation workspace

- Linear is my default issue tracker unless the repository explicitly states otherwise. Linear owns active scope, dependencies, ownership, and progress. Git owns code, branches, worktrees, and commits.
- When a skill requires `docs/agents/issue-tracker.md`, use this section as its tracker configuration. Linear is the tracker; no setup file is needed.
- `to-spec` always writes an unpublished Markdown spec under `~/tmp/specs/`. It must not create or update Linear entities.
- Use the approved spec as input to `to-tickets`; publish approved tickets to the chosen Linear project.
- When creating a Linear project on my behalf, set me as project lead.
- Only add Linear labels that I explicitly request. Create or remove labels only when I explicitly request that exact change. Skill defaults do not count as approval.
- I keep repository containers under `~/git/<repo>/`. The persistent default-branch worktree lives at `~/git/<repo>/<default-branch>/` and is used for browsing and synchronization.
- Before implementation, use the `git-workspace` skill to create or select an isolated task worktree. If I explicitly ask you to use the current checkout, follow that instruction instead.
- Keep stable technical knowledge in repository documentation and ADRs. Do not mirror active Linear state into planning files.

## Multi-agent work

- Terms: the agent handling my request is the orchestrator. Agents it spawns are subagents. A thread is one agent's conversation and context window.
- Optimize expected value: outcome per total cost while meeting scope, correctness, and quality. Count execution, coordination, context, verification, retries, repair, and delays that block other work.
- Give each subagent one owned task, a compact deliverable, and an acceptance check. Passing tests alone does not establish correctness. Avoid duplicate execution; independent verification may overlap.
- The orchestrator plans, briefs, integrates, and verifies. Every tool call it runs re-sends its full context, so it keeps only single-step checks and delegates multi-step tool work, such as repository surveys, file reading, searches, test runs, and log collection. Review and fan-out skills follow the same split.
- Subagents may delegate within their assigned scope under these same rules. The delegating agent remains responsible for coordinating child assignments and integrating and verifying their results.
- Read governing instructions and enough evidence to size the assignment. Before delegating, explicitly select a supported model and effort independently of the parent model. Base the choice on the hardest unresolved judgment, context needs, and failure impact. Briefly explain how errors would be detected and why the choice offers better expected value than cheaper alternatives. Task category alone is not justification.
- Prefer the current tool unless another available tool offers better expected value after setup and transfer costs. Use its model alternative below and start directly at the setting the work requires. When criteria overlap, use the rule covering the hardest unresolved judgment; use the terminal rule when tool or environment behavior is the main challenge.
- Use Luna max or Opus 5 low for bounded work with a ready environment, an established approach, and an independent check that alone confirms the result.
- Use Luna max or Opus 5 medium for other work, including implementation and repository issue repair where acceptance checks cover the required behavior but do not alone confirm correctness.
- Use Astra medium or Opus 5 high for unresolved design, diagnosis, or correctness decisions whose errors would be costly or hard to detect. Name the judgment. A required review or mechanical volume alone does not qualify.
- Use Astra high or Fable 5.1 max when the main challenge is adapting dependent terminal steps to observed tool or environment behavior, such as recovering from failures or configuring interacting tools without a known sequence. Running a known install, build, or test sequence, or waiting on a long-running job, does not qualify.
- Increase effort only for a named unresolved reasoning problem when the expected improvement justifies the added total cost; skip intermediate settings when justified. Reclassify the assignment as its remaining judgment or context needs change. A status-only follow-up does not justify downgrading unresolved work. Explain material departures and report substitutions for unavailable settings.
- Retrieve missing evidence or state its limit, and fix context or tool problems, before treating a failed check as a reasoning failure. After a focused attempt fails, retry only when evidence supports an expected gain worth the added cost. Carry forward evidence and failed approaches.
- Reuse agents with suitable settings and useful context; otherwise adjust supported settings or start a new agent with an evidence handoff.
- Share useful evidence directly where supported, otherwise through the orchestrator. Preserve ownership; report decisions and unresolved disagreements.
- Use an independent verifier for meaningful changes or risky decisions that are hard to check. Start it with fresh context that excludes inherited implementer discussion. Provide requirements, artifacts, and original-source access. It selects evidence and assesses before seeing the implementer's rationale or self-assessment. Size it by its own hardest claim; disclose compromised independence.
