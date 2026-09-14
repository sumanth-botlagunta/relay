import AppKit
import RelayCore

/// "Send current tab to another browser" — shared pipeline behind the ⌃⌥B
/// hotkey and the menu-bar item. Grabs the frontmost browser's active tab via
/// Apple Events (one-time Automation consent per browser); falls back to a web
/// URL on the clipboard. Always shows the picker — the whole point is choosing.
@MainActor
enum SendTab {
    static func trigger() {
        let model = AppModel.shared
        if model.registry.browsers.isEmpty { model.registry.refresh() }

        var url: URL?
        var context: String?
        let frontID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if let frontID {
            url = TabGrabber.currentTabURL(
                browserID: frontID,
                isKnownBrowser: model.registry.browser(withID: frontID) != nil
            )
        }
        if url == nil {
            url = URLExtractor.extractWebURL(from: NSPasteboard.general.string(forType: .string) ?? "")
            context = "Using a clipboard link — the current browser tab was unavailable."
        }
        guard let url else {
            AppFeedback.message("No link available", detail: "Open a web page in a supported browser, or copy a complete web link and try again. If access was denied, review Relay in System Settings → Privacy & Security → Automation.")
            return
        }
        LinkHandler.handle(rawURL: url, sourceAppID: frontID, forcePicker: true, context: context)
    }
}

enum TabGrabber {
    // Known AppleScript dialects for the current-tab URL.
    private static let scripts: [String: String] = [
        "com.apple.Safari": #"tell application id "com.apple.Safari" to return URL of current tab of front window"#,
        "com.google.Chrome": #"tell application id "com.google.Chrome" to return URL of active tab of front window"#,
        "company.thebrowser.Browser": #"tell application id "company.thebrowser.Browser" to return URL of active tab of front window"#,
    ]

    static func currentTabURL(browserID: String, isKnownBrowser: Bool) -> URL? {
        // The frontmost app's bundle ID is interpolated into AppleScript source
        // that Relay executes with its Automation permissions. Reject anything
        // outside a safe charset so a hostile ID can't inject script.
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-_")
        guard !browserID.isEmpty,
              browserID.unicodeScalars.allSatisfy({ allowed.contains($0) })
        else { return nil }

        let candidates: [String]
        if let known = scripts[browserID] {
            candidates = [known]
        } else if isKnownBrowser {
            // Unknown browser: try both common dialects (Chromium then WebKit).
            candidates = [
                #"tell application id "\#(browserID)" to return URL of active tab of front window"#,
                #"tell application id "\#(browserID)" to return URL of current tab of front window"#,
            ]
        } else {
            return nil
        }

        for source in candidates {
            var error: NSDictionary?
            guard let script = NSAppleScript(source: "with timeout of 3 seconds\n" + source + "\nend timeout") else { continue }
            let result = script.executeAndReturnError(&error)
            if error == nil, let value = result.stringValue,
               let url = URLExtractor.extractWebURL(from: value) {
                return url
            }
        }
        return nil
    }
}
