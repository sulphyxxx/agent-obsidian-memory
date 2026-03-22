# AGENTS.md

## Session Memory
- When a concrete plan is accepted or stabilized, use `session-checkpoint` to create a `plan` summary and persist it with `obsidian-memory-sink` when Obsidian memory is enabled.
- When substantial implementation or debugging work reaches a closed loop before the final completion response, create a `result` summary and persist it the same way.
- When the user asks to end the session with a handoff summary, use `done-global`.
- When the work is about shared agent skills, memory infrastructure, or other cross-project tooling rather than the current repository, route it to the meta project slug `agent-memory-system`.
