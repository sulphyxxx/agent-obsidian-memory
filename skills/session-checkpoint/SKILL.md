---
name: session-checkpoint
description: Use when a stable plan, substantial implementation result, or explicit handoff needs to be captured as a structured checkpoint summary before the context moves on or is persisted elsewhere.
---

# Session Checkpoint

## Overview

Create a structured markdown summary for a `plan`, `result`, or `handoff` checkpoint. This skill owns the summary content, not the storage backend.

## Workflow

1. Decide the trigger: `plan`, `result`, or `handoff`.
2. Copy the template from `assets/checkpoint_template.md`.
3. Fill every section with facts from the current conversation only.
4. Save the filled template to a temporary markdown file.
5. Report the summary file path so another skill or script can persist it.

## Trigger Rules

- `plan`: A concrete plan was accepted or stabilized enough that later work should be measured against it.
- `result`: A meaningful implementation, fix, or debugging loop reached a stopping point and should be recorded before the final response.
- `handoff`: The user asked for `/done`, an end-of-session note, or a handoff summary.

## Content Rules

- Use facts only. Do not guess missing commands, files, or outcomes.
- Keep section bullets short and scannable.
- Write `- None` when a section has nothing real to record.
- Preserve exact command lines when they matter for reproduction.
- For `plan`, keep `Completed Work`, `Changed Files`, and `Commands + Validation` minimal unless real work already happened.
- For `result` and `handoff`, include concrete file paths and verification evidence.

## Required Output

Save the completed markdown to a temp file and surface the path in the response as `SUMMARY_FILE=<path>`.

Recommended command:

```bash
summary_file="$(mktemp -t codex-checkpoint.XXXXXX.md)"
```

Then write the completed template into that file.

## Resources

- `assets/checkpoint_template.md`: Canonical checkpoint sections. Copy it verbatim, then fill the bullets.
