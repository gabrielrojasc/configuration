# AGENTS.md

## Working with me

I'm Gabriel. I care about simple systems, traceable evidence, direct communication, and low duplicated state.

Make progress when the request is clear enough to attempt. When a step doesn't need my input, keep going, and put status notes in the same message as your next action. Check available sources before asking me for facts. Ask before consequential decisions that change the task's scope, target, ownership, user-visible contract, or external state beyond what I requested.

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
- Stop and ask when blocked or when the next step deletes data or is otherwise destructive, requires new authority, changes authentication, or changes the task's target or user-visible contract.
- Ask before changing files or settings outside the task's repository, worktree, or what I asked you to change. Temporary files, tool-managed caches, and locations these instructions specify, such as `~/tmp/specs/` and task worktrees, don't need approval.
- If no repository-local command or documented procedure covers a required operational step, use standard, bounded, read-only diagnostics or local tests with existing tools. Confine test writes to disposable temporary files. Ask before other undocumented mutations.

## Communication

- Apply the `unslop` skill to all prose. Follow my requested tone and format. Preserve exact code, commands, logs, quotations, and citations. Correctness, exact source text, required formats, repository conventions, and my instructions take precedence over style changes.

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
- Use `gh` for GitHub operations.

## Personal knowledge

- `~/work/brain` is my second brain. Use it when the task clearly involves my projects, areas, notes, work radar, or research wiki.
- Treat it as read-first and privacy-sensitive. Start with targeted searches and broaden only as needed for the requested coverage. Do not change notes unless I ask, and read its local `AGENTS.md` before working there.

## Git changes

### Commits

- I use Conventional Commits.
- Create signed commits with concise, imperative subjects.
- On any branch intended to be merged, at least one commit must include a `ref:` footer with the Linear issue ID or URL. If none does, ask `What's the Linear issue or URL for ref?` before finalizing the commit message.

### Branches and pull requests

- Create pull requests in ready-for-review state unless I or the repository explicitly request a draft.
- Prefix new branches with `feature/`, `bugfix/`, `hotfix/`, `release/`, or `docs/`, followed by a concise kebab-case description.
- Update a branch from its base by rebasing onto it, never by merging the base in.

## Coding principles

- Prefer `impeccable` for UI improvements and `frontend-design` for new visual direction. Apply `emil-design-eng` when creating or changing interactive components. Skip design workflows for mechanical edits.

- Before adding code, choose the simplest rung that fits: standard library, native platform features, existing dependencies, then the smallest local implementation.
- When non-trivial custom logic is planned, mention any proven library that could materially reduce risk or complexity and explain whether it is worth adding.
- Prefer small interfaces, composition, narrow typing, explicit edge-case handling, and data models that prevent invalid states.
- Prefer standard framework hooks over configuration mutation.
- Write comments to explain why. Keep them current when the code moves or changes.

## Testing

- Prove features with end-to-end tests that drive the real system along the path a user takes. Make them the default and usually the only tests you add.
- End each end-to-end run with an artifact I can inspect and regenerate, such as a log, screenshot, recording, or output file. Record the command that reproduces it in or next to the artifact, and show it in the response only when I ask for it.
- Add an isolated test only for behavior an end-to-end test cannot reach or pin down. Write it before the code: list every way the unit can fail, turn that list into tests, then implement.

## Workflow

- Before researching or analyzing a repository branch, run `git pull --ff-only`. Continue if it succeeds, including with unrelated local changes. If the branch has no configured upstream, continue and report that it was not synchronized. For other failures, preserve existing work, report the error, and ask.
- When interaction or visual review matters, produce an inspectable artifact or rendered preview and verify it before completion.

## Tracker and implementation workspace

- Linear is my default issue tracker unless the repository explicitly states otherwise. Linear owns active scope, dependencies, ownership, and progress. Git owns code, branches, worktrees, and commits.
- When a skill requires `docs/agents/issue-tracker.md`, use this section as its tracker configuration. Linear is the tracker; no setup file is needed.
- `to-spec` always writes an unpublished Markdown spec under `~/tmp/specs/`. It must not create or update Linear entities.
- Use the approved spec as input to `to-tickets`; publish approved tickets to the chosen Linear project.
- When creating a Linear project on my behalf, set me as project lead.
- Assign Linear issues I create, or that you create on my behalf, to me unless I name another assignee.
- Only add Linear labels that I explicitly request. Create or remove labels only when I explicitly request that exact change. Skill defaults do not count as approval.
- I keep repository containers under `~/git/<repo>/`. The persistent default-branch worktree lives at `~/git/<repo>/<default-branch>/` and is used for browsing and synchronization.
- Before implementation, use the `git-workspace` skill to create or select an isolated task worktree. If I explicitly ask you to use the current checkout, follow that instruction instead.
- Keep stable technical knowledge in repository documentation and ADRs. Do not mirror active Linear state into planning files.

## Multi-agent work

- Terms: the agent handling my request is the orchestrator. Agents it spawns are subagents. A thread is one agent's conversation and context window.
- Match the thread to the work. When a task needs repeated tool calls and a cheaper rung covers it, delegate instead of running them in the current thread.
- Delegate only to the rung agents `bounded`, `unproven`, `consequential`, and `unruly`. Choose by description. When criteria overlap, use the rung covering the hardest unresolved judgment.
- Before treating a failed check as a reasoning failure, retrieve missing evidence and fix context or tool problems. Retry or escalate only when evidence supports the expected gain.
- Subagents may delegate within their scope under these rules. The delegating agent integrates and verifies the results.
- Use an independent verifier for meaningful changes or risky decisions that are hard to check. Give it fresh context, requirements, artifacts, and source access, and withhold the implementer's rationale until it has assessed. Size it by its own hardest claim.
