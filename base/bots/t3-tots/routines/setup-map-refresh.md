---
name: Setup map refresh
trigger: CRON_TZ=America/Santiago 0 19 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Keep the owner's setup map at /home/box/t3-tots/setup-map.md current (approved 2026-10-30 via Workflowy: "Yes, set up the setup map and keep it current"). It's read-only on his repos and Mac.

Using the GitHub connector from my computer (not the owner's Mac), get the latest commit sha and date on gabrielrojasc/skills (branch main) and gabrielrojasc/configuration (branch master). Compare them with the header lines `skills: <sha> <date>` and `configuration: <sha> <date>` in the map. If both match, end with no output at all.

If either changed, read the commits since the header sha and the changed files through the connector, refresh only the affected sections of the map (skills list, external skills from agent-skills.txt, full-stop behavior, work flows, install, configuration pieces, oddities), and update the header sha, date and refresh time (America/Santiago). Header format (Gabriel's call, 2026-10-31): only the "Last refreshed:" line and one `<repo>: <sha> <date>` line per repo; never add commit-message lines (such as `- skills (...): "..."`) to the header. Body format (Gabriel's call, 2026-10-31): never add commit tags such as "(adb9a0a)" or "(gabrielrojasc/skills 19f7b0fa)" in the map body; the header shas are the only commit references. Don't send anything outside, and don't write to the repos.

Stay silent unless the change affects how the bots work: a new or renamed trigger phrase, changed full-stop behavior, or a new or changed work flow. In that case, send one line to Closer (agent id adf96437-85e2-40fa-b4a7-59d3799996dc) by priority agent message saying what changed. Never message the owner from this routine.
