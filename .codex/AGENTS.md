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

## Environment & Tooling

- Use repo-local tooling and environment managers.
- Do not rely on global language installs.
- Environments must be reproducible.
- Python venvs MUST be created with `uv venv` (infer Python version from project config; use `--python <version>` only if explicitly specified).
- Activate the venv before running commands, and use the repo’s existing dependency manager inside it. Use `uv run` only if the repo uses `uv` for dependencies. Do not migrate tooling.
- If a command fails due to permissions or network restrictions, retry with escalation before attempting any workaround or environment modification.

- Follow existing repo workflows and tooling.
- Use defined scripts (npm, Makefile, etc.) instead of creating new ones.
- Consult CI configs (GitHub Actions) for canonical build/test commands.

## External Service Operations

- Default to fetch-only, read-only external-service operations for lookup and discovery work.
- Use mutating external-service operations only when the user explicitly asks for them or when they are indispensable to complete the requested task.
- Assume external-service tools are already authenticated. Do not run auth-changing commands unless the user explicitly asks.
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

- Code repositories usually live under `~/git`.
- Shared cross-repo engineering context lives under `~/git/engineering-context`.
- Ephemeral scratch work lives under `~/tmp/_ai_scratch`.

## Repo Discovery Conventions

- Treat `AGENTS.md`, `README.md`, and repo-local `docs/` indexes as the first stop.
- Prefer repository-local, versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs Map Expectations

- Repo-local docs live under `docs/`.
- Repo-specific plans live under `docs/exec-plans/active/` and `docs/exec-plans/completed/`.
- Supporting knowledge lives under `docs/references/`.
- `docs/services/` is used only when the repo has multiple runtime components.

## Planning Locations

- Repo-local work keeps plans in the repo.
- Cross-repo work keeps research and plans under `~/git/engineering-context/active/<clear-initiative>[_<ticket-key>]/`.
- When a ticket exists, use `<clear-initiative>_<ticket-key>` so the initiative is clear at a glance and the ticket remains a suffix.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Shared Context Extras

- Keep initiative-local decision records under `~/git/engineering-context/active/<clear-initiative>[_<ticket-key>]/decisions/` when cross-repo tradeoffs need a durable record.
- Keep stable service or component reference cards under `~/git/engineering-context/service-catalog/`.
- Keep durable cross-repo dependency or contract maps under `~/git/engineering-context/dependency-maps/`.

## Workflow Rules

- Plans are first-class artifacts.
- Compact useful exploration into durable Markdown.
- Distinguish automated verification from manual verification.
- If ownership, boundaries, or evidence are unclear, do more research instead of guessing.

## Multi-Agent Context Engineering

- For medium and larger tasks, prefer splitting bounded work across sub-agents so the main agent keeps its context focused on orchestration, decisions, and integration.
- Keep tiny or fully linear tasks local when delegation overhead exceeds the context benefit, and keep the immediate blocking step local when delegation would slow the critical path.
- Delegate independent discovery, verification, and disjoint implementation work when possible, with clear ownership and no duplicated effort.
- Ask sub-agents for compact findings and decision-ready summaries rather than raw context dumps.
- When work spans repos or produces durable decisions, prefer concise artifact-backed summaries aligned with `~/git/engineering-context`.

## Scratch Guidance

- Use scratch for copied logs, rough notes, temporary summaries, and intermediate output.
- Scratch is not a second documentation system.
