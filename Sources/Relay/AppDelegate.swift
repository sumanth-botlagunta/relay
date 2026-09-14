import AppKit
import Carbon.HIToolbox
import Combine
import RelayCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var sendTabHotKey: HotKey?
    private var settingsObservation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed for bare `swift run` (no Info.plist); harmless in the bundle.
        NSApp.setActivationPolicy(.accessory)

        settingsObservation = AppModel.shared.$settings.map(\.sendTabShortcut).removeDuplicates().sink { [weak self] shortcut in
            self?.registerShortcut(shortcut)
        }

        Task { @MainActor in
            let promptedKey = "relay.promptedDefaultBrowser"
            if !DefaultBrowser.isDefault, !UserDefaults.standard.bool(forKey: promptedKey) {
                UserDefaults.standard.set(true, forKey: promptedKey)
                DefaultBrowser.request()
            }
        }
    }

    @MainActor
    private func registerShortcut(_ shortcut: SendTabShortcut) {
        sendTabHotKey = nil
        AppModel.shared.shortcutError = nil
        let code: Int
        switch shortcut {
        case .controlOptionB: code = kVK_ANSI_B
        case .controlOptionL: code = kVK_ANSI_L
        case .controlOptionR: code = kVK_ANSI_R
        case .disabled: return
        }
        sendTabHotKey = HotKey(keyCode: UInt32(code), carbonModifiers: UInt32(controlKey | optionKey)) {
            Task { @MainActor in SendTab.trigger() }
        }
        if sendTabHotKey == nil {
            AppModel.shared.shortcutError = "\(shortcut.label) is unavailable, possibly because another app uses it. Choose a different shortcut."
        }
    }

    // LSUIElement app has no Dock icon, so double-clicking Relay.app in Finder
    // otherwise does nothing visible. Open Settings on reopen with no windows.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            SettingsWindow.show()
        }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Must read the Apple Event synchronously, before any await.
        let source = Self.appleEventSourceBundleID()
            ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        // Capture modifiers at delivery, before the asynchronous task runs.
        let modifier = AppModel.shared.settings.pickerModifier
        let flags = NSEvent.modifierFlags
        let forcePicker = (modifier == .option && flags.contains(.option)) || (modifier == .shift && flags.contains(.shift))
        Task { @MainActor in
            for url in urls {
                LinkHandler.handle(rawURL: url, sourceAppID: source, forcePicker: forcePicker)
            }
        }
    }

    static func appleEventSourceBundleID() -> String? {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              let addr = event.attributeDescriptor(forKeyword: AEKeyword(keyAddressAttr)),
              let pidDesc = addr.coerce(toDescriptorType: typeKernelProcessID),
              pidDesc.data.count == MemoryLayout<pid_t>.size
        else { return nil }
        let pid = pidDesc.data.withUnsafeBytes { $0.load(as: pid_t.self) }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }
}
