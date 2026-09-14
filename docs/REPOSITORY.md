# Repository maintenance

The public repository starts with a clean release snapshot. Personal development notes, local settings, and the private pre-release commit history are not part of it. The repository owner’s public GitHub handle is intentionally visible in project URLs and CODEOWNERS.

## Protection policy

- Main requires a pull request, passing **Test and build**, an up-to-date branch, resolved conversations, and linear history. Force pushes and deletion are blocked.
- Public changes require a code-owner review. The sole maintainer may use a recorded pull-request bypass for their own changes when no second reviewer is available. This is an explicit exception, not an independent review.
- Release tags cannot be changed or deleted. Only repository administrators can create release tags.
- Workflow tokens default to read-only. Publishing has write permission in a separate job after build/test success. External-contributor workflows require approval; untrusted code does not receive secrets.
- Actions are pinned to full commit hashes, and Dependabot proposes updates. Secret scanning, push protection, and private vulnerability reporting should remain enabled.
- Squash merge is the supported merge strategy; merged branches are automatically deleted. GitHub-generated squash commits can include contributor metadata, so review the final message and author before merging.

See GitHub repository settings for the actual enforced rules. Do not disable checks to make a failing change mergeable. If a CI job is renamed, update the required check before merging that rename.

## Release procedure

1. Use a pull request to update `RelayVersion.current`, both version fields in `Resources/Info.plist`, and `docs/releases/vVERSION.md`.
2. Test the relevant manual flows and review the public diff and screenshots for private data.
3. Merge only after CI passes. Create the corresponding `vVERSION` tag on that reviewed main commit.
4. The release workflow tests, builds an Apple Silicon app, verifies architecture/signature, and publishes the DMG, ZIP, and checksums.
5. Download the published artifact, verify its checksum, and test installation before recommending it broadly.

Signing with an Apple Developer ID and notarizing require a valid Apple developer identity. Keep signing credentials in encrypted repository environments or secrets, never in source. Require approval for access if signing credentials are added later.
