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

# Default Agent Workflow

## Workspace Conventions

- Code repositories live under `~/fun`.
- Shared engineering context lives under `~/fun/engineering-context`.
- Ephemeral scratch work lives under `~/tmp/_ai_scratch` -- not a second documentation system.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, repo-local `docs/` indexes. Prefer versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs & Planning Layout

- Repo docs live under `docs/`; supporting knowledge under `docs/references/`; `docs/services/` only for multi-component repos.
- Execution artifacts default to `~/fun/engineering-context/active/<clear-initiative>[_<ticket-key>]/` for both single-repo and cross-repo work.
- Use repo-local docs for durable knowledge worth preserving from completed work: architecture notes, commands, pitfalls, service cards, and implementation learnings with ongoing value.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts; keep `decisions/` for tradeoffs that need a durable record.
- Stable service reference cards go in `~/fun/engineering-context/service-catalog/`; cross-repo dependency maps in `~/fun/engineering-context/dependency-maps/`.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Plans are first-class artifacts. Compact useful exploration into durable Markdown.
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
- Consistent terminology throughout the artifact. Pick one term for a concept and keep it.
