import AppKit
import RelayCore

@MainActor
enum AppFeedback {
    static func message(_ title: String, detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func launchFailed(url: URL, detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "The link could not be opened"
        alert.informativeText = detail + "\nYour link is still available."
        alert.addButton(withTitle: "Choose Another Browser")
        alert.addButton(withTitle: "Copy Link")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            LinkHandler.handle(rawURL: url, sourceAppID: nil, forcePicker: true, context: "Choose another browser to retry.", prioritize: true)
        case .alertSecondButtonReturn: copy(url)
        default: break
        }
    }

    static func copy(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }
}
