---
name: obsidian-memory-sink
description: Use when a structured checkpoint summary already exists and must be persisted into the configured Obsidian vault as project, daily, and session notes.
---

# Obsidian Memory Sink

## Overview

Persist an existing structured summary into Obsidian. This skill does not invent summary content; it reads a finished markdown summary file and writes the corresponding notes.

## Workflow

1. Ensure a summary file already exists, usually from `$session-checkpoint` or `$done-global`.
2. Load the vault settings from `~/.codex/memories/obsidian-memory.json` unless the command already specifies them.
3. Run `scripts/write_obsidian_memory.sh`.
4. Report the created or updated note paths.

## Inputs

- Required:
  - `summary_file`
  - `trigger` in `plan|result|handoff`
  - `project_root`
- Optional:
  - `project_slug`
  - `session_id`
  - `vault_root`
  - `root_prefix`

## Command

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/obsidian-memory-sink/scripts/write_obsidian_memory.sh" \
  --summary-file "$summary_file" \
  --project-root "$project_root" \
  --trigger "$trigger"
```

Add `--project-slug "$project_slug"` when the note should be classified under a meta project instead of the current repository slug. Add `--session-id "$session_id"` when available. Override vault settings only when needed.

## Notes

- If the config is disabled, report that the write was skipped rather than forcing output.
- Do not rewrite the summary content inside the sink; regenerate the summary upstream if it is wrong.
- Use the note contract in `references/note-contract.md` when you need to reason about the output layout.
- For global Codex skills, memory infrastructure, or other cross-project work, prefer `--project-root "${CODEX_HOME:-$HOME/.codex}" --project-slug agent-memory-system`.

## Resources

- `scripts/write_obsidian_memory.sh`: Deterministic note writer.
- `references/note-contract.md`: Output layout and frontmatter contract.
