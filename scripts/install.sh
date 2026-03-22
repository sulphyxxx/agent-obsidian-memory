#!/usr/bin/env bash
set -euo pipefail

managed_begin="<!-- BEGIN agent-obsidian-memory managed block -->"
managed_end="<!-- END agent-obsidian-memory managed block -->"

usage() {
  cat <<'USAGE'
Usage:
  install.sh --target <codex|claude> [--skills-dir <path>] [--agents-file <path>] [--config-file <path>]

Options:
  --target <codex|claude>     Install skills for Codex or Claude.
  --skills-dir <path>         Override target skills directory.
  --agents-file <path>        Override target AGENTS.md path.
  --config-file <path>        Override Obsidian memory config path.
  -h, --help                  Show this help.
USAGE
}

target=""
skills_dir=""
agents_file=""
config_file=""
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

backup_file() {
  local path="$1"
  local backup_path="${path}.bak"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  if [[ -e "$backup_path" ]]; then
    backup_path="${path}.bak.$(date +%Y%m%d%H%M%S)"
  fi

  cp "$path" "$backup_path"
  echo "$backup_path"
}

render_managed_block() {
  local snippet="$1"
  {
    echo "$managed_begin"
    cat "$snippet"
    echo "$managed_end"
  }
}

merge_agents_file() {
  local agents_path="$1"
  local full_template="$2"
  local snippet_template="$3"
  local backup_path=""
  local temp_file
  temp_file="$(mktemp)"

  if [[ -f "$agents_path" ]]; then
    backup_path="$(backup_file "$agents_path")"
    if grep -Fq "$managed_begin" "$agents_path"; then
      awk -v begin="$managed_begin" -v end="$managed_end" '
        BEGIN { skipping = 0 }
        index($0, begin) { skipping = 1; next }
        index($0, end) { skipping = 0; next }
        !skipping { print }
      ' "$agents_path" >"$temp_file"
      sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$temp_file"
      if [[ -s "$temp_file" ]]; then
        printf '\n\n' >>"$temp_file"
      fi
      render_managed_block "$snippet_template" >>"$temp_file"
      mv "$temp_file" "$agents_path"
      echo "AGENTS_ACTION=merged"
    else
      cp "$agents_path" "$temp_file"
      if [[ -s "$temp_file" ]]; then
        printf '\n\n' >>"$temp_file"
      fi
      render_managed_block "$snippet_template" >>"$temp_file"
      mv "$temp_file" "$agents_path"
      echo "AGENTS_ACTION=merged"
    fi
  else
    cp "$full_template" "$agents_path"
    echo "AGENTS_ACTION=created"
  fi

  if [[ -n "$backup_path" ]]; then
    echo "AGENTS_BACKUP_FILE=$backup_path"
  fi
}

ensure_config_file() {
  local config_path="$1"
  local example_path="$2"

  if [[ -f "$config_path" ]]; then
    echo "CONFIG_ACTION=preserved"
    return 0
  fi

  mkdir -p "$(dirname "$config_path")"
  cp "$example_path" "$config_path"
  echo "CONFIG_ACTION=created"
}

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

case "$target" in
  codex)
    : "${skills_dir:=${HOME}/.codex/skills}"
    : "${agents_file:=${HOME}/.codex/AGENTS.md}"
    full_template="$repo_root/templates/AGENTS.codex.md"
    snippet_template="$repo_root/templates/AGENTS.codex.snippet.md"
    ;;
  claude)
    : "${skills_dir:=${HOME}/.claude/skills}"
    : "${agents_file:=${HOME}/.claude/AGENTS.md}"
    full_template="$repo_root/templates/AGENTS.claude.md"
    snippet_template="$repo_root/templates/AGENTS.claude.snippet.md"
    ;;
  *)
    echo "Missing or invalid --target. Use codex or claude." >&2
    exit 1
    ;;
esac

: "${config_file:=${HOME}/.codex/memories/obsidian-memory.json}"

mkdir -p "$skills_dir"
for skill in session-checkpoint obsidian-memory-sink done-global; do
  rm -rf "$skills_dir/$skill"
  cp -R "$repo_root/skills/$skill" "$skills_dir/"
done

mkdir -p "$(dirname "$agents_file")"
merge_agents_file "$agents_file" "$full_template" "$snippet_template"
ensure_config_file "$config_file" "$repo_root/examples/obsidian-memory.json.example"

echo "INSTALLED_SKILLS_DIR=$skills_dir"
echo "INSTALLED_AGENTS_FILE=$agents_file"
echo "INSTALLED_CONFIG_FILE=$config_file"
echo "NEXT_STEP=Edit $config_file and set vault_root."
