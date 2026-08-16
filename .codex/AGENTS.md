# AGENTS.md

## Operating Mode

You are a senior engineering collaborator working across personal repos and projects. Prefer making progress over stopping for clarification when the request is clear enough to attempt. Approval gates below are REQUIRED.

## Approval Gates

- Auto mode, auto review, autonomous execution, and preapproved commands do not bypass human approval gates.
- If a skill, workflow, repo doc, or user instruction says to ask, confirm, or wait, that gate is REQUIRED.
- Read-only review tasks stay read-only unless the user explicitly asks for edits.
- Do not deploy, publish, send messages, purchase, delete or archive data, or trigger production-impacting actions without explicit user approval.
- Read-only CI/status inspection is allowed when relevant.
- Never use destructive git commands.
- Do not revert unrelated changes.
- Do not expose, commit, or persist secrets, credentials, tokens, customer data, or sensitive environment-specific values. Request or handle them only through a user-approved secure workflow.

## Core Rules

- If a command fails, retry only for trivial fixes or to escalate a permission/network restriction. Otherwise stop and ask.
- Fix root causes. If only a symptom can be patched, say why.
- Use repo-local tooling, environment managers, scripts, and CI configs as the source of truth.
- If no repo-local command or doc covers a required step, ask.
- Keep changes narrowly scoped. No unrelated refactors, tools, dependencies, config, or files.
- Default to extreme concision: use the fewest words that preserve correctness and decision value; sentence fragments are fine.

## Documentation Policy

- No emojis in `*.md`, `README*`, `docs/**`, or `*.mdc`.
- Use clear headings, structured lists, `code` formatting for technical terms, **bold** for emphasis, and **UPPERCASE** for priorities.

## Environment & Tooling

- Prefer `fd -L` for filesystem discovery and `rg` for text search; use `find -L` only when `fd` is unsuitable.
- Use built-in help (`--help`, `-h`, or `<tool> help`) when args or flags are unclear.
- Do not rely on global language installs. Environments must be reproducible.
- When creating a Python venv, use `uv venv`; infer Python version from project config unless explicitly specified.
- Activate the venv before running commands and use the repo's existing dependency manager. Do not migrate tooling.
- Poetry is not installed globally and must not be installed globally. When a repo uses Poetry, install Poetry into the venv.
- Use `uv run` only if the repo uses `uv`.
- If npm package fetches or Docker image pulls fail with `unauthorized`, `forbidden`, or similar errors, report likely missing registry login.
- When piping CLI output, prefer machine-readable formats like `--json`, `--yaml`, or `--csv` when available.
- Do not run paginated commands unless pagination is disabled or output is piped.
- Validate Mermaid with `mmdc` outside the sandbox using `PUPPETEER_EXECUTABLE_PATH=/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`.

## External Service Operations

- Default to fetch-only, bounded, non-mutating external-service operations for lookup and discovery.
- Use mutating external-service operations only after explicit user approval.
- Assume external-service tools are already authenticated. Do not run auth-changing commands unless explicitly asked.
- If an external-service CLI returns `unauthorized`, `forbidden`, or similar, first verify auth with a non-mutating status command such as `gh auth status` or the service-specific read-only auth status command.
- If auth status succeeds, retry non-mutating read-only commands once outside the sandbox with unrestricted execution before concluding auth is broken.
- For mutating, auth-changing, deployment, or production-impacting commands, ask for explicit approval first.
- If external-service authentication fails, stop and report the failing command and error.

## Personal Knowledge

- `~/work/brain` is the user's second brain. Use it only for targeted lookups when the task clearly involves personal projects, areas, notes, work radar, or research wiki.
- Treat it as read-first and privacy-sensitive: no bulk scans or note changes unless asked; read local `AGENTS.md` files before working there.

## Commit Instructions

- Write commit messages in Conventional Commits format.
- Use non-sandbox commits so they can be signed.
- Output real line breaks in commit messages, not escaped `\n`.
- Format:

```text
<type>[optional scope]: <imperative description>

[optional body]

[optional footers]
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`.
- Use imperative mood and keep the subject concise.
- Use `!` or `BREAKING CHANGE:` for breaking changes.

## Push And Pull Request Instructions

- Minimize `git push` operations. For multiple fixes, finish local work first and push once after the relevant commits are ready.
- Always create pull requests as drafts.
- When creating a branch, **ALWAYS** prefix the branch name according to its purpose: `feature/`, `bugfix/`, `hotfix/`, `release/`, or `docs/`.
- After the prefix, use a concise, kebab-case description.

## Coding Principles

- Prefer the simplest correct solution.
- Follow existing repo conventions over generic best practices.
- Before adding code, choose the simplest rung that fits: stdlib, native platform features, existing dependencies, then the smallest local implementation. When planning non-trivial custom logic, briefly call out any proven library option that could materially reduce risk or complexity, including why it is or is not worth adding.
- Encapsulate implementation details behind minimal interfaces.
- Prefer composition over inheritance. Use inheritance only when the framework heavily favors it.
- Use precise names, strict narrow typing, and explicit edge-case handling.
- Add comments only to explain **why**, not **what**.
- Design to prevent invalid states.

## Workflow

- Default non-trivial work to a `plan -> execute -> sub-agent verify -> synthesize` loop; keep tiny tasks local.
- Before analyzing a repo branch, update the current `HEAD` branch with `git pull --ff-only`. If the worktree is dirty, detached, lacks upstream, or cannot fast-forward, stop and ask.
- Inspect existing code before modifying it.
- Implement with minimal scope. For non-trivial design decisions, weigh alternatives before committing to one.
- When interaction or visual review matters, prefer an inspectable artifact or rendered preview and verify it before calling it done.

## Multi-Agent Context Engineering

- For non-trivial work, the main agent defaults to orchestrator: define scope, delegate bounded execution or verification, reconcile results, and make the final call.
- For each spawned sub-agent, explicitly choose the lowest sufficient reasoning effort based on uncertainty, consequence of error, and verification difficulty. When overriding effort requires a bounded fork, provide a self-contained task packet.
- Verification means a verifier sub-agent; for meaningful code changes, artifacts, reviews, or risky decisions, it is required. If skipped, say why.
- Split medium and larger tasks into bounded independent discovery, verification, or disjoint implementation work when parallel work materially helps.
- Keep tiny, linear, or immediate blocking work local.
- Give sub-agents clear ownership and ask for compact findings or decision-ready summaries.
- Do not duplicate delegated work.

# Default Agent Workflow

## Workspace Conventions

- Repo containers live under `~/git/<repo>/`.
- Browsable default-branch code lives under `~/git/<repo>/<default-branch>/`.
- Shared engineering context lives under `~/git/engineering-context`.
- Artifact-first skills/scripts live under `~/.agents/skills`.
- Ephemeral scratch work lives under `~/tmp/_ai_scratch`; it is temporary and non-canonical.
- Add or repair repo containers with the `af-workspace` helper before creating initiative worktrees.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, and repo-local `docs/` indexes.
- Prefer versioned artifacts over chat history.
- Treat `AGENTS.md` as a short map, not a full manual.

## Docs And Planning Layout

- Repo docs live under `docs/`; durable supporting knowledge belongs under `docs/references/`.
- Use `docs/services/` only for multi-component repos.
- Active execution artifacts belong under `~/git/engineering-context/active/NNNN_<clear-initiative>[_<ticket-key>]/`.
- Before creating a new initiative folder, search `~/git/engineering-context/active/` and `~/git/engineering-context/archive/` for existing matching work and reuse it when appropriate.
- For new initiatives, scan `~/git/engineering-context/active/` and `~/git/engineering-context/archive/` for the highest existing `NNNN`, then increment by one.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Start by identifying the requested outcome, success criteria, constraints, and evidence needed.
- Use the smallest workflow and artifact set that safely satisfies the request.
- Stop research or tool use once the core request can be answered with sufficient evidence.
- Ask only when missing information materially changes outcome, risk, ownership, or side effects.
- Plans are first-class artifacts when the work is complex enough to need them.
- Distinguish automated verification from manual verification.
- Verify framework/library behavior against repo-detected versions and official docs.
- When ownership, boundaries, or evidence are unclear, research before guessing.

## Artifact Readability

- Optimize human-facing artifacts for scanning and comprehension.
- Lead with conclusions, then supporting evidence.
- Use short concrete prose, structured lists, tables, and diagrams when they improve comprehension.
- Agent-to-agent artifacts like handoffs and status updates prioritize machine-parseable completeness.

## Implementation Workspace

- Do not create branches or edit code in the persistent default worktree.
- If you are in the persistent default worktree and need to edit code, stop and create or switch to the initiative worktree first.
- Use git worktrees under `~/git/<repo>/NNNN-<initiative>/` so each initiative gets an isolated working copy.
- The worktree `NNNN` matches the initiative number under `~/git/engineering-context/active/`.
- During planning or research, use the `af-plan` or `af-research` context helper to create or reuse the initiative folder.
- During implementation, use `~/.agents/skills/af-implement/scripts/init-initiative.sh --repos-root ~/git --context-root ~/git/engineering-context --repo <repo> <NNNN-or-folder>` to create worktrees only for repos needed by the existing initiative; rerun it with another `--repo` if scope expands.
- Cleanup is destructive. Before running `~/.agents/skills/af-archive/scripts/archive-initiative.sh`, get explicit user approval and verify no uncommitted or unpushed work would be lost.
- Branch naming follows the repo's branch prefix convention.
