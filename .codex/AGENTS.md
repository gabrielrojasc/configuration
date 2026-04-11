# AGENTS.md

## Core Rules

- If a command fails, retry only for obvious trivial issues. Otherwise stop and ask.
- Always fix root causes, not symptoms.
- Do not revert unrelated changes.
- Never use destructive git commands.
- When piping CLI output through other tools, prefer machine-readable formats like `--json`, `--yaml`, or `--csv` when available.
- Do not run paginated commands unless pagination is disabled or output is piped.
- Keep communication concise and direct.

## Documentation Policy

- No emojis in:
  - `*.md`
  - `README*`
  - `docs/**`
  - `*.mdc`

Use:

- **Bold** for emphasis
- `Code` formatting for technical terms
- **UPPERCASE** for priorities (REQUIRED, WARNING, IMPORTANT)
- Clear headings and structured lists

## Deployments

- All deployments are made either through GitHub Actions or Jenkins and manually triggered by the user.

## Environment & Tooling

- Use repo-local tooling and environment managers.
- Do not rely on global language installs.
- Environments must be reproducible.
- Python venvs MUST be created with `uv venv` (infer Python version from project config; use `--python <version>` only if explicitly specified).
- Activate the venv before running commands, and use the repo’s existing dependency manager inside it. Use `uv run` only if the repo uses `uv` for dependencies. Do not migrate tooling.
- If a command fails due to permissions or network restrictions, retry with escalation before attempting any workaround or environment modification.
- npm package fetches and Docker image pulls may require prior registry login. If an install or pull fails with `unauthorized`, `forbidden`, or similar registry/auth errors, treat missing login as a likely cause and tell the user before assuming a generic network problem.

- When using `find` or `fd`, include the flag to follow symlinks (`find -L` or `fd -L`/`fd --follow`).

- Follow existing repo workflows and tooling.
- Use defined scripts (npm, Makefile, etc.) instead of creating new ones.
- Consult CI configs (GitHub Actions) for canonical build/test commands.

## External Service Operations

- Default to fetch-only, read-only external-service operations for lookup and discovery work.
- Use mutating external-service operations only when the user explicitly asks for them or when they are indispensable to complete the requested task.
- Assume external-service tools are already authenticated. Do not run auth-changing commands unless the user explicitly asks.
- If an external-service CLI returns `unauthorized`, `forbidden`, or a similar auth error, first verify auth with a non-mutating status command such as `acli jira auth status` or `gh auth status`.
- If the auth status succeeds, retry the original command once outside the sandbox, with unrestricted execution, before concluding the failure is an auth problem.
- If external-service authentication fails, stop and report the failing command and error so the user can fix authentication.

## GitHub Operations

- Use the `gh` CLI for GitHub operations (issues, PRs, releases, search, API).
- Default GitHub searches to `org:riskive` unless a different scope is explicitly required.
- Docs: https://cli.github.com/manual/

## Atlassian Operations

- Use `acli jira` for Jira operations.
- Prefer `acli jira workitem view <ticket> --fields '*all'` when full ticket context is needed.
- Prefer bounded queries with `--limit` for discovery. Use `--paginate` only when the full result set is required and the output is being piped or redirected.
- Examples from `acli` help:
  - View a ticket: `acli jira workitem view KEY-123`
  - View all fields for a ticket: `acli jira workitem view KEY-123 --fields '*all'`
  - View selected fields as JSON: `acli jira workitem view KEY-123 --fields summary,comment --json`
  - Search by JQL: `acli jira workitem search --jql "project = TEAM" --limit 50`
  - Search selected fields as CSV: `acli jira workitem search --jql "project = TEAM" --fields "key,summary,assignee" --csv`
- Docs: https://developer.atlassian.com/cloud/acli/reference/commands/jira/

## Commit Instructions

- Write commit messages in Conventional Commits format.
- For any branch intended to be merged, **AT LEAST ONE** commit on that branch **MUST** include a `ref:` footer.
- Use non-sandbox commits so they can be signed.
- Output real line breaks in commit messages, not escaped `\n`.
- Format:

```text
<type>[optional scope]: <imperative description>

[optional body]

ref: <Jira ticket or URL>
[optional other footers]
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
- Use imperative mood and keep the subject concise.
- Use `!` or `BREAKING CHANGE:` for breaking changes.
- If no commit on the branch includes `ref:`, ask: `What’s the Jira ticket or URL for ref?` before finalizing the commit message.

## Pull Request Instructions

- When creating a branch, **ALWAYS** prefix the branch name according to its purpose.
- Use `feature/` for new features, for example `feature/login-system`.
- Use `bugfix/` for non-critical bug fixes, for example `bugfix/header-styling`.
- Use `hotfix/` for critical production fixes created from the production branch, for example `hotfix/critical-security-issue`.
- Use `release/` for release preparation branches, for example `release/v1.0.1`.
- Use `docs/` for documentation updates or fixes, for example `docs/api-endpoints`.
- After the prefix, use a concise, kebab-case description of the change.

## Coding Principles

- Prefer the simplest correct solution.
- Reduce complexity; avoid cleverness.
- Encapsulate implementation details behind minimal interfaces.
- Use precise naming.
- Add comments only to explain **why**, not **what**.
- Design to prevent invalid states.
- Handle edge cases explicitly.
- Use strict, narrow typing.

## Workflow

1. Understand requirements and constraints.
2. Inspect existing code before modifying it.
3. Consider at least two approaches for non-trivial problems.
4. Implement with minimal scope.
5. Self-review for simplicity, correctness, and consistency.

## Scope Discipline

- Do not introduce new tools or patterns without clear necessity.
- Follow existing repo conventions over generic best practices.
- No unrelated refactors.

# Default Agent Workflow

## Workspace Conventions

- Code repositories live under `~/git`.
- Shared engineering context lives under `~/git/engineering-context`.
- Implementation worktrees live under `~/worktree`.
- Ephemeral scratch work lives under `~/tmp/_ai_scratch` -- not a second documentation system.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, repo-local `docs/` indexes. Prefer versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs & Planning Layout

- Repo docs live under `docs/`; supporting knowledge under `docs/references/`; `docs/services/` only for multi-component repos.
- Execution artifacts default to `~/git/engineering-context/active/NNNN_<clear-initiative>[_<ticket-key>]/` for both single-repo and cross-repo work.
- `NNNN` is a zero-padded sequence number assigned globally across `active/` and `archive/`. Scan both directories for the highest existing number and increment by one.
- Use repo-local docs for durable knowledge worth preserving from completed work: architecture notes, commands, pitfalls, service cards, and implementation learnings with ongoing value.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts; keep `decisions/` for tradeoffs that need a durable record.
- Stable service reference cards go in `~/git/engineering-context/service-catalog/`; cross-repo dependency maps in `~/git/engineering-context/dependency-maps/`.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Plans are first-class artifacts. Compact useful exploration into durable Markdown.
- The structure-approval proposal is also a first-class Markdown artifact, not just a chat message.
- Distinguish automated verification from manual verification.
- Verify framework/library behavior against repo-detected versions and official docs, not memory.
- When ownership, boundaries, or evidence are unclear, research before guessing.

## Artifact Readability

Human-facing artifacts -- plans, research, decision records -- must optimize for scanning and comprehension. Agent-to-agent artifacts like handoffs and status updates prioritize machine-parseable completeness instead.

- Lead each section with the conclusion or key takeaway, then supporting detail.
- Short declarative sentences. Cut filler phrases ("it should be noted", "in order to", "it is important that").
- Concrete over abstract: specific file paths, function names, and version numbers over vague references.
- Use bullet lists for three or more related items. Use tables for comparisons or structured attribute sets.
- One idea per paragraph. No wall-of-text blocks.
- Write headings that state the finding or decision, not just the topic (prefer "Auth middleware stores tokens in plaintext" over "Auth middleware analysis").
- Use **bold** for key terms on first mention and for emphasis.
- Use Mermaid diagrams for flows, dependency graphs, and architecture when visual structure aids comprehension over prose.
- For planning artifacts, include Mermaid sequence diagrams in both the proposal and the final plan when they clarify flow, rollout, or ownership; skip them only when they would add no value.
- Consistent terminology throughout the artifact. Pick one term for a concept and keep it.

## Implementation Workspace

Do not create branches or edit code directly in `~/git`. Use git worktrees so each initiative gets an isolated working copy and the main checkouts stay clean.

Setup: run the installed `af-implement` helper script. It assigns the next sequence number, creates the initiative folder structure, fetches all repos, and creates worktrees under `~/worktree/NNNN/<repo>/`.

```bash
<SKILLS_ROOT>/af-implement/scripts/init-initiative.sh \
  --repos-root ~/git \
  --context-root ~/git/engineering-context \
  --worktrees-root ~/worktree \
  [--branch-prefix feature] \
  <initiative-name> [ticket-key]
```

All implementation happens inside `~/worktree/NNNN/<repo>/`. Branch naming follows the repo's branch prefix convention (e.g., `feature/`, `bugfix/`, `hotfix/`).

Cleanup: run the installed `af-archive` helper script to remove worktrees, delete local branches, and move the initiative to `~/git/engineering-context/archive/`.

```bash
<SKILLS_ROOT>/af-archive/scripts/archive-initiative.sh \
  --repos-root ~/git \
  --context-root ~/git/engineering-context \
  --worktrees-root ~/worktree \
  [--delete-remote] <NNNN>
```
