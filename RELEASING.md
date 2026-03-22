# Releasing

This repository uses a manual GitHub Releases flow.

## Versioning

- Release tags use the format `vX.Y.Z`.
- The first published release is `v0.1.0`.
- Releases are cut from `main`.

## Release Scope

- `v0.1.0` is a source-only release.
- Do not upload custom binaries or zip artifacts.
- `installer` branch changes are not part of `v0.1.0`.

## Preflight Checks

Run these commands from a clean checkout on `main`:

```bash
git status --short --branch
git tag --list
git ls-remote --tags origin
gh --version
gh auth status
```

Confirm:

- `main` is the current branch
- there are no unexpected working tree changes
- `v0.1.0` does not already exist locally or remotely
- `gh` is installed and authenticated

## Publish v0.1.0

Push the release base to GitHub before tagging:

```bash
git push origin main
```

Create the annotated tag:

```bash
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
```

Create release notes in a temporary file:

```bash
cat > /tmp/agent-obsidian-memory-v0.1.0.md <<'EOF'
## Summary
- Initial release of agent-obsidian-memory
- Includes session-checkpoint, obsidian-memory-sink, and done-global
- Source-only release from main

## Notes
- Installer branch improvements are not included in v0.1.0
EOF
```

Publish the GitHub Release:

```bash
gh release create v0.1.0 \
  --title "v0.1.0" \
  --notes-file /tmp/agent-obsidian-memory-v0.1.0.md
```

## Verification

After publishing:

```bash
git ls-remote --tags origin
gh release view v0.1.0
```

Confirm the release is visible on GitHub and only uses GitHub's default source archives.
