# Obsidian Note Contract

The writer creates or updates three note classes under the configured prefix, default `Agents/`.

## Projects

- Path: `Projects/<project-slug>.md`
- Purpose: current project state
- Managed sections:
  - `Current State`
  - `Recent Decisions`
  - `Open Risks`
  - `Next Actions`
  - `Latest Sessions`

## Daily

- Path: `Daily/YYYY-MM-DD.md`
- Purpose: readable same-day overview plus checkpoint timeline
- Managed sections:
  - `Today at a glance`
  - one expanded entry per written checkpoint
- Daily overview includes:
  - total checkpoints
  - touched projects
  - remaining open items count
- Each checkpoint entry includes:
  - project link
  - session link
  - non-empty summary sections such as decisions, completed work, risks, and next actions

## Sessions

- Path: `Sessions/<project-slug>/YYYY/YYYY-MM-DD_HHMMSS_<trigger>.md`
- Purpose: immutable checkpoint snapshot
- Includes frontmatter:
  - `project`
  - `repo_root`
  - `trigger`
  - `generated_at`
  - `session_id`
  - `tags`
