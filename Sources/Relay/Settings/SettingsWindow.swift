import AppKit
import SwiftUI

@MainActor
enum SettingsWindow {
    private static var window: NSWindow?
    static func show() {
        if window == nil {
            let created = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 570),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            created.title = "Relay Settings"
            created.identifier = NSUserInterfaceItemIdentifier("RelaySettings")
            created.contentMinSize = NSSize(width: 640, height: 520)
            created.isReleasedWhenClosed = false
            created.contentView = NSHostingView(rootView: SettingsView(model: .shared))
            created.center()
            window = created
        }
        AppModel.shared.registry.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
