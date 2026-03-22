#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install.sh --target <codex|claude> [--skills-dir <path>] [--agents-file <path>]

Options:
  --target <codex|claude>     Install skills for Codex or Claude.
  --skills-dir <path>         Override target skills directory.
  --agents-file <path>        Override target AGENTS.md path.
  -h, --help                  Show this help.
USAGE
}

target=""
skills_dir=""
agents_file=""
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
      shift 2
      ;;
    --skills-dir)
      skills_dir="${2:-}"
      shift 2
      ;;
    --agents-file)
      agents_file="${2:-}"
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

case "$target" in
  codex)
    : "${skills_dir:=${HOME}/.codex/skills}"
    : "${agents_file:=${HOME}/.codex/AGENTS.md}"
    template="$repo_root/templates/AGENTS.codex.md"
    ;;
  claude)
    : "${skills_dir:=${HOME}/.claude/skills}"
    : "${agents_file:=${HOME}/.claude/AGENTS.md}"
    template="$repo_root/templates/AGENTS.claude.md"
    ;;
  *)
    echo "Missing or invalid --target. Use codex or claude." >&2
    exit 1
    ;;
esac

mkdir -p "$skills_dir"
for skill in session-checkpoint obsidian-memory-sink done-global; do
  rm -rf "$skills_dir/$skill"
  cp -R "$repo_root/skills/$skill" "$skills_dir/"
done

cp "$template" "$agents_file"

echo "INSTALLED_SKILLS_DIR=$skills_dir"
echo "INSTALLED_AGENTS_FILE=$agents_file"
echo "NEXT_STEP=Copy examples/obsidian-memory.json.example into your runtime config location and set your vault path."
