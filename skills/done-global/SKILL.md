---
name: done-global
description: Use this skill when a user sends `/done` or asks to end a session with a handoff summary. It saves a structured markdown note under the platform-default session-notes root and updates project `SESSION_SUMMARY.md` when that file exists.
metadata:
  short-description: Save /done context globally and in-project
---

# Done Global

Use this skill only for explicit session wrap-up requests.

## Trigger

- User sends `/done`.
- User asks to end the session and save a summary/context handoff.

## Workflow

1. Extract session facts into a concise markdown draft using `assets/done_note_template.md`.
2. Save the draft to a temporary file.
3. Run:
   - `bash "<skills-dir>/done-global/scripts/write_done_note.sh" --project-root "$PWD" --summary-file "$TMP_SUMMARY"`
   - If a session identifier is available, add: `--session-id "<id>"`
4. If the platform-default Obsidian memory config exists and is enabled, also run:
   - `bash "<skills-dir>/obsidian-memory-sink/scripts/write_obsidian_memory.sh" --project-root "$PWD" --summary-file "$TMP_SUMMARY" --trigger handoff`
   - If a session identifier is available, add: `--session-id "<id>"`
   - If the session is about global agent-memory tooling rather than the current repo, replace `--project-root "$PWD"` with `--project-root "<agent-home>" --project-slug agent-memory-system`
5. Read command output and return these fields:
   - `GLOBAL_NOTE`
   - `PROJECT_SUMMARY`
   - `PROJECT_SUMMARY_STATUS`
   - `SESSION_NOTE`
   - `PROJECT_NOTE`
   - `DAILY_NOTE`

## Content Rules

- Facts only; do not guess unknown details.
- Keep sections concise and scannable.
- If nothing happened in a section, write `- None`.
- Keep file list and command list explicit when available.

Platform defaults:

- Codex config: `~/.codex/memories/obsidian-memory.json`
- Claude config: `~/.claude/memories/obsidian-memory.json`
- Codex skills dir: `~/.codex/skills`
- Claude skills dir: `~/.claude/skills`
- Codex session notes: `~/.codex/session-notes`
- Claude session notes: `~/.claude/session-notes`
- Other platforms should pass explicit `--config-file` and resolve the installed skills dir directly

## Required Sections

- `## Discussion Summary`
- `## Key Decisions`
- `## Completed Work`
- `## Open Issues / Risks`
- `## Next Actions`
- `## Changed Files`
- `## Commands + Validation`

## User-Facing Response

- Confirm `/done` summary is saved.
- Show `GLOBAL_NOTE` path.
- Show project summary update status and path.
- If the Obsidian sink ran, show the session, project, and daily note paths.
