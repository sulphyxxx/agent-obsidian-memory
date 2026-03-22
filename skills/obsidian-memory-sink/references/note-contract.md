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
- Purpose: append-only timeline
- One entry per written checkpoint

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
