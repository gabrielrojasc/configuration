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

## Commit Instructions

- Write commit messages in Conventional Commits format.
- For any branch intended to be merged, **AT LEAST ONE** commit on that branch **MUST** include a `ref:` footer.
- Use non-sandbox commits so they can be signed.
- Output real line breaks in commit messages, not escaped `\n`.
- Format:

```text
<type>[optional scope]: <imperative description>

[optional body]
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
- Use imperative mood and keep the subject concise.
- Use `!` or `BREAKING CHANGE:` for breaking changes.

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

## Multi-Agent Context Engineering

- For medium and larger tasks, prefer splitting bounded work across sub-agents so the main agent keeps its context focused on orchestration, decisions, and integration.
- Keep tiny or fully linear tasks local when delegation overhead exceeds the context benefit, and keep the immediate blocking step local when delegation would slow the critical path.
- Delegate independent discovery, verification, and disjoint implementation work when possible, with clear ownership and no duplicated effort.
- Ask sub-agents for compact findings and decision-ready summaries rather than raw context dumps.

