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

Run the installer from the repository root:

```bash
cd ~/skills/agent-obsidian-memory
./install.sh --target codex
```

or:

```bash
cd ~/skills/agent-obsidian-memory
./install.sh --target claude
```

The installer:
- installs the three skills into the target skills directory
- creates or updates the target `AGENTS.md`
- creates `~/.codex/memories/obsidian-memory.json` if it does not already exist

Codex and Claude share the same default memory config path:

```bash
~/.codex/memories/obsidian-memory.json
```

After installation, edit that file and set `vault_root`.

### Existing Files

The installer is designed to be safe to re-run:

- existing skill folders are replaced with the versions from this repo
- existing `AGENTS.md` content is preserved, and only the managed Session Memory block is inserted or updated
- existing `obsidian-memory.json` is preserved and not overwritten
- when an existing `AGENTS.md` is modified, a backup file is created first

### Advanced Usage

```bash
./install.sh --target codex --skills-dir /custom/skills --agents-file /custom/AGENTS.md --config-file /custom/obsidian-memory.json
```

## Releases

Release tags use `vX.Y.Z` format. The manual release flow is documented in `RELEASING.md`.

## Typical Flow

1. Generate a structured checkpoint with `session-checkpoint`.
2. Persist it with `obsidian-memory-sink`.
3. Use `done-global` for explicit `/done` handoffs.

For cross-project agent tooling or memory-system work, route the note to `agent-memory-system` with `--project-slug agent-memory-system`.

## Repository Layout

- `skills/`: the reusable skills
- `templates/`: full AGENTS templates plus mergeable Session Memory snippets
- `examples/`: example config files
- `scripts/`: installer implementation

## Status

This repo is a workflow pack, not an Obsidian plugin or a hosted service. It is designed to be copied into existing agent setups and adapted as needed.

## License

MIT
