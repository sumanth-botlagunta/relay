# Privacy

Relay has no analytics, telemetry, account system, advertising, remote configuration, or application-operated server.

## Data used on your Mac

- Incoming URLs and the source app identifier are processed to choose a destination. Queued URLs are held in memory and are not saved as browsing history.
- Settings store browser identifiers, routing patterns, shortcuts, and preferences in `~/Library/Application Support/Relay/settings.json`. Rules may contain domains or source apps you use. Treat this file as private.
- Chrome profile discovery reads Chrome’s local `Local State` file for profile names and directories. Relay does not need Chrome passwords, cookies, or browsing history.
- Send Tab reads a supported browser’s active-tab URL through Apple Events after macOS grants Automation permission. If unavailable, it may read a clipboard link and identifies that fallback in the picker.
- Copy Link writes the selected URL to the clipboard. Other apps with clipboard access may read it.
- macOS manages default-browser registration, login items, and permissions separately from Relay’s settings file.

Relay’s routing, cleaning, and warning logic does not make network requests. Your chosen browser accesses the destination when a link opens. GitHub hosts source, issues, and releases under GitHub’s own policies; README badges are fetched from GitHub and Shields.io.

No diagnostic uploader is included. macOS or your browser may have their own diagnostics. Before sharing a screenshot or a settings file, remove personal links, names, rules, and local paths. Uninstallation steps are in [Install](docs/INSTALL.md).
