# Releasing

This repository currently uses a manual GitHub Releases flow.

## Versioning

- Release tags use the format `vX.Y.Z`.
- Releases are cut from `main`.
- Use patch releases for small fixes and documentation cleanups.
- Use minor releases when installation flow or user-facing project shape changes in meaningful ways.

## Release Style

- Releases are source-only plus one generated bootstrap asset.
- Publish from a clean `main` checkout with `gh` CLI.
- The bootstrap asset filename is always `agent-obsidian-memory-installer.sh`.

## skills.sh Positioning

Treat `sulphyxxx/agent-obsidian-memory` as a repository-level skills pack.

- Lead README installation instructions with `npx skills add sulphyxxx/agent-obsidian-memory`.
- Keep the GitHub release bootstrap installer as an alternative path, not the primary homepage call to action.
- Keep README language focused on the three installed skills: `session-checkpoint`, `obsidian-memory-sink`, and `done-global`.

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
- the target version does not already exist locally or remotely
- `gh` is installed and authenticated

## Generic Release Flow

Push the release base to GitHub before tagging:

```bash
git push origin main
```

Create the annotated tag:

```bash
git tag -a <version> -m "<version>"
git push origin <version>
```

Create release notes in a temporary file.

Build the release installer asset:

```bash
./scripts/build_release_installer.sh <version> dist/agent-obsidian-memory-installer.sh
```

Then publish:

```bash
gh release create <version> \
  --title "<version>" \
  --notes-file /tmp/<repo>-<version>.md \
  dist/agent-obsidian-memory-installer.sh#agent-obsidian-memory-installer.sh
```

## v0.2.0 Example

`v0.2.0` is the release where the project becomes materially easier to install and understand. It includes the installer and homepage README improvements now on `main`.

Example notes file:

```bash
cat > /tmp/agent-obsidian-memory-v0.2.0.md <<'EOF'
## Summary
- Adds a root `./install.sh` entrypoint
- Makes installer reruns safer by preserving config and updating AGENTS via a managed block
- Rewrites the README into a clearer project homepage
- Adds a latest-release bootstrap installer for macOS-first `curl | bash` installs

## Notes
- Source-only release from main
- Covers the installer and homepage README upgrade line after v0.1.0
EOF
```

Publish:

```bash
./scripts/build_release_installer.sh v0.2.0 dist/agent-obsidian-memory-installer.sh
git tag -a v0.2.0 -m "v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 \
  --title "v0.2.0" \
  --notes-file /tmp/agent-obsidian-memory-v0.2.0.md \
  dist/agent-obsidian-memory-installer.sh#agent-obsidian-memory-installer.sh
```

## Post-Release Verification

After publishing:

```bash
git ls-remote --tags origin
gh release view <version>
```

Confirm the release is visible on GitHub and only uses GitHub's default source archives.

Then verify the public install path and listing behavior:

- Run `npx skills add sulphyxxx/agent-obsidian-memory` from a clean environment.
- Confirm the target agent environment can discover the installed skills.
- Check `skills.sh` after installs propagate and confirm the repo appears with reasonable metadata.
