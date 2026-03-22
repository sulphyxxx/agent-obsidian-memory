#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
releasing_doc="$repo_root/RELEASING.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

[[ -f "$releasing_doc" ]] || fail "expected RELEASING.md to exist"

assert_contains "$releasing_doc" "v0.1.0"
assert_contains "$releasing_doc" "gh release create"
assert_contains "$releasing_doc" "source-only"
assert_contains "$releasing_doc" "git push origin main"
assert_contains "$releasing_doc" "git push origin v0.1.0"

echo "PASS"
