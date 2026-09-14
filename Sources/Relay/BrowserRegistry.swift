import AppKit
import RelayCore

@MainActor
final class BrowserRegistry: ObservableObject {
    static let chromeBundleID = "com.google.Chrome"
    static let safariBundleID = "com.apple.Safari"

    @Published private(set) var browsers: [Browser] = []
    @Published private(set) var chromeProfiles: [ChromeProfile] = []

    private let ownBundleID = Bundle.main.bundleIdentifier ?? BrowserIdentity.relayBundleID

    static func isRecognizedBrowser(_ id: String) -> Bool {
        ["com.apple.Safari", "com.google.Chrome", "com.google.Chrome.canary",
         "org.mozilla.firefox", "org.mozilla.nightly", "com.brave.Browser", "com.microsoft.edgemac",
         "com.operasoftware.Opera", "com.vivaldi.Vivaldi", "company.thebrowser.Browser",
         "company.thebrowser.dia", "com.kagi.kagimacOS", "app.zen-browser.zen"].contains(id)
    }

    func refresh() {
        let probe = URL(string: "https://example.com")!
        var seen = Set<String>()
        var found: [Browser] = []
        for appURL in NSWorkspace.shared.urlsForApplications(toOpen: probe) {
            guard let bundle = Bundle(url: appURL),
                  let bid = bundle.bundleIdentifier,
                  bid != ownBundleID,
                  !Self.isRelayApplication(bundle),
                  !seen.contains(bid)
            else { continue }
            seen.insert(bid)
            let info = bundle.infoDictionary
            let name = (info?["CFBundleDisplayName"] as? String)
                ?? (info?["CFBundleName"] as? String)
                ?? appURL.deletingPathExtension().lastPathComponent
            found.append(Browser(bundleID: bid, name: name, appURL: appURL))
        }
        browsers = found
        chromeProfiles = Self.loadChromeProfiles()
    }

    static func isRelayApplication(_ bundle: Bundle) -> Bool {
        BrowserIdentity.isRelay(bundleID: bundle.bundleIdentifier,
            executableName: bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String,
            bundleName: bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
    }

    func browser(withID id: String?) -> Browser? {
        guard let id else { return nil }
        return browsers.first { $0.bundleID == id }
    }

    func icon(for browser: Browser) -> NSImage {
        NSWorkspace.shared.icon(forFile: browser.appURL.path)
    }

    private static func loadChromeProfiles() -> [ChromeProfile] {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome/Local State")
        guard let data = try? Data(contentsOf: url) else { return [] }
        return ChromeProfileParser.parse(localStateJSON: data)
    }
}
