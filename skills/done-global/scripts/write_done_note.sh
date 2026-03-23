#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  write_done_note.sh --summary-file <file> [options]

Required:
  --summary-file <file>       Markdown content file for this session note.

Options:
  --project-root <path>       Project path (default: current working directory).
  --session-id <id>           Optional session identifier for filename preference.
  --global-root <path>        Global output root (default: $HOME/.agent-memory/session-notes).
  --trigger <text>            Trigger label (default: /done).
  --no-project-summary        Skip in-project SESSION_SUMMARY.md update.
  -h, --help                  Show this help.
USAGE
}

default_global_root() {
  printf '%s\n' "${HOME}/.agent-memory/session-notes"
}

slugify() {
  local input="$1"
  printf '%s' "$input" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

safe_token() {
  local input="$1"
  printf '%s' "$input" \
    | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

project_root="${PWD}"
summary_file=""
session_id=""
global_root="$(default_global_root)"
trigger_label="/done"
update_project_summary="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --summary-file)
      summary_file="${2:-}"
      shift 2
      ;;
    --session-id)
      session_id="${2:-}"
      shift 2
      ;;
    --global-root)
      global_root="${2:-}"
      shift 2
      ;;
    --trigger)
      trigger_label="${2:-}"
      shift 2
      ;;
    --no-project-summary)
      update_project_summary="false"
      shift
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

if [[ -z "$summary_file" ]]; then
  echo "Missing required argument: --summary-file" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$summary_file" ]]; then
  echo "Summary file not found: $summary_file" >&2
  exit 1
fi

if ! project_root="$(cd "$project_root" && pwd)"; then
  echo "Invalid --project-root: $project_root" >&2
  exit 1
fi

repo_root="$project_root"
if git -C "$project_root" rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root="$(git -C "$project_root" rev-parse --show-toplevel)"
fi

repo_name="$(basename "$repo_root" 2>/dev/null || true)"
if [[ -z "$repo_name" ]]; then
  repo_name="unknown-repo"
fi

branch_name="no-branch"
if git -C "$repo_root" rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
  branch_name="$(git -C "$repo_root" rev-parse --abbrev-ref HEAD)"
  if [[ "$branch_name" == "HEAD" ]]; then
    branch_name="detached-head"
  fi
fi

repo_slug="$(slugify "$repo_name")"
branch_slug="$(slugify "$branch_name")"
session_slug="$(safe_token "$session_id")"

if [[ -z "$repo_slug" ]]; then
  repo_slug="unknown-repo"
fi
if [[ -z "$branch_slug" ]]; then
  branch_slug="no-branch"
fi

ts="$(date '+%Y%m%d_%H%M%S')"
stamp_readable="$(date '+%Y-%m-%d %H:%M:%S %z')"

target_dir="${global_root}/${repo_slug}/${branch_slug}"
mkdir -p "$target_dir"

if [[ -n "$session_slug" ]]; then
  base_name="done_${session_slug}__${branch_slug}.md"
else
  base_name="done_${ts}.md"
fi

target_file="${target_dir}/${base_name}"
if [[ -e "$target_file" ]]; then
  base_no_ext="${base_name%.md}"
  seq=1
  while :; do
    candidate="${target_dir}/${base_no_ext}__${ts}_${seq}.md"
    if [[ ! -e "$candidate" ]]; then
      target_file="$candidate"
      break
    fi
    seq=$((seq + 1))
  done
fi

{
  echo "# Session Done Note"
  echo
  echo "- Generated At: \`${stamp_readable}\`"
  echo "- Trigger: \`${trigger_label}\`"
  echo "- Project Root: \`${project_root}\`"
  echo "- Repo: \`${repo_name}\`"
  echo "- Branch: \`${branch_name}\`"
  if [[ -n "$session_slug" ]]; then
    echo "- Session ID: \`${session_slug}\`"
  else
    echo "- Session ID: \`N/A\`"
  fi
  echo
  cat "$summary_file"
} > "$target_file"

project_summary_file="${repo_root}/SESSION_SUMMARY.md"
project_summary_status="skipped_no_file"

if [[ "$update_project_summary" == "true" && -f "$project_summary_file" ]]; then
  entry_tmp="$(mktemp)"
  out_tmp="$(mktemp)"
  entry_time="$(date '+%Y-%m-%d %H:%M:%S')"

  cat > "$entry_tmp" <<EOF
### ${entry_time}
- Global note: \`${target_file}\`
- Repo: \`${repo_name}\`
- Branch: \`${branch_name}\`
- Trigger: \`${trigger_label}\`
EOF

  if awk -v entry_file="$entry_tmp" '
    BEGIN {
      while ((getline line < entry_file) > 0) {
        entry = entry line ORS
      }
      close(entry_file)
      inserted = 0
    }
    {
      print
      if (!inserted && $0 ~ /^## Session Logs[[:space:]]*$/) {
        print ""
        printf "%s", entry
        print ""
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        if (NR > 0) {
          print ""
        }
        print "## Session Logs"
        print ""
        printf "%s", entry
      }
    }
  ' "$project_summary_file" > "$out_tmp"; then
    mv "$out_tmp" "$project_summary_file"
    project_summary_status="updated"
  else
    rm -f "$out_tmp"
    project_summary_status="error"
  fi

  rm -f "$entry_tmp"
fi

printf 'GLOBAL_NOTE=%s\n' "$target_file"
printf 'PROJECT_SUMMARY=%s\n' "$project_summary_file"
printf 'PROJECT_SUMMARY_STATUS=%s\n' "$project_summary_status"
printf 'REPO_ROOT=%s\n' "$repo_root"
printf 'BRANCH=%s\n' "$branch_name"
