# Contributing to Relay

Thanks for helping people open links where they want them. Small, focused fixes and clear bug reports are useful contributions.

## Before you start

For a substantial feature, open an issue describing the workflow and proposed behavior before implementing it. Keep unrelated refactors separate. Never include real browsing URLs, Chrome profile names, local settings, credentials, or personal machine paths in a patch, issue, or screenshot.

## Development

Use macOS 15+, Swift 6, and Xcode or Command Line Tools. There are no external package dependencies.

```sh
swift run RelayTests
swift build --product Relay
./Scripts/build.sh
```

The package deliberately uses Swift 5 language mode with a Swift 6 toolchain. Do not claim Swift 6 strict-concurrency compliance. `RelayTests` is an executable test harness; failed expectations produce a nonzero exit status.

## Code conventions

- Follow Swift API naming conventions, use four-space indentation, and match surrounding code.
- Put deterministic routing, parsing, validation, and persistence logic in `RelayCore`. Keep UI and macOS services in `Relay`.
- Isolate UI state and AppKit operations to the main actor. Handle asynchronous completion exactly once; use request IDs to reject stale callbacks.
- Validate URLs before launch. Pass process arguments as separate array elements; never interpolate a URL into a shell command.
- Keep saved settings backward compatible. Do not overwrite a newer schema or silently discard corrupt data.
- Surface actionable failures. Use native controls, readable labels, keyboard shortcuts, and accessibility descriptions.
- Add focused regression coverage for behavior changes. Check relevant UI flows manually; avoid tests that merely restate an implementation.
- Keep documentation honest about supported browsers, operating systems, permissions, and untested cases.

## Before a pull request

1. Run `swift run RelayTests` and `./Scripts/build.sh`.
2. Run `python3 Scripts/check-public-content.py` after staging your intended files.
3. Review `git diff --check` and the final diff. Stage only intended files.
4. For UI changes, include a screenshot made with synthetic data and note the manual checks performed.
5. Use your GitHub-provided no-reply commit email if you want to keep your email private. Check author and committer metadata before pushing.

Public pull requests run with read-only permissions and no repository secrets. CI must pass before merging. The maintainer reviews public contributions. Do not use privileged `pull_request_target` workflows to run contributor code.

Contributions are provided under the project’s MIT license. Be respectful, discuss ideas rather than people, and avoid harassment or sharing someone else’s private information. Maintainers may remove abusive content and limit participation.
