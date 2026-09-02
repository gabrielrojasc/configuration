@~/.codex/AGENTS.md

## Hidden skills

- Some installed skills set `disable-model-invocation: true`, so they never appear in the available-skills list. Every installed skill lives under `~/.claude/skills/`.
- When I name a `/skill-name` that is not in the list, do not report it missing and do not improvise the task: read `~/.claude/skills/<name>/SKILL.md` and follow it as if invoked. Resolve `<SKILL_DIR>`, relative links, and bundled scripts against that directory.
- If that exact directory does not exist, list `~/.claude/skills/` and use the obvious match. Ask only when nothing matches.
