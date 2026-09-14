# Testing and compatibility

## Automated checks

```sh
swift run RelayTests
./Scripts/build.sh
python3 Scripts/check-public-content.py
./Scripts/package-release.sh
```

The executable regression harness checks routing precedence, exact/subdomain boundaries, URL validation and cleanup, suspicious-link heuristics, Chrome profile parsing, settings compatibility and recovery, temporary defaults, queue ordering, retries, and stale completions. These are expectations in a custom runner, not XCTest cases. CI runs tests and builds the app for pull requests. Release automation also builds for Apple Silicon, checks the architecture and ad-hoc signature, then packages checksummed downloads.

The public-content checker detects common credential formats, private-key headers, personal email providers, local home paths, and forbidden local artifacts in tracked files. It is a preventive check, not proof that arbitrary sensitive information is absent. Review every diff and screenshot.

## Manual release checklist

Use synthetic links and a disposable browser profile. Record the app version, macOS version, architecture, browsers, and what was actually tested.

- Fresh install: launch, find Settings, register HTTP/HTTPS, and test the picker.
- Normal links: click and keyboard selection, Escape, Copy Link, original/cleaned toggle.
- Multiple links: successful open leaves the next picker; Skip skips one; Escape dismisses the group.
- Routing: exact domain, subdomain, source app, first-match order, remember choice, temporary default, Pause, held override.
- Failure recovery: removed browser, missing profile, failed launch, canceled prompt, save failure.
- Chrome: ordinary, Incognito, and named profile launches with Chrome both running and stopped.
- Permissions: Send Tab allowed/denied, clipboard fallback, shortcut conflict, launch at login.
- UI: light/dark, smaller display, external display, keyboard-only navigation, VoiceOver and increased contrast.
- Upgrade/uninstall: settings retained, newer schema protected, default browser restored before removal.

## Evidence and limits

The 1.2.1 baseline passed 145 automated expectations and live Apple Silicon tests for Safari launch, three queued external links, Skip, Escape, keyboard selection, and cleaned destinations. The public 1.3.0 release passes 151 expectations, including six checks preventing Relay copies from being treated as browser destinations, and adds packaging/privacy validation. See the release workflow for reproducible public build results.

Compilation does not prove behavior on every Mac. The oldest supported macOS release, full VoiceOver/Switch Control, multiple monitors, browser crashes, and managed-device restrictions require broader community testing. A successful browser launch means the request was accepted, not that the web page loaded. Do not report these scenarios as passed without testing them.
