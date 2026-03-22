# agent-obsidian-memory

`agent-obsidian-memory` is a skill pack for Codex- and Claude-style agents that turns structured work checkpoints into durable Obsidian notes.

It is for people who already run agent workflows and want memory written back into their vault after the work is done. It is intentionally **not an Obsidian plugin** and not a chat-in-vault assistant.

## Why It Exists

Most Obsidian AI tooling focuses on interacting inside the vault. This project focuses on the opposite direction: agents do work elsewhere, then write the durable summary back into Obsidian in a predictable format.

The workflow is intentionally split:

- `session-checkpoint` creates the structured summary
- `obsidian-memory-sink` writes that summary into Obsidian
- `done-global` handles explicit end-of-session handoffs

## Quick Start

Install from the repository root:

```bash
cd ~/skills/agent-obsidian-memory
./install.sh --target codex
```

or:

```bash
cd ~/skills/agent-obsidian-memory
./install.sh --target claude
```

Then edit:

```bash
~/.codex/memories/obsidian-memory.json
```

and set `vault_root` to your Obsidian vault.

## What It Installs

The installer:

- installs `session-checkpoint`, `obsidian-memory-sink`, and `done-global`
- creates or updates the target `AGENTS.md`
- creates `~/.codex/memories/obsidian-memory.json` if it does not already exist

It is safe to rerun:

- existing skill folders are replaced with the versions from this repo
- existing `AGENTS.md` content is preserved, and only the managed Session Memory block is inserted or updated
- existing `obsidian-memory.json` is preserved and not overwritten
- when an existing `AGENTS.md` is modified, a backup file is created first

Advanced usage:

```bash
./install.sh --target codex --skills-dir /custom/skills --agents-file /custom/AGENTS.md --config-file /custom/obsidian-memory.json
```

## Who This Is For

This repo is a good fit if you:

- already use Codex, Claude, or similar agent workflows
- want repeatable memory writes into Obsidian after planning, implementation, or handoff
- prefer simple shell-based setup over a hosted service

This repo is probably not the right fit if you want:

- an Obsidian plugin UI
- an in-vault chat assistant
- a general-purpose knowledge management system by itself

## Typical Flow

1. Generate a structured checkpoint with `session-checkpoint`.
2. Persist it with `obsidian-memory-sink`.
3. Use `done-global` for explicit `/done` handoffs.

For cross-project agent tooling or memory-system work, route the note to `agent-memory-system` with `--project-slug agent-memory-system`.

## Releases

Release tags use `vX.Y.Z` format. The manual release flow is documented in `RELEASING.md`.

## Repository Layout

- `skills/`: reusable skills
- `templates/`: full AGENTS templates plus mergeable Session Memory snippets
- `examples/`: example config files
- `scripts/`: installer implementation

## Status

This repo is a workflow pack, not a hosted product. It is designed to be copied into an existing agent setup and adapted as needed.

## License

MIT
