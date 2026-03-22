# agent-obsidian-memory

`agent-obsidian-memory` is a small skill pack for Codex- and Claude-style agents that turns `plan`, `result`, and `handoff` checkpoints into durable Obsidian notes.

## Why It Exists

Most Obsidian AI tools focus on chatting inside the vault. This project focuses on the opposite direction: agents doing work elsewhere, then writing structured memory back into Obsidian.

The workflow is intentionally split into two parts:
- `session-checkpoint` creates the structured summary.
- `obsidian-memory-sink` persists that summary into Obsidian.

`done-global` remains the explicit session wrap-up entrypoint.

## Included Skills

- `session-checkpoint`
- `obsidian-memory-sink`
- `done-global`

## Note Layout

The sink writes notes under a configurable root prefix, default `Agents/`:

- `Projects/<project>.md`
- `Daily/YYYY-MM-DD.md`
- `Sessions/<project>/<year>/<timestamp>_<trigger>.md`

## Install

### Codex

```bash
cd ~/skills/agent-obsidian-memory
./scripts/install.sh --target codex
cp examples/obsidian-memory.json.example ~/.codex/memories/obsidian-memory.json
```

Then edit `~/.codex/memories/obsidian-memory.json` and set `vault_root`.

### Claude

```bash
cd ~/skills/agent-obsidian-memory
./scripts/install.sh --target claude
```

Copy `examples/obsidian-memory.json.example` into the config location used by your Claude workflow, then set the vault path.

## Releases

Release tags use `vX.Y.Z` format. The manual release flow is documented in `RELEASING.md`.

## Typical Flow

1. Generate a structured checkpoint with `session-checkpoint`.
2. Persist it with `obsidian-memory-sink`.
3. Use `done-global` for explicit `/done` handoffs.

For cross-project agent tooling or memory-system work, route the note to `agent-memory-system` with `--project-slug agent-memory-system`.

## Repository Layout

- `skills/`: the reusable skills
- `templates/`: AGENTS templates for Codex and Claude
- `examples/`: example config files
- `scripts/`: install helper

## Status

This repo is a workflow pack, not an Obsidian plugin or a hosted service. It is designed to be copied into existing agent setups and adapted as needed.

## License

MIT
