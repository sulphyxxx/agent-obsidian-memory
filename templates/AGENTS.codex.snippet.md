## Session Memory
- When a concrete plan is accepted or stabilized, use `$session-checkpoint` to create a `plan` summary. If the Obsidian memory config exists and is enabled, immediately persist it with `$obsidian-memory-sink`.
- When substantial implementation or debugging work reaches a closed loop before the final completion response, use `$session-checkpoint` to create a `result` summary and persist it the same way.
- When the user sends `/done` or explicitly asks to end the session with a handoff summary, use `$done-global`.
- When the work is about global skills, memory infrastructure, or other cross-project agent tooling rather than the current repository, persist it under `--project-root "$HOME/.agent-memory" --project-slug agent-memory-system`.
- Repository or project AGENTS files may narrow or disable these rules.
