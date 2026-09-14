import AppKit
import RelayCore

struct PickerEntry: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let icon: NSImage
    let target: BrowserLauncher.Target

    @MainActor
    static func build(model: AppModel) -> [PickerEntry] {
        let byID = Dictionary(uniqueKeysWithValues: model.registry.browsers.map { ($0.bundleID, $0) })
        let orderedIDs = model.settings.orderedBrowserIDs(installed: model.registry.browsers.map(\.bundleID))
        var entries = orderedIDs.compactMap { id -> PickerEntry? in
            guard !model.settings.hiddenBrowserIDs.contains(id), let browser = byID[id] else { return nil }
            return PickerEntry(id: id, title: browser.name, subtitle: "", badge: nil,
                icon: model.registry.icon(for: browser), target: .browser(id))
        }
        if model.settings.chromeExtras, let chrome = byID[BrowserRegistry.chromeBundleID],
           !model.settings.hiddenBrowserIDs.contains(chrome.bundleID) {
            let icon = model.registry.icon(for: chrome)
            entries.append(PickerEntry(id: "chrome-incognito", title: "Chrome Incognito", subtitle: "Private window",
                badge: "eye.slash.fill", icon: icon, target: .chromeIncognito))
            // Even a single named profile is a useful explicit routing destination.
            for profile in model.registry.chromeProfiles {
                entries.append(PickerEntry(id: "chrome-profile-\(profile.directory)", title: profile.name,
                    subtitle: "Chrome profile", badge: "person.crop.circle.fill", icon: icon,
                    target: .chromeProfile(profile.directory)))
            }
        }
        return entries
    }
}

@MainActor
final class PickerViewModel: ObservableObject {
    @Published var pendingCount = 0
    @Published var selection = 0
    @Published var useOriginal = false
    @Published var showDetails = false
    @Published var rememberDomain = false
    let entries: [PickerEntry]
    let cleanedURL: URL
    let originalURL: URL
    let warnings: [SecurityWarning]
    let context: String?
    let width: CGFloat
    let maxHeight: CGFloat

    init(entries: [PickerEntry], url: URL, originalURL: URL, warnings: [SecurityWarning], context: String?) {
        self.entries = entries
        self.cleanedURL = url
        self.originalURL = originalURL
        self.warnings = warnings
        self.context = context
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        width = min(390, (screen?.visibleFrame.width ?? 1000) - 20)
        maxHeight = max(240, (screen?.visibleFrame.height ?? 800) - 24)
    }

    var url: URL { useOriginal ? originalURL : cleanedURL }
    var host: String { url.host ?? url.absoluteString }
    var height: CGFloat {
        min(maxHeight, 220 + CGFloat(min(max(entries.count, 1), 5)) * 54
            + (warnings.isEmpty ? 0 : 90) + (showDetails ? 138 : 0) + (context == nil ? 0 : 26)
            + (pendingCount > 0 ? 24 : 0))
    }
}

enum PickerChoice {
    case open(PickerEntry)
    case copy
    case skip
    case settings
    case cancel
    case deactivate
}
