#!/usr/bin/env bash
set -euo pipefail

VERSION="__VERSION__"
REPO_SLUG="sulphyxxx/agent-obsidian-memory"
ARCHIVE_URL="https://github.com/sulphyxxx/agent-obsidian-memory/archive/refs/tags/${VERSION}.tar.gz"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage:
  curl -fsSL https://github.com/sulphyxxx/agent-obsidian-memory/releases/latest/download/agent-obsidian-memory-installer.sh | bash -s -- --target <codex|claude> [installer args...]

Notes:
  This installer currently supports macOS first.
  It downloads the tagged source archive for the embedded release version and then runs ./install.sh with your arguments.
USAGE
  exit 0
fi

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "This installer currently supports macOS first." >&2
  echo "Use the repo-local installer on other platforms for now." >&2
  exit 1
fi

for required_cmd in curl tar mktemp bash; do
  command -v "$required_cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $required_cmd" >&2
    exit 1
  }
done

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

archive_path="$tmpdir/release.tar.gz"

curl -fsSL "$ARCHIVE_URL" -o "$archive_path"
mkdir -p "$tmpdir/repo"
tar -xzf "$archive_path" --strip-components=1 -C "$tmpdir/repo"

if [[ ! -x "$tmpdir/repo/install.sh" ]]; then
  chmod +x "$tmpdir/repo/install.sh"
fi

exec "$tmpdir/repo/install.sh" "$@"
