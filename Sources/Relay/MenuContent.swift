import AppKit
import SwiftUI
import RelayCore

struct MenuContent: View {
    @ObservedObject var model: AppModel

    private static let durations: [(label: String, seconds: TimeInterval?)] = [
        ("For 30 Minutes", 1800),
        ("For 1 Hour", 3600),
        ("For 2 Hours", 7200),
        ("Until I Stop It", nil),
    ]

    var body: some View {
        Text(model.isPaused ? "Relay — Paused" : "Relay — Choose where links open")
        if let tempID = model.tempBrowserID,
           let browser = model.registry.browser(withID: tempID) {
            Text(temporaryLabel(browser))
            Button("Stop Temporary Browser") {
                model.stopTemporary()
            }
            Divider()
        }

        Menu("Primary Browser") {
            ForEach(model.registry.browsers) { browser in
                Toggle(browser.name, isOn: primaryBinding(browser))
            }
        }

        Menu("Use Temporarily") {
            ForEach(model.registry.browsers) { browser in
                Menu(browser.name) {
                    ForEach(Self.durations, id: \.label) { duration in
                        Button(duration.label) {
                            model.startTemporary(browserID: browser.bundleID, duration: duration.seconds)
                        }
                    }
                }
            }
        }

        Toggle("Pause — Everything to Primary", isOn: $model.isPaused)

        Divider()

        Button("Send Current Tab To…") { SendTab.trigger() }
        if model.settings.sendTabShortcut != .disabled {
            Text("Shortcut: \(model.settings.sendTabShortcut.label)")
        }

        Button("Settings…") {
            // Accessory apps don't activate on their own, which would leave
            // the window behind the frontmost app.
            SettingsWindow.show()
        }
        .keyboardShortcut(",")
        Button("Quit Relay") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func temporaryLabel(_ browser: Browser) -> String {
        guard let expiry = model.tempExpiry else {
            return "Using \(browser.name) until you stop it"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Using \(browser.name) until \(formatter.string(from: expiry))"
    }

    private func primaryBinding(_ browser: Browser) -> Binding<Bool> {
        Binding(
            get: { model.settings.primaryBrowserID == browser.bundleID },
            set: { on in if on { model.settings.primaryBrowserID = browser.bundleID } }
        )
    }
}
