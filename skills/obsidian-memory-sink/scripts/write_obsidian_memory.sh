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
  --config-file <path>        Config file path (default: $HOME/.agent-memory/obsidian-memory.json).
  -h, --help                  Show this help.
USAGE
}

default_config_file() {
  printf '%s\n' "${HOME}/.agent-memory/obsidian-memory.json"
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
sessions_root="${vault_root}/${root_prefix}/Sessions"

python3 - "$summary_file" "$session_note" "$project_note" "$daily_note" "$project_slug" "$repo_root" "$trigger" "$ts" "$root_prefix" "$session_id" "$sessions_root" <<'PY'
from __future__ import annotations

from pathlib import Path
import re
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
sessions_root = Path(sys.argv[11])

summary_text = summary_path.read_text(encoding="utf-8").strip()

SECTION_ORDER = [
    "Discussion Summary",
    "Key Decisions",
    "Completed Work",
    "Open Issues / Risks",
    "Next Actions",
]

def parse_summary_sections(text: str) -> dict[str, str]:
    parsed: dict[str, list[str]] = {}
    current_name: str | None = None
    for raw_line in text.splitlines():
        if raw_line.startswith("## "):
            current_name = raw_line[3:].strip()
            parsed[current_name] = []
        elif current_name is not None:
            parsed[current_name].append(raw_line)
    return {name: "\n".join(lines).strip() for name, lines in parsed.items()}


def section_body(sections: dict[str, str], name: str) -> str:
    body = sections.get(name, "").strip()
    return body or "- None"


def section_has_content(body: str) -> bool:
    normalized = body.strip()
    if not normalized:
        return False
    return normalized not in {"- None", "- None."}


def render_daily_entry(record: dict[str, str], session_link: str, project_link: str) -> str:
    time_label = record.get("time_label", "").strip()
    lines = [
        f"## {time_label} {record['trigger']} · {project_link}".rstrip(),
        f"- Note: {session_link}",
    ]
    lines.append("")
    for name in SECTION_ORDER:
        body = record["sections"].get(name, "").strip()
        if section_has_content(body):
            lines.extend([f"### {name}", body, ""])
    return "\n".join(lines).rstrip() + "\n"


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        return {}, text
    _, _, remainder = text.partition("---\n")
    frontmatter_text, marker, body = remainder.partition("---\n")
    if not marker:
        return {}, text
    frontmatter: dict[str, str] = {}
    for line in frontmatter_text.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        frontmatter[key.strip()] = value.strip()
    return frontmatter, body


def collect_daily_records() -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    pattern = f"*/{daily_path.stem[:4]}/{daily_path.stem}_*.md"
    for candidate in sorted(sessions_root.glob(pattern)):
        text = candidate.read_text(encoding="utf-8")
        frontmatter, body = parse_frontmatter(text)
        summary_start = body.find("## ")
        summary_only = body[summary_start:].strip() if summary_start != -1 else ""
        sections = parse_summary_sections(summary_only)
        stem_match = re.match(r"(?P<day>\d{4}-\d{2}-\d{2})_(?P<time>\d{6})_(?P<trigger>[a-z]+)", candidate.stem)
        if not stem_match:
            continue
        candidate_project = frontmatter.get("project", candidate.parent.parent.name)
        records.append(
            {
                "project_slug": candidate_project,
                "trigger": frontmatter.get("trigger", stem_match.group("trigger")),
                "generated_at": frontmatter.get("generated_at", ""),
                "time_label": f"{stem_match.group('time')[:2]}:{stem_match.group('time')[2:4]}",
                "session_stem": candidate.stem,
                "session_year": candidate.parent.name,
                "sections": sections,
                "sort_key": (
                    stem_match.group("day"),
                    stem_match.group("time"),
                    candidate_project,
                    candidate.stem,
                ),
            }
        )
    records.sort(key=lambda item: item["sort_key"])
    return records


summary_sections = parse_summary_sections(summary_text)
discussion = section_body(summary_sections, "Discussion Summary")
decisions = section_body(summary_sections, "Key Decisions")
risks = section_body(summary_sections, "Open Issues / Risks")
next_actions = section_body(summary_sections, "Next Actions")

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

daily_records = collect_daily_records()
project_links = sorted(
    {
        f"[[{root_prefix}/Projects/{record['project_slug']}|{record['project_slug']}]]"
        for record in daily_records
    }
)
open_items_remaining = sum(
    1
    for record in daily_records
    if section_has_content(record["sections"].get("Open Issues / Risks", ""))
    or section_has_content(record["sections"].get("Next Actions", ""))
)
daily_lines = [
    f"# Daily Agent Memory - {daily_path.stem}",
    "",
    "## Today at a glance",
    f"- Checkpoints: `{len(daily_records)}`",
    f"- Projects: {', '.join(project_links) if project_links else '- None'}",
    f"- Follow-ups: `{open_items_remaining}`",
]
for record in daily_records:
    record_project_rel = f"{root_prefix}/Projects/{record['project_slug']}"
    record_session_rel = (
        f"{root_prefix}/Sessions/{record['project_slug']}/{record['session_year']}/{record['session_stem']}"
    )
    daily_lines.extend(
        [
            "",
            render_daily_entry(
                record,
                f"[[{record_session_rel}|{record['session_stem']}]]",
                f"[[{record_project_rel}|{record['project_slug']}]]",
            ).rstrip(),
        ]
    )

daily_path.write_text("\n".join(daily_lines).rstrip() + "\n", encoding="utf-8")
PY

printf 'SESSION_NOTE=%s\n' "$session_note"
printf 'PROJECT_NOTE=%s\n' "$project_note"
printf 'DAILY_NOTE=%s\n' "$daily_note"
