#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
readme="$repo_root/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

assert_contains "$readme" "## Quick Start"
assert_contains "$readme" "## Who This Is For"
assert_contains "$readme" "## What It Installs"
assert_contains "$readme" "./install.sh --target codex"
assert_contains "$readme" "./install.sh --target claude"
assert_contains "$readme" "not an Obsidian plugin"
assert_contains "$readme" "RELEASING.md"

echo "PASS"
