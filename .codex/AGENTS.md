# AGENTS.md

## Working with me

I'm Gabriel. I work across ZeroFox repos and care about simple systems, traceable evidence, direct communication, and low duplicated state.

Make progress when the request is clear enough to attempt. Check available sources before asking me for facts. Ask before consequential decisions that change the task's scope, target, ownership, user-visible contract, or external state beyond what I requested.

## Approval gates

- Automation and preapproved commands do not bypass my approval gates.
- Follow every approval gate stated by me, the repository, a skill, or the active workflow.
- When I ask for a review, explanation, audit, diagnosis, or status report, treat the request as read-only unless I also ask for changes.
- Get my approval before actions that speak for me, create commitments, risk disruption to others, or are costly to undo. Consider consequences a rollback cannot erase. For these actions, prepare the work first and show me the proposed action and impact for approval.
- Do not deploy directly. I trigger deployments manually through GitHub Actions, Jenkins, or the relevant release system. Read-only CI and status inspection is allowed when relevant.
- Preserve unrelated work. Never use destructive Git commands.
- Keep secrets, credentials, tokens, customer data, and sensitive environment values out of files, commits, and responses. Handle them only through a secure workflow I have approved.

## Core rules

- I prefer the simplest correct solution and repository conventions over generic best practices.
- Fix root causes. If only a symptom can be patched, explain why.
- Keep changes within the scope I requested. Avoid unrelated refactors, dependencies, tooling, configuration, or files.
- Use repository-local tooling, environment managers, scripts, and CI configuration as the source of truth.
- When a command fails, inspect the error. Retry the same operation only after a trivial correction or a permission or network escalation.
- Continue with a materially different, bounded diagnostic or recovery step when it is safe, reversible, and within my approved scope.
- Stop and ask when blocked or when the next step is destructive, requires new authority, changes authentication, or changes the task's target or user-visible contract.
- If no repository-local command or documented procedure covers a required build, test, migration, deployment, or other operational step, use only standard, bounded, read-only diagnostics. Ask before choosing an undocumented mutating path.

## Communication

- Apply the `unslop` skill to all prose you write or rewrite. Keep revisions within the task scope. Correctness, exact source text, required formats, repository conventions, and my instructions take precedence.
- I prefer extreme concision. Use the fewest words that preserve correctness and decision value; sentence fragments are fine.
- Match the tone and format I request. Preserve exact code, commands, logs, quotations, citations, and required formats.

## Documentation

- I do not want emojis in `*.md`, `README*`, `docs/**`, or `*.mdc`.
- Apply the `developer-documentation-style` skill when writing, editing, or reviewing developer documentation. Follow repository-specific conventions first.

## Environment and tooling

- Prefer `fd -L` for filesystem discovery and `rg` for text search; use `find -L` only when `fd` is unsuitable.
- Use built-in help when command arguments or flags are unclear.
- Do not rely on globally installed language tools. Keep environments reproducible.
- Use the repository's dependency and environment manager. Do not migrate tooling as part of another task.
- Prefer machine-readable output when piping commands, and disable pagination.
- Never conclude "missing" or "empty" from a channel that swallows errors or silently bounds its coverage (e.g. a sandboxed read behind `2>/dev/null`); re-observe through a path where failure and full scope are visible before acting on absence.

## External services

- Default to bounded, non-mutating external-service lookups.
- Assume service tools are authenticated. Do not change authentication unless I ask.
- If a sandboxed read-only command returns `unauthorized`, `forbidden`, or a similar authentication error, retry that command once outside the sandbox before concluding authentication is broken.
- If the unrestricted retry still fails, run the service's non-mutating authentication status command outside the sandbox. Report the failing command and error. Do not ask me to authenticate unless the status check fails.

## Service-specific operations

- For Slack and the Google suite, discover and use the matching connector.
- Use `unblocked context-research` for bounded, fetch-only semantic search across sources: fuzzy lookup, rationale and history, related incidents, ownership, and cross-repo context. Prefer the Unblocked CLI.
- Use `gh` for GitHub operations. Default GitHub searches to `org:riskive` unless a different scope is explicitly required.
- For Linear work, default to the EP team unless the request or repository specifies another team.
- Use `linear-zf-guidance` when implementation work starts from Linear or when creating branches, commits, or pull requests for Linear-tracked work.

## Personal knowledge

- `~/work/brain` is my second brain. Use it when the task clearly involves my projects, areas, notes, work radar, or research wiki.
- Treat it as read-first and privacy-sensitive. Start with targeted searches and broaden only as needed for the requested coverage. Do not change notes unless I ask, and read its local `AGENTS.md` before working there.

## Git changes

### Commits

- I use Conventional Commits.
- Create signed commits with concise, imperative subjects.
- Use real line breaks in bodies and footers. Mark breaking changes with `!` or `BREAKING CHANGE:`.
- On any branch intended to be merged, at least one commit must include a `ref:` footer with the Linear issue ID or URL. If none does, ask `What's the Linear issue or URL for ref?` before finalizing the commit message.

### Branches and pull requests

- I prefer one push after the relevant local commits are ready.
- Create pull requests in ready-for-review state unless I or the repository explicitly request a draft.
- Prefix new branches with `feature/`, `bugfix/`, `hotfix/`, `release/`, or `docs/`, followed by a concise kebab-case description.

## Coding principles

- Before adding code, choose the simplest rung that fits: standard library, native platform features, existing dependencies, then the smallest local implementation.
- When non-trivial custom logic is planned, mention any proven library that could materially reduce risk or complexity and explain whether it is worth adding.
- Prefer small interfaces, composition, narrow typing, explicit edge-case handling, and data models that prevent invalid states.
- Write comments to explain why. Keep them current when the code moves or changes.

## Workflow

- Before researching or analyzing a repository branch, run `git pull --ff-only`. Continue if it succeeds, including when the worktree has unrelated changes. If it fails, do not stash, reset, rebase, or otherwise alter the existing work. Report the failure and ask.
- Inspect existing code before modifying it.
- Keep implementation within the requested scope. Weigh alternatives before consequential design decisions.
- When interaction or visual review matters, produce an inspectable artifact or rendered preview and verify it before completion.

<!-- BEGIN gabrielrojasc/skills -->

## Tracker and implementation workspace

- Linear is my default issue tracker unless the repository explicitly states otherwise. Linear owns active scope, dependencies, ownership, and progress. Git owns code, branches, worktrees, and commits.
- For skills that require `docs/agents/issue-tracker.md`, treat this section as its replacement. Do not require a repository-local copy or ask me to run tracker setup. Use Linear directly.
- `to-spec` always writes an unpublished Markdown spec under `~/tmp/specs/`. It must not create or update Linear entities.
- Use the approved spec as input to `to-tickets`; publish approved tickets to the chosen Linear project.
- Fetching Linear data is read-only. Get my explicit approval before creating or updating issues, projects, comments, or workflow state, except status updates for authorized work: started when work begins, review when ready, and completed after verification.
- When creating Linear work on my behalf, assign issues to me and set me as the project lead in the same operation whenever Linear supports those fields.
- Only add Linear labels that I explicitly request. Create or remove labels only when I explicitly request that exact change. Skill defaults do not count as approval.
- I keep repository containers under `~/git/<repo>/`. The persistent default-branch worktree lives at `~/git/<repo>/<default-branch>/` and is used for browsing and synchronization.
- Before implementation, use the `git-workspace` skill to create or select an isolated task worktree. If I explicitly ask you to use the current checkout, follow that instruction instead.
- Keep stable technical knowledge in repository documentation and ADRs. Do not mirror active Linear state into planning files.

<!-- END gabrielrojasc/skills -->

## Multi-agent work

- Match ceremony to risk. Keep small, sequential work in the main session.
- Delegate bounded work when parallel discovery, disjoint implementation, or independent verification materially reduces time or risk.
- Give each sub-agent one clearly owned task, a compact deliverable, and a checkable completion criterion. Do not duplicate work.
- Use an independent verifier when a meaningful change or risky decision would otherwise be difficult or expensive to check.
- Explicitly choose and set the model and reasoning effort for every subagent based on its hardest assigned work. Never rely on defaults or inherited settings.
- Bounded retrieval, extraction, and mechanical edits with clear checks: Luna high or Sonnet high.
- Self-contained implementation, review, and synthesis with clear requirements: Astra medium or Opus high.
- Ambiguous investigations or synthesis, architectural tradeoffs, conflicting evidence: Astra high or Fable high.
- Exceptionally difficult reasoning, including verification: Astra xhigh or Fable xhigh.
