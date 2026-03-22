#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  build_release_installer.sh <version> <output-path>

Example:
  ./scripts/build_release_installer.sh v0.2.0 dist/agent-obsidian-memory-installer.sh
USAGE
}

version="${1:-}"
output_path="${2:-}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
template_path="$repo_root/scripts/release_installer_template.sh"

if [[ -z "$version" || -z "$output_path" ]]; then
  usage >&2
  exit 1
fi

mkdir -p "$(dirname "$output_path")"
sed "s|__VERSION__|$version|g" "$template_path" >"$output_path"
chmod +x "$output_path"
