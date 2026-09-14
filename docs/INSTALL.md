# Install, update, and remove Relay

## Requirements

- macOS 15 Sequoia or newer.
- Apple Silicon Mac. Releases contain `arm64` code. Intel Macs are not supported.
- At least one installed browser. Safari is the usual fallback.

Relay is an early public release. It is not an App Store app, has no automatic updater, and the downloadable testing builds are not Apple-notarized. No Windows or Linux build is available.

## Download and install

1. Visit the [latest release](https://github.com/sumanth-botlagunta/relay/releases/latest).
2. Download the Apple Silicon DMG, open it, and drag Relay onto Applications. Alternatively, unzip the Apple Silicon ZIP and move Relay.app into Applications.
3. Eject the disk image. Open Relay from Applications.
4. Use **Settings → General → Make Default**, and approve the macOS request. This registers Relay for HTTP and HTTPS links. Reopening Relay from Applications shows Settings.
5. Use **Setup & Help → Test Picker** to test with an example link.

The app lives in the menu bar with a branching-arrow icon and has no Dock icon. Links clicked inside a browser may stay in that browser; Relay handles URLs that other apps send to the system default browser.

## When macOS blocks the first launch

Current releases are ad-hoc signed, not signed with an Apple Developer ID or notarized. After trying to open a trusted download, go to **System Settings → Privacy & Security** and use **Open Anyway**, if macOS offers it. Read and approve the prompt only if you trust the source. See [Apple’s current instructions](https://support.apple.com/guide/mac-help/mh40616/mac).

Do not disable Gatekeeper, remove quarantine recursively, or weaken your Mac’s security settings. A managed Mac may disallow unnotarized software. In that case, ask your administrator or build from source if permitted.

## Verify a download

Download `SHA256SUMS.txt` alongside the DMG and ZIP. From their folder:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

Both files must be present for both checks to pass. If you downloaded only one format, compare its `shasum -a 256` output with its entry in the checksum file. This detects corruption; it does not replace publisher signing.

## Update

Quit Relay from its menu before replacing `/Applications/Relay.app` with the new download. Open the new app. Your JSON preferences remain in place. Check the version under **Setup & Help**. Keep a copy of the previous app as a ZIP if you need to roll back; avoid leaving multiple unzipped Relay apps installed.

**Upgrading from a private build to 1.3.0:** the public app uses a neutral bundle identifier. Select **Make Default** again and check **Launch at login**. macOS may ask for Automation permission again when Send Tab is used. The preferences directory has not changed. Do not run both builds together.

## Common issues

| Problem | What to try |
| --- | --- |
| Nothing visible after opening | Find the branching-arrow menu icon, or reopen Relay from Applications for Settings. |
| Links skip Relay | Check both HTTP and HTTPS in Setup & Help, then Make Default. Source apps may open a specific browser themselves. |
| Links skip the picker | Check rules, Pause, and temporary defaults. Hold the configured modifier while clicking to override them. |
| Browser or profile missing | Open Browsers settings and Refresh Browsers & Profiles. Confirm the browser is installed and the entry is visible. |
| Send Tab cannot read the browser | Allow Relay under Privacy & Security → Automation. Browser scripting support varies. Use a copied link if needed. |
| A shortcut does nothing | Choose another Send Tab shortcut in General, or turn it off. Another app may own the shortcut. |
| Login launch does not work | Check System Settings → General → Login Items & Extensions. |
| Preferences cannot be saved | Read the error in Settings. Preserve the recovery file; do not share its private contents publicly. |

## Uninstall

1. Choose another default browser in macOS System Settings.
2. Turn off **Launch at login** in Relay and quit it.
3. Move `/Applications/Relay.app` to the Trash.
4. Optionally remove `~/Library/Application Support/Relay/` to delete saved preferences and recovery files. This loses your rules; keep a private backup if needed.

## Build locally

With a Swift 6 toolchain installed:

```sh
git clone https://github.com/sumanth-botlagunta/relay.git
cd relay
swift run RelayTests
./Scripts/build.sh
./Scripts/build.sh install-built
```

Quit an existing Relay before installing. The installer preserves the previous app in a ZIP under `dist/` and keeps settings intact. Building requires macOS; a Swift 6 toolchain is required.
