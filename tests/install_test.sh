#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

assert_not_contains() {
  local path="$1"
  local needle="$2"
  if grep -Fq "$needle" "$path"; then
    fail "did not expect $path to contain: $needle"
  fi
}

assert_line_count() {
  local expected="$1"
  local needle="$2"
  local path="$3"
  local actual
  actual="$(grep -Fc "$needle" "$path" || true)"
  [[ "$actual" == "$expected" ]] || fail "expected $expected matches for '$needle' in $path, got $actual"
}

run_install() {
  local target="$1"
  "$repo_root/scripts/install.sh" \
    --target "$target" \
    --skills-dir "$tmpdir/$target/skills" \
    --agents-file "$tmpdir/$target/AGENTS.md" \
    --config-file "$tmpdir/shared/obsidian-memory.json" \
    >"$tmpdir/$target.out"
}

mkdir -p "$tmpdir/codex"
cat >"$tmpdir/codex/AGENTS.md" <<'EOF'
# Existing AGENTS

## Custom Rules
- Keep me.
EOF

mkdir -p "$tmpdir/shared"
cat >"$tmpdir/shared/obsidian-memory.json" <<'EOF'
{
  "enabled": true,
  "vault_root": "/tmp/existing-vault",
  "root_prefix": "Agents"
}
EOF

run_install codex

assert_file_exists "$tmpdir/codex/skills/session-checkpoint/SKILL.md"
assert_file_exists "$tmpdir/codex/skills/obsidian-memory-sink/SKILL.md"
assert_file_exists "$tmpdir/codex/skills/done-global/SKILL.md"
assert_contains "$tmpdir/codex/AGENTS.md" "## Custom Rules"
assert_contains "$tmpdir/codex/AGENTS.md" "## Session Memory"
assert_contains "$tmpdir/codex/AGENTS.md" '$session-checkpoint'
assert_contains "$tmpdir/codex/AGENTS.md" "BEGIN agent-obsidian-memory managed block"
assert_file_exists "$tmpdir/codex/AGENTS.md.bak"
assert_contains "$tmpdir/shared/obsidian-memory.json" "/tmp/existing-vault"

run_install codex
assert_line_count 1 "BEGIN agent-obsidian-memory managed block" "$tmpdir/codex/AGENTS.md"

mkdir -p "$tmpdir/claude"
run_install claude
assert_file_exists "$tmpdir/claude/skills/session-checkpoint/SKILL.md"
assert_file_exists "$tmpdir/shared/obsidian-memory.json"
assert_contains "$tmpdir/claude/AGENTS.md" "## Session Memory"
assert_contains "$tmpdir/claude.out" "CONFIG_ACTION="

rm -f "$tmpdir/shared/obsidian-memory.json"
mkdir -p "$tmpdir/fresh"
"$repo_root/scripts/install.sh" \
  --target codex \
  --skills-dir "$tmpdir/fresh/skills" \
  --agents-file "$tmpdir/fresh/AGENTS.md" \
  --config-file "$tmpdir/shared/obsidian-memory.json" \
  >"$tmpdir/fresh.out"

assert_file_exists "$tmpdir/shared/obsidian-memory.json"
assert_contains "$tmpdir/shared/obsidian-memory.json" '"vault_root": "/Users/your-user/Library/Mobile Documents/iCloud~md~obsidian/Documents/YourVault"'
assert_contains "$tmpdir/fresh.out" "CONFIG_ACTION=created"
assert_not_contains "$tmpdir/fresh.out" "NEXT_STEP=Copy examples/obsidian-memory.json.example"

echo "PASS"
