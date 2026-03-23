#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  write_obsidian_memory.sh --summary-file <file> --trigger <plan|result|handoff> [options]

Required:
  --summary-file <file>       Structured markdown summary to persist.
  --trigger <type>            One of: plan, result, handoff.

Options:
  --project-root <path>       Project path (default: current working directory).
  --project-slug <slug>       Override the derived project slug.
  --session-id <id>           Optional session identifier.
  --vault-root <path>         Override vault root from config.
  --root-prefix <path>        Override note prefix from config. Default: Agents.
  --config-file <path>        Config file path (default: platform-specific default).
  -h, --help                  Show this help.
USAGE
}

default_config_file() {
  local codex_home="${CODEX_HOME:-${HOME}/.codex}"
  local claude_home="${CLAUDE_HOME:-${HOME}/.claude}"
  local codex_home_real
  local claude_home_real
  local script_dir
  codex_home_real="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$codex_home")"
  claude_home_real="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$claude_home")"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  case "$script_dir" in
    "${claude_home_real}/skills/"*)
      printf '%s\n' "${claude_home}/memories/obsidian-memory.json"
      ;;
    "${codex_home_real}/skills/"*)
      printf '%s\n' "${codex_home}/memories/obsidian-memory.json"
      ;;
    *)
      printf '%s\n' "${codex_home}/memories/obsidian-memory.json"
      ;;
  esac
}

project_root="${PWD}"
project_slug=""
summary_file=""
trigger=""
session_id=""
vault_root=""
root_prefix=""
config_file="$(default_config_file)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --project-slug)
      project_slug="${2:-}"
      shift 2
      ;;
    --summary-file)
      summary_file="${2:-}"
      shift 2
      ;;
    --trigger)
      trigger="${2:-}"
      shift 2
      ;;
    --session-id)
      session_id="${2:-}"
      shift 2
      ;;
    --vault-root)
      vault_root="${2:-}"
      shift 2
      ;;
    --root-prefix)
      root_prefix="${2:-}"
      shift 2
      ;;
    --config-file)
      config_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$summary_file" || -z "$trigger" ]]; then
  echo "Missing required arguments." >&2
  usage >&2
  exit 1
fi

case "$trigger" in
  plan|result|handoff) ;;
  *)
    echo "Invalid trigger: $trigger" >&2
    exit 1
    ;;
esac

if [[ ! -f "$summary_file" ]]; then
  echo "Summary file not found: $summary_file" >&2
  exit 1
fi

if ! project_root="$(cd "$project_root" && pwd)"; then
  echo "Invalid --project-root: $project_root" >&2
  exit 1
fi

if [[ -f "$config_file" ]]; then
  eval "$(
    python3 - "$config_file" <<'PY'
import json
import shlex
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

enabled = data.get("enabled", True)
vault_root = data.get("vault_root", "")
root_prefix = data.get("root_prefix", "Agents")

print(f"CONFIG_ENABLED={shlex.quote('true' if enabled else 'false')}")
print(f"CONFIG_VAULT_ROOT={shlex.quote(vault_root)}")
print(f"CONFIG_ROOT_PREFIX={shlex.quote(root_prefix)}")
PY
  )"
else
  CONFIG_ENABLED="true"
  CONFIG_VAULT_ROOT=""
  CONFIG_ROOT_PREFIX="Agents"
fi

if [[ "${CONFIG_ENABLED:-true}" != "true" ]]; then
  echo "SKIPPED_CONFIG_DISABLED=1"
  exit 0
fi

if [[ -z "$vault_root" ]]; then
  vault_root="${CONFIG_VAULT_ROOT:-}"
fi

if [[ -z "$root_prefix" ]]; then
  root_prefix="${CONFIG_ROOT_PREFIX:-Agents}"
fi

if [[ -z "$vault_root" ]]; then
  echo "Vault root is not configured." >&2
  exit 1
fi

mkdir -p "$vault_root"

repo_root="$project_root"
if git -C "$project_root" rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root="$(git -C "$project_root" rev-parse --show-toplevel)"
fi

repo_name="$(basename "$repo_root")"
if [[ -z "$project_slug" ]]; then
  project_slug="$(
    printf '%s' "$repo_name" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
  )"
else
  project_slug="$(
    printf '%s' "$project_slug" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
  )"
fi

if [[ -z "$project_slug" ]]; then
  echo "Project slug resolved to empty." >&2
  exit 1
fi

ts="$(date '+%Y-%m-%dT%H:%M:%S%z')"
day_stamp="$(date '+%Y-%m-%d')"
time_stamp="$(date '+%H%M%S')"
year_stamp="$(date '+%Y')"

projects_dir="${vault_root}/${root_prefix}/Projects"
daily_dir="${vault_root}/${root_prefix}/Daily"
sessions_dir="${vault_root}/${root_prefix}/Sessions/${project_slug}/${year_stamp}"

mkdir -p "$projects_dir" "$daily_dir" "$sessions_dir"

session_stem="${day_stamp}_${time_stamp}_${trigger}"
if [[ -n "$session_id" ]]; then
  clean_session_id="$(
    printf '%s' "$session_id" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
  )"
  session_stem="${session_stem}__${clean_session_id}"
fi

session_note="${sessions_dir}/${session_stem}.md"
project_note="${projects_dir}/${project_slug}.md"
daily_note="${daily_dir}/${day_stamp}.md"

python3 - "$summary_file" "$session_note" "$project_note" "$daily_note" "$project_slug" "$repo_root" "$trigger" "$ts" "$root_prefix" "$session_id" <<'PY'
from __future__ import annotations

from pathlib import Path
import sys

summary_path = Path(sys.argv[1])
session_path = Path(sys.argv[2])
project_path = Path(sys.argv[3])
daily_path = Path(sys.argv[4])
project_slug = sys.argv[5]
repo_root = sys.argv[6]
trigger = sys.argv[7]
generated_at = sys.argv[8]
root_prefix = sys.argv[9].strip("/")
session_id = sys.argv[10] or "N/A"

summary_text = summary_path.read_text(encoding="utf-8").strip()

sections: dict[str, list[str]] = {}
current: str | None = None
for line in summary_text.splitlines():
    if line.startswith("## "):
        current = line[3:].strip()
        sections[current] = []
    elif current is not None:
        sections[current].append(line)

def section_body(name: str) -> str:
    body = "\n".join(sections.get(name, [])).strip()
    return body or "- None"

discussion = section_body("Discussion Summary")
decisions = section_body("Key Decisions")
risks = section_body("Open Issues / Risks")
next_actions = section_body("Next Actions")

session_stem = session_path.stem
session_rel = f"{root_prefix}/Sessions/{project_slug}/{session_path.parent.name}/{session_stem}"
project_rel = f"{root_prefix}/Projects/{project_slug}"
session_link = f"[[{session_rel}|{session_stem}]]"
project_link = f"[[{project_rel}|{project_slug}]]"

frontmatter = "\n".join(
    [
        "---",
        f"project: {project_slug}",
        f"repo_root: {repo_root}",
        f"trigger: {trigger}",
        f"generated_at: {generated_at}",
        f"session_id: {session_id}",
        "tags:",
        "  - agent-memory",
        f"  - {project_slug}",
        f"  - {trigger}",
        "---",
        "",
    ]
)

session_body = "\n".join(
    [
        frontmatter.rstrip(),
        f"# {project_slug} {trigger}",
        "",
        f"- Project: {project_link}",
        f"- Generated At: `{generated_at}`",
        f"- Trigger: `{trigger}`",
        f"- Repo Root: `{repo_root}`",
        "",
        summary_text,
        "",
    ]
)
session_path.write_text(session_body, encoding="utf-8")

if project_path.exists():
    existing = project_path.read_text(encoding="utf-8")
else:
    existing = "\n".join(
        [
            "---",
            f"project: {project_slug}",
            f"repo_root: {repo_root}",
            "tags:",
            "  - agent-memory",
            f"  - {project_slug}",
            "---",
            "",
            f"# {project_slug}",
            "",
        ]
    )

project_frontmatter, _, project_rest = existing.partition("---\n")
if existing.startswith("---\n"):
    _, _, remainder = existing.partition("---\n")
    _, _, project_rest = remainder.partition("---\n")
else:
    project_rest = existing

project_sections: dict[str, str] = {}
current = None
for line in project_rest.splitlines():
    if line.startswith("## "):
        current = line[3:].strip()
        project_sections[current] = ""
    elif current is None:
        project_sections.setdefault("_preamble", "")
        project_sections["_preamble"] += line + "\n"
    else:
        project_sections[current] += line + "\n"

latest_existing = [
    line for line in project_sections.get("Latest Sessions", "").splitlines() if line.strip().startswith("- ")
]
new_latest = [f"- {session_link}"] + [line for line in latest_existing if session_link not in line]
new_latest = new_latest[:10] or ["- None"]

new_project = "\n".join(
    [
        "---",
        f"project: {project_slug}",
        f"repo_root: {repo_root}",
        "tags:",
        "  - agent-memory",
        f"  - {project_slug}",
        "---",
        "",
        f"# {project_slug}",
        "",
        "## Current State",
        discussion,
        "",
        "## Recent Decisions",
        decisions,
        "",
        "## Open Risks",
        risks,
        "",
        "## Next Actions",
        next_actions,
        "",
        "## Latest Sessions",
        "\n".join(new_latest),
        "",
    ]
)
project_path.write_text(new_project, encoding="utf-8")

daily_header = f"# Daily Agent Memory - {daily_path.stem}\n\n"
daily_entry = "\n".join(
    [
        f"## {trigger} / {project_slug} / {session_path.stem}",
        f"- Project: {project_link}",
        f"- Session: {session_link}",
        "",
    ]
)
if daily_path.exists():
    daily_text = daily_path.read_text(encoding="utf-8")
else:
    daily_text = daily_header

if session_link not in daily_text:
    daily_text = daily_text.rstrip() + "\n\n" + daily_entry
    daily_path.write_text(daily_text.rstrip() + "\n", encoding="utf-8")
PY

printf 'SESSION_NOTE=%s\n' "$session_note"
printf 'PROJECT_NOTE=%s\n' "$project_note"
printf 'DAILY_NOTE=%s\n' "$daily_note"
