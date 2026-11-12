---
name: Setup map refresh
trigger: CRON_TZ=America/Santiago 0 19 * * 1-5
timing: flexible, earlyMinutes 15, lateMinutes 15
enabled: true
---
Keep the owner's setup map at /home/box/t3-tots/setup-map.md current (approved 2026-10-30 via Workflowy: "Yes, set up the setup map and keep it current"). It's read-only on his repos and Mac.

Reading the repos goes through T3 Code. Send the T3 Code thread titled "Setup map refresh" in ~/fun/configuration, starting it if there is none, the goal: keep the setup map in step with gabrielrojasc/skills (branch main) and gabrielrojasc/configuration (branch master), writing to no repo. Give it the map's header lines `skills: <sha> <date>` and `configuration: <sha> <date>`, and the header and body formats below. Ask it to reply "no change" when both repos match those lines, and otherwise with the full new text of each affected section of the map (skills list, external skills from agent-skills.txt, full-stop behavior, work flows, install, configuration pieces, oddities), the new header lines, and whether the change affects how the bots work. On "no change", end with no output at all. Otherwise replace those sections and the header lines in the map, and update the refresh time (America/Santiago).

Header format (Gabriel's call, 2026-10-31): only the "Last refreshed:" line and one `<repo>: <sha> <date>` line per repo; never add commit-message lines (such as `- skills (...): "..."`) to the header. Body format (Gabriel's call, 2026-10-31): never add commit tags such as "(adb9a0a)" or "(gabrielrojasc/skills 19f7b0fa)" in the map body; the header shas are the only commit references. Don't send anything outside.

Stay silent unless the change affects how the bots work: a new or renamed trigger phrase, changed full-stop behavior, or a new or changed work flow. In that case, send one line to Closer by priority agent message saying what changed. Never message the owner from this routine.
